# Ortio XR Capture & Visualization System

**Transform your iOS photogrammetry app into a collaborative XR platform**

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20visionOS-lightgrey)]()
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)]()
[![SwiftData](https://img.shields.io/badge/SwiftData-✓-blue)]()
[![Status](https://img.shields.io/badge/status-in%20development-yellow)]()

---

## 🎯 What is Ortio?

Ortio is an XR (Extended Reality) system for architectural model review and collaboration:

1. **📱 iOS App** - Capture physical models using photogrammetry
2. **🥽 visionOS App** - View models in 3D/AR and add spatial annotations
3. **☁️ Cloud Backend** - Sync models and annotations between users
4. **👥 Collaboration** - Share models with team members for feedback

### Use Case Example
An architect builds a physical scale model → scans it with iPhone → uploads to cloud → team reviews in Vision Pro → adds spatial annotations → feedback syncs to all devices.

---

## 📊 Project Status

**Current Phase:** Foundation (45% complete)

| Component | Status | Details |
|-----------|--------|---------|
| iOS Capture | ✅ Complete | Existing Apple sample (working) |
| Shared Framework | ✅ Code Ready | Awaiting Xcode config |
| visionOS App | ✅ Scaffold Ready | Awaiting Xcode config |
| Database Schema | ✅ Ready | Ready to deploy |
| Cloud Sync | ⏸️ Not Started | Depends on foundation |
| Tests | 🔶 60% Coverage | Annotation model complete |

**Next Milestone:** First visionOS build (ETA: 2-3 hours after Xcode setup)

---

## 🚀 Quick Start

### For New Users

1. **Read the overview**
   → See [docs/implementation/SUMMARY.md](docs/implementation/SUMMARY.md)

2. **Set up your environment**
   → Follow [docs/getting-started/QUICK_START.md](docs/getting-started/QUICK_START.md)

3. **Configure Xcode** (required manual step)
   → Follow [docs/getting-started/FRAMEWORK_SETUP_GUIDE.md](docs/getting-started/FRAMEWORK_SETUP_GUIDE.md)

4. **Deploy Supabase backend**
   → Use [docs/database/schema.sql](docs/database/schema.sql)

**Estimated Time:** 2-3 hours to first working build

### For Developers

```bash
# Clone repository
git clone <repo-url>
cd GuidedCapture

# Open in Xcode
open GuidedCapture.xcodeproj

# Follow FRAMEWORK_SETUP_GUIDE.md to:
# 1. Create GuidedCaptureShared framework target
# 2. Create GuidedCaptureVision visionOS target
# 3. Link dependencies

# Run tests
xcodebuild test \
  -project GuidedCapture.xcodeproj \
  -scheme GuidedCapture \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 🏗️ Architecture

### System Overview

```
iOS App (Capture)
     ↓
  Upload
     ↓
Supabase Cloud ←→ Shared Framework (Models, Networking)
     ↓                    ↑
  Download              Used by
     ↓                    ↓
visionOS App (View & Annotate)
```

### Technology Stack

**iOS/visionOS:**
- Swift 5.9+
- SwiftUI (UI framework)
- SwiftData (local persistence)
- RealityKit (3D rendering)
- ObjectCapture (photogrammetry)

**Backend:**
- Supabase (PostgreSQL + Storage + Auth)
- Row-Level Security (multi-user access control)

**Testing:**
- XCTest (unit tests)
- In-memory containers (SwiftData tests)
- Mock services (network isolation)

### Project Structure

```
/
├── GuidedCapture/              iOS app (photogrammetry)
├── GuidedCaptureShared/        Shared code (models, networking)
├── GuidedCaptureVision/        visionOS app (3D viewing)
├── GuidedCaptureTests/         Unit & integration tests
├── docs/                       📚 All documentation
│   ├── getting-started/        Setup guides
│   ├── implementation/         Planning & progress
│   └── database/               SQL schema
├── CLAUDE.md                   Project instructions
└── README.md                   This file
```

---

## 🎨 Features

### Current (iOS App)
- ✅ 3D object capture using photogrammetry
- ✅ USDZ model generation
- ✅ Local model storage and browsing
- ✅ User profiles and settings
- ✅ Import models from file system

### In Progress (visionOS App)
- 🔶 3D model viewer (scaffold ready)
- 🔶 Spatial gesture controls (stubbed)
- ⏸️ Spatial annotations (data model ready)
- ⏸️ Model download from cloud
- ⏸️ AR immersive mode

### Planned (Cloud Backend)
- ⏸️ Model upload/download
- ⏸️ User authentication
- ⏸️ Annotation synchronization
- ⏸️ Multi-user model sharing
- ⏸️ Permission-based access control

---

## 📚 Documentation

All documentation is in the [`/docs`](docs/) folder:

### Essential Reading
1. **[SUMMARY.md](docs/implementation/SUMMARY.md)** - What's been built, architecture overview
2. **[QUICK_START.md](docs/getting-started/QUICK_START.md)** - Fast path to first build
3. **[FRAMEWORK_SETUP_GUIDE.md](docs/getting-started/FRAMEWORK_SETUP_GUIDE.md)** - Detailed setup

### Reference
4. **[IMPLEMENTATION_PLAN.md](docs/implementation/IMPLEMENTATION_PLAN.md)** - 12-part plan, 7-week timeline
5. **[IMPLEMENTATION_PROGRESS.md](docs/implementation/IMPLEMENTATION_PROGRESS.md)** - Progress by epic/story
6. **[schema.sql](docs/database/schema.sql)** - Database design

See [docs/README.md](docs/README.md) for full navigation guide.

---

## 🧪 Testing

### Run All Tests
```bash
xcodebuild test \
  -project GuidedCapture.xcodeproj \
  -scheme GuidedCapture \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Coverage
- **Current:** ~60%
- **Target:** 80%+
- **Annotation Model:** 100% ✅

### Test Files
- `AnnotationModelTests.swift` - 12 tests for spatial annotation model
- `MockNetworkService.swift` - Full mock for cloud operations
- `FileManagerMocks.swift` - File system mocks
- More tests needed for ViewModels and integration scenarios

---

## 🔧 Requirements

### Development
- macOS Sonoma 14.0+
- Xcode 15.2+
- Apple Silicon Mac (recommended for visionOS simulator)

### iOS App
- iOS 17.0+
- iPhone with LiDAR Scanner
- A14 Bionic or newer

### visionOS App
- visionOS 1.0+
- Vision Pro (for AR features)
- visionOS simulator (for window-based development)

### Backend
- Supabase account (free tier sufficient for development)

---

## 🎯 Roadmap

### Phase 1: Foundation (Weeks 1-2) ← **YOU ARE HERE**
- ✅ Shared framework structure
- ✅ visionOS app scaffold
- ✅ Database schema
- ⏸️ Xcode configuration (manual step required)
- ⏸️ RealityKit model viewer
- ⏸️ Gesture controls

### Phase 2: Cloud Integration (Weeks 3-4)
- Supabase deployment
- Authentication system
- Model upload (iOS)
- Model download (visionOS)

### Phase 3: Annotation Sync (Weeks 5-6)
- 3D annotation markers
- Annotation creation UI
- Cloud synchronization
- Conflict resolution

### Phase 4: Sharing & Polish (Week 7)
- Model sharing by email
- Permission-based access
- Performance optimization
- 80%+ test coverage

---

## 🤝 Contributing

### Code Conventions
- **Views** suffixed with `View`
- **ViewModels** suffixed with `ViewModel`
- **MVVM pattern** with dependency injection
- **Protocol-based design** for testability
- **SwiftData** for persistence

See [CLAUDE.md](CLAUDE.md) for full conventions.

### Testing Standards
- AAA pattern (Arrange-Act-Assert)
- Mock services for isolation
- In-memory containers for SwiftData
- 80%+ code coverage target

### Documentation
- Update relevant docs when adding features
- Add inline comments for complex logic
- Include TODO markers for incomplete work
- Write README for new modules

---

## 📄 License

See [LICENSE](LICENSE/) folder for this sample's licensing information.

**Note:** This project is based on Apple's GuidedCapture sample with significant extensions for XR collaboration.

---

## 🙏 Acknowledgments

- **Apple** - GuidedCapture sample project foundation
- **Supabase** - Backend infrastructure
- **RealityKit** - 3D rendering framework

---

## 📞 Support

### Issues
- Check [docs/getting-started/FRAMEWORK_SETUP_GUIDE.md](docs/getting-started/FRAMEWORK_SETUP_GUIDE.md) troubleshooting
- Review inline TODO comments in code
- Verify Supabase configuration

### Resources
- [visionOS Documentation](https://developer.apple.com/visionos/)
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

---

## 🚀 Getting Started

**Ready to begin?**

1. Read [docs/implementation/SUMMARY.md](docs/implementation/SUMMARY.md) for overview
2. Follow [docs/getting-started/QUICK_START.md](docs/getting-started/QUICK_START.md) for setup
3. Configure Xcode using [docs/getting-started/FRAMEWORK_SETUP_GUIDE.md](docs/getting-started/FRAMEWORK_SETUP_GUIDE.md)

**Estimated time to first build:** 2-3 hours

---

**Project Status:** 🟡 In Development (45% complete)
**Last Updated:** 2026-02-12
**Maintainer:** Matyas Vascak
