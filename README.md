# 📸 CutieCam - Film Aesthetic Camera App

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)

> **"เทสดี ดูสวยดูแพง ราคาเอื้อมถึง"**
> Bringing influencer-tier aesthetics to everyone's phone.

## 🎯 Overview

**CutieCam** is a premium iOS camera app that replicates the aesthetics of film cameras and compact digital cameras. Inspired by viral trends from influencers and celebrities on social media, CutieCam makes professional-looking, ready-to-post photos accessible to everyone.

### 🌟 Unique Selling Point

**Filter Marketplace**: Unlike other camera apps, CutieCam allows public contributors to **create and sell their own filters** within the app, creating a creator economy around aesthetic photography.

## ✨ Key Features

### 📷 Camera Functionality
- **Real-time Filter Preview**: See filters applied before you capture
- **High-Quality Capture**: Full-resolution photo output
- **Advanced Controls**: 
  - Flash toggle
  - Front/back camera switching
  - Zoom support
  - Professional camera settings

### 🎨 Film Aesthetic Filters
- **Film Vintage**: Classic film look with warm tones
- **Film Dreams**: Soft vintage with light leaks
- **K-Pop Glow**: Soft, glowing skin like K-pop idols
- **Disposable Camera**: Y2K disposable camera vibes
- **Y2K Digital**: Early 2000s digital camera aesthetic
- **Soft Aesthetic**: Instagram-ready dreamy look
- **Cinematic**: Movie-like color grading

### 🎬 Filter Effects
- **Film Grain**: Adjustable grain intensity and size
- **Light Leaks**: Customizable light leak effects with color control
- **Vignette**: Professional edge darkening
- **Halation**: Highlight glow effect
- **Color Grading**:
  - Temperature & Tint adjustment
  - Saturation & Contrast
  - Exposure control
  - Highlights & Shadows
- **Date Stamp**: Vintage date stamps (multiple styles)
- **Digital Noise**: Compact camera artifacts
- **Fade Effect**: Faded film look

### 🛍️ Filter Marketplace
- **Browse Filters**: Trending, Popular, New, Free, Premium
- **Search**: Find filters by name or style
- **Creator Profiles**: Follow your favorite filter creators
- **Ratings & Reviews**: Community-driven quality control
- **User-Generated Content**: Sell your own filters
- **Commission Structure**: 70% creator / 30% platform

### 🎭 Photo Editor
- **Real-time Adjustments**:
  - Exposure
  - Contrast
  - Saturation
  - Film Grain
  - Vignette
- **Non-destructive Editing**: Adjust parameters after capture
- **Quick Save**: One-tap save to photo library

### 👤 User Features
- **Gallery**: Organize your captured photos
- **Favorites**: Save your favorite filters
- **Profile**: Track your stats and purchases
- **Subscription Tiers**:
  - **Free**: Basic filters with watermark
  - **Basic ($2.99/month)**: All filters, no watermark, HD quality
  - **Pro ($5.99/month)**: Premium filters + AI enhancements
  - **Creator ($9.99/month)**: All Pro features + sell filters

## 🎯 Target Audience

- **Primary**: Females aged 10-30 (Thailand)
- **Secondary**: Global users interested in aesthetic photography
- **Niche**: Content creators, influencers, K-pop fans

## 🏗️ Technical Architecture

### Technologies Used
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Camera capture and processing
- **Core Image**: Advanced image filtering
- **Core ML**: AI-powered photo enhancements (future)
- **StoreKit**: In-app purchases and subscriptions
- **PhotoKit**: Photo library integration

### Architecture Pattern
- **MVVM** (Model-View-ViewModel)
- **Service-Oriented Architecture**
- **Reactive Programming** with Combine

### Project Structure
```
CutieCam/
├── Models/
│   ├── Filter.swift
│   ├── User.swift
│   └── Photo.swift
├── Views/
│   ├── CameraView.swift
│   ├── PhotoEditorView.swift
│   ├── FilterMarketplaceView.swift
│   ├── HomeView.swift
│   └── ProfileView.swift
├── ViewModels/
│   └── CameraViewModel.swift
├── Services/
│   ├── CameraService.swift
│   ├── FilterService.swift
│   └── PhotoLibraryService.swift
└── Assets.xcassets/
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- macOS 26.1 or later (for development)
- Active Apple Developer account (for device testing)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/CutieCam.git
cd CutieCam
```

2. **Open in Xcode**
```bash
open CutieCam.xcodeproj
```

3. **Configure Signing**
- Select your development team in Xcode
- Update the bundle identifier if needed

4. **Run the app**
- Select a simulator or connected device
- Press `Cmd + R` to build and run

### Permissions Required
- **Camera Access**: Required for photo capture
- **Photo Library Access**: Required to save edited photos

## 📱 App Flow

```
Launch
  ↓
Home (Tab Bar)
  ├── Camera Tab → Capture Photo → Edit Photo → Save to Library
  ├── Filters Tab → Browse Marketplace → Purchase/Download Filter
  ├── Gallery Tab → View Photos → Edit/Share
  └── Profile Tab → Manage Account → Upgrade Subscription
```

## 🎨 Design Philosophy

### Visual Aesthetic
- **Dark Theme**: Primary black background for photo focus
- **Accent Color**: Orange/Pink gradient (warmth, creativity)
- **Typography**: Courier for date stamps, San Francisco for UI
- **Minimalist UI**: Clean, distraction-free interface

### UX Principles
1. **Simplicity**: One-tap to capture, minimal steps to edit
2. **Preview-First**: Always show what you'll get before capture
3. **Non-Destructive**: All edits are reversible
4. **Speed**: Fast processing, no waiting
5. **Delight**: Smooth animations, satisfying interactions

## 💰 Monetization Strategy

### Revenue Streams
1. **Subscriptions** (Primary)
   - Basic: $2.99/month
   - Pro: $5.99/month
   - Creator: $9.99/month

2. **Filter Sales** (Secondary)
   - User-generated filters: $0.99 - $4.99
   - Platform commission: 30%

3. **Premium Filters** (Tertiary)
   - Exclusive pro filters
   - Celebrity/Influencer collaborations

4. **In-App Purchases**
   - One-time filter packs
   - AI enhancement credits

### Market Opportunity
- **Thailand Camera App Market**: ฿500M+ annually
- **Global Aesthetic Photography**: $2B+ market
- **Creator Economy**: Growing 20% YoY

## 🌏 Localization

### Supported Languages
- 🇬🇧 English (Primary)
- 🇹🇭 Thai (Primary Market)

### Thai Market Adaptation
- Local payment methods (PromptPay, TrueMoney)
- Thai celebrity filter collaborations
- Local social media integration (LINE, Thai TikTok)
- Thai aesthetic trends (แบ๊วๆ, soft grunge, vintage)

## 📊 Analytics & Metrics

### Key Performance Indicators
- **DAU/MAU Ratio**: Target 40%
- **Filter Usage**: Track most popular filters
- **Conversion Rate**: Free to Paid (Target: 5%)
- **Creator Sales**: Marketplace transaction volume
- **Retention**: 7-day, 30-day cohorts

## 🔮 Roadmap

### Phase 1: MVP (Current)
- [x] Core camera functionality
- [x] Preset filters (6 styles)
- [x] Basic photo editor
- [x] Filter marketplace UI
- [ ] In-app purchases
- [ ] User authentication

### Phase 2: Enhanced Features
- [ ] AI-powered enhancements (Core ML)
- [ ] Custom filter creation tools
- [ ] Social sharing integration
- [ ] Cloud sync
- [ ] Advanced editing tools

### Phase 3: Creator Platform
- [ ] Creator dashboard & analytics
- [ ] Filter monetization system
- [ ] Community features (follow, like, comment)
- [ ] Filter trending algorithm
- [ ] Influencer partnerships

### Phase 4: Global Expansion
- [ ] Multi-language support (Japanese, Korean, Vietnamese)
- [ ] Regional payment methods
- [ ] Local celebrity collaborations
- [ ] AI-powered recommendations

## 🤝 Contributing

We welcome filter creators and developers to contribute!

### For Filter Creators
1. Create amazing filters using our tools
2. Submit for review
3. Set your price
4. Earn 70% on each sale

### For Developers
1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Follow Swift style guidelines

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by viral aesthetic trends on X (Twitter), Instagram, TikTok
- Film camera aesthetics: Fujifilm, Kodak, Polaroid
- Compact digital camera era: Canon, Sony, Nikon
- K-pop aesthetic photography community
- Thai photography creators

## 📞 Contact

- **Developer**: Piyachet Pongsantichai
- **Email**: piyachet@cutiecam.app
- **Twitter**: [@cutiecam_app](https://twitter.com/cutiecam_app)
- **Instagram**: [@cutiecam.app](https://instagram.com/cutiecam.app)

## 🎉 Social Media References

This app was inspired by viral aesthetic posts from:
- [@aheyekrn](https://x.com/aheyekrn)
- [@marauisxx](https://x.com/marauisxx)
- [@BrightMinho](https://x.com/BrightMinho)
- [@morpormorpaeng](https://x.com/morpormorpaeng)
- [@txxxfilm](https://x.com/txxxfilm)
- [@PPIMMYY](https://x.com/PPIMMYY)

---

**Made with ❤️ in Thailand 🇹🇭**

*"เทสดี ดูสวยดูแพง ราคาเอื้อมถึง"*

