# カメラエラー修正サマリー

## 問題

- **エラー**: "unable to add camera input"
- **症状**: 写真の撮影・処理・保存ができない

## 修正内容

### 1. プロジェクト設定の修正 (`CutieCam.xcodeproj/project.pbxproj`)

#### サンドボックス設定の修正
iOS向けにアプリサンドボックスを無効化しました：

```
"ENABLE_APP_SANDBOX[sdk=iphoneos*]" = NO;
"ENABLE_APP_SANDBOX[sdk=iphonesimulator*]" = NO;
"ENABLE_APP_SANDBOX[sdk=macosx*]" = YES;  // macOS向けはサンドボックスを維持
"ENABLE_APP_SANDBOX[sdk=xros*]" = NO;
"ENABLE_APP_SANDBOX[sdk=xrsimulator*]" = NO;
```

**理由**: App Sandboxが有効だと、iOSアプリでカメラデバイスへのアクセスが制限される場合があります。

### 2. CameraService.swift の改善

#### 2.1 PhotoCaptureDelegateの保持問題を解決

**問題**: デリゲートオブジェクトが早期に解放され、写真キャプチャのコールバックが呼ばれない

**修正**: 
```swift
// デリゲートの強参照を保持
private var photoCaptureDelegate: PhotoCaptureDelegate?

// キャプチャ時にデリゲートを保持し、完了後に解放
self.photoCaptureDelegate = PhotoCaptureDelegate { [weak self] result in
    defer {
        Task { @MainActor in
            self?.photoCaptureDelegate = nil
        }
    }
    continuation.resume(with: result)
}
```

#### 2.2 セッション設定の改善

**追加機能**:
- 既存の入力/出力を削除してからクリーンセットアップ
- セッションプリセットの互換性チェック
- 高解像度キャプチャの有効化
- 詳細なログ出力で問題を追跡

```swift
// 既存の入力/出力を削除
session.inputs.forEach { session.removeInput($0) }
session.outputs.forEach { session.removeOutput($0) }

// セッションプリセットの互換性チェック
if session.canSetSessionPreset(.photo) {
    session.sessionPreset = .photo
} else {
    session.sessionPreset = .high
}

// 高解像度キャプチャを有効化
photoOutput.isHighResolutionCaptureEnabled = true
```

#### 2.3 エラーハンドリングの強化

- カメラデバイスが利用できない場合の詳細なログ
- 入力追加失敗時のエラーメッセージ
- セッション状態の確認とログ出力

#### 2.4 セッション制御の改善

**修正前**: 非同期でセッションを開始するが、完了を待たない

**修正後**: セッションの開始/停止を正しく待機
```swift
await withCheckedContinuation { continuation in
    sessionQueue.async {
        self.session.startRunning()
        print("Camera session started: \(self.session.isRunning)")
        continuation.resume()
    }
}
```

#### 2.5 カメラ切り替え時のエラーリカバリー

カメラ切り替えが失敗した場合、元のカメラ入力を復元する仕組みを追加：

```swift
// エラー発生時、元のカメラ入力を復元
if let oldDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
   let oldInput = try? AVCaptureDeviceInput(device: oldDevice),
   session.canAddInput(oldInput) {
    session.addInput(oldInput)
    videoDeviceInput = oldInput
}
```

#### 2.6 PhotoCaptureDelegateの詳細ログ

キャプチャプロセスの各段階でログを出力：
- キャプチャ開始
- 処理完了
- 画像データサイズ
- UIImage作成成功/失敗

### 3. 新規ビューの作成

#### GalleryView.swift
- フォトライブラリから写真を読み込んで表示
- グリッドレイアウトで写真を一覧表示
- 写真タップでPhotoEditorViewを開く

#### ProfileView.swift
- ユーザープロフィール表示
- サブスクリプション管理へのアクセス
- 設定項目の表示

## プライバシー権限

プロジェクトのビルド設定に以下の権限が設定されています：

- `NSCameraUsageDescription`: カメラアクセスの説明
- `NSPhotoLibraryAddUsageDescription`: 写真保存の説明
- `NSPhotoLibraryUsageDescription`: フォトライブラリアクセスの説明

## 次のステップ

### アプリをテストする手順

1. Xcodeでプロジェクトを開く
2. iPhoneシミュレーターまたは実機を選択
3. プロジェクトをビルド・実行
4. カメラ権限のダイアログで「許可」をタップ
5. カメラビューで以下をテスト：
   - カメラプレビューが表示されるか
   - 写真が撮影できるか
   - フィルターが適用されるか
   - 写真が保存されるか

### デバッグログの確認

アプリ実行中、Xcodeのコンソールに以下のログが表示されます：

```
Found video device: [カメラ名]
Successfully added camera input
Successfully added photo output
Starting camera session...
Camera session started: true
Camera ready: true
PhotoCaptureDelegate initialized
Photo capture started
Photo processing finished
Image data size: [バイト数] bytes
Successfully created UIImage: [サイズ]
Capture finished successfully
```

これらのログでカメラの動作状況を確認できます。

## トラブルシューティング

### カメラプレビューが黒い場合

1. カメラ権限が許可されているか確認
2. シミュレーターではなく実機でテスト
3. Xcodeのコンソールでエラーログを確認

### 写真が保存されない場合

1. フォトライブラリ権限が許可されているか確認
2. `PhotoLibraryService.swift`のエラーログを確認
3. 設定アプリで権限を手動で確認

### "unable to add camera input" エラーが続く場合

1. アプリを完全に削除して再インストール
2. シミュレーターをリセット
3. 実機でテスト（シミュレーターのカメラサポートは限定的）

## 技術的な詳細

### デリゲート保持の重要性

AVFoundationの`AVCapturePhotoCaptureDelegate`は、キャプチャ処理中に強参照されていないと早期に解放される可能性があります。これを防ぐため、クラスのプロパティとしてデリゲートを保持し、キャプチャ完了後にクリーンアップします。

### 非同期処理のスレッド安全性

カメラセッションの操作は専用のシリアルキュー（`sessionQueue`）で実行し、UI更新は`MainActor`で実行することで、スレッド安全性を確保しています。

### エラーリカバリー戦略

カメラ切り替えなどの操作が失敗した場合、可能な限り元の状態に復帰し、ユーザーエクスペリエンスを維持します。

