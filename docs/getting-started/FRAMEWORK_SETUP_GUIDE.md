> Historical note: this guide documents deferred prototype work for shared-framework and visionOS targets. Those targets are currently archived under `/DeferredPrototypes/` and are not part of the supported build.

# GuidedCaptureShared Framework Setup Guide

This guide explains how to configure the Xcode project to add the `GuidedCaptureShared` framework and `GuidedCaptureVision` (visionOS) targets.

## Overview

The codebase is being refactored into three targets:
- **GuidedCapture** (iOS) - Existing iOS app for 3D model capture
- **GuidedCaptureShared** (Framework) - NEW: Shared code (models, networking)
- **GuidedCaptureVision** (visionOS) - NEW: visionOS app for XR viewing

## Step 1: Create GuidedCaptureShared Framework Target

### 1.1 Add Framework Target
1. Open `GuidedCapture.xcodeproj` in Xcode
2. File → New → Target
3. Select **Framework** (iOS)
4. Product Name: `GuidedCaptureShared`
5. Language: Swift
6. Click **Finish**

### 1.2 Add Files to Framework Target
Add the following files from the `GuidedCaptureShared/` directory:

**Models/**
- `Models.swift`
- `User.swift`
- `Theme.swift`
- `Annotation.swift` ✨ NEW

**Networking/**
- `NetworkProtocol.swift` ✨ NEW
- `CloudStorageService.swift` ✨ NEW

**SupabaseModels/**
- `ModelRecord.swift` ✨ NEW
- `AnnotationRecord.swift` ✨ NEW
- `UserRecord.swift` ✨ NEW

**Utilities/**
- `FileManagerProtocol.swift`
- `PathConstants.swift`

**How to add:**
1. Select the files in Project Navigator
2. Open File Inspector (⌥⌘1)
3. Under "Target Membership", check `GuidedCaptureShared`

### 1.3 Configure Framework Build Settings
1. Select `GuidedCaptureShared` target
2. Build Settings → Search "Defines Module" → Set to **YES**
3. General → Frameworks and Libraries → Add:
   - `SwiftData.framework`
   - `Foundation.framework`

## Step 2: Link Framework to iOS App

### 2.1 Add Framework Dependency
1. Select `GuidedCapture` (iOS) target
2. General → Frameworks, Libraries, and Embedded Content
3. Click **+** → Add `GuidedCaptureShared.framework`
4. Set "Embed" to **Embed & Sign**

### 2.2 Update iOS App Imports
Replace direct file references with framework imports:

**Before:**
```swift
// Models.swift is in the same project
let model = Models(...)
```

**After:**
```swift
import GuidedCaptureShared

let model = Models(...)
```

Files to update:
- `ModelsViewModel.swift`
- `ImportViewModel.swift`
- `SettingsViewModel.swift`
- `EditProfileView.swift`
- `ModelsView.swift`
- `ImportView.swift`
- `SettingsView.swift`
- `GuidedCaptureSampleApp.swift`

### 2.3 Remove Duplicates from iOS Target
Once framework is linked, remove these files from the iOS target:
1. Select file in Project Navigator
2. File Inspector → Target Membership
3. **Uncheck** `GuidedCapture` (keep `GuidedCaptureShared` checked)

Files to remove from iOS target:
- `Models.swift`
- `User.swift`
- `Theme.swift`
- `FileManagerProtocol.swift`
- `PathConstants.swift`

⚠️ **DO NOT DELETE THE FILES** - just uncheck the iOS target membership!

## Step 3: Create visionOS App Target

### 3.1 Add visionOS Target
1. File → New → Target
2. Select **visionOS** → **App**
3. Product Name: `GuidedCaptureVision`
4. Language: Swift
5. Interface: SwiftUI
6. Click **Finish**

### 3.2 Link Framework to visionOS App
1. Select `GuidedCaptureVision` target
2. General → Frameworks, Libraries, and Embedded Content
3. Click **+** → Add `GuidedCaptureShared.framework`
4. Set "Embed" to **Embed & Sign**

### 3.3 Add Required Frameworks
1. Select `GuidedCaptureVision` target
2. General → Frameworks and Libraries → Add:
   - `RealityKit.framework`
   - `SwiftData.framework`
   - `SwiftUI.framework`

### 3.4 Configure Info.plist
Add the following keys to `GuidedCaptureVision/Info.plist`:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
</dict>
```

## Step 4: Configure Tests

### 4.1 Update Test Target Dependencies
1. Select `GuidedCaptureTests` target
2. Build Phases → Link Binary With Libraries
3. Add `GuidedCaptureShared.framework`

### 4.2 Update Test Imports
Add to all test files:
```swift
@testable import GuidedCaptureShared
@testable import GuidedCapture
```

### 4.3 Add Mock Files to Tests
Ensure these are in the test target:
- `GuidedCaptureTests/mocks/FileManagerMocks.swift` (existing)
- `GuidedCaptureTests/mocks/MockNetworkService.swift` ✨ NEW

## Step 5: Add Supabase Swift SDK

### 5.1 Add Package Dependency
1. File → Add Packages
2. Enter URL: `https://github.com/supabase/supabase-swift`
3. Dependency Rule: **Up to Next Major Version** (latest)
4. Click **Add Package**
5. Select products:
   - `Supabase` → Add to `GuidedCaptureShared`

### 5.2 Create Secrets Configuration
1. Create file: `Configuration/Secrets.xcconfig`
2. Add to `.gitignore`:
   ```
   Configuration/Secrets.xcconfig
   ```
3. Add content:
   ```
   // Supabase Configuration
   SUPABASE_URL = https://<YOUR_PROJECT>.supabase.co
   SUPABASE_ANON_KEY = <YOUR_ANON_KEY>
   ```
4. Project → Info → Configurations → Debug → Set configuration file to `Secrets.xcconfig`

### 5.3 Update CloudStorageService
Uncomment the Supabase client initialization in `CloudStorageService.swift`:
```swift
import Supabase

// Uncomment:
private let supabaseClient: SupabaseClient

init(supabaseURL: String, supabaseKey: String) {
    self.supabaseURL = supabaseURL
    self.supabaseKey = supabaseKey
    self.supabaseClient = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: supabaseKey
    )
}
```

## Step 6: Verify Build

### 6.1 Build Framework
1. Select `GuidedCaptureShared` scheme
2. Product → Build (⌘B)
3. ✅ Should build without errors

### 6.2 Build iOS App
1. Select `GuidedCapture` scheme
2. Product → Build (⌘B)
3. ✅ Should build without errors

### 6.3 Run Tests
```bash
xcodebuild test \
  -project GuidedCapture.xcodeproj \
  -scheme GuidedCapture \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
✅ All existing tests should pass

### 6.4 Build visionOS App (Later)
1. Select `GuidedCaptureVision` scheme
2. Product → Build (⌘B)
3. ✅ Should build (may need visionOS simulator)

## Step 7: Database Setup (Supabase)

### 7.1 Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Save the following from Settings → API:
   - Project URL → `SUPABASE_URL`
   - Anon/Public Key → `SUPABASE_ANON_KEY`

### 7.2 Deploy Database Schema
Copy the contents of `database/schema.sql` and run in Supabase SQL Editor.

### 7.3 Enable Authentication
1. Supabase Dashboard → Authentication → Settings
2. Enable **Email** provider
3. Set email templates (optional)

### 7.4 Configure Storage
1. Supabase Dashboard → Storage
2. Create new bucket: `models`
3. Set bucket to **Public** (for public URLs)
4. Set file size limit: 500MB

## Troubleshooting

### "No such module 'GuidedCaptureShared'"
- Ensure framework target is built first
- Check target dependencies (Build Phases → Dependencies)
- Clean build folder (⇧⌘K) and rebuild

### "Undefined symbol: _$s..."
- Framework not linked properly
- Check Frameworks and Libraries → `GuidedCaptureShared.framework` is present
- Ensure "Embed & Sign" is selected

### Tests Failing After Migration
- Add `@testable import GuidedCaptureShared` to test files
- Ensure `GuidedCaptureShared.framework` is in test target dependencies
- Check that mock files are in test target membership

### visionOS Simulator Not Available
- Xcode 15+ required
- Download visionOS SDK: Xcode → Settings → Platforms
- Use Mac with Apple Silicon for best performance

## Next Steps

After framework setup is complete:

1. ✅ **Epic 1.1 Complete** - Shared framework exists
2. **Epic 1.2** - Create visionOS app scaffold
3. **Epic 1.3** - Implement RealityKit model viewer
4. **Epic 2.1** - Test annotation data model
5. **Epic 3.1** - Connect to Supabase backend

## File Structure (Final State)

```
GuidedCapture.xcodeproj/
├── GuidedCapture (iOS target)
│   ├── Features/
│   │   ├── Capture/
│   │   ├── Models/
│   │   └── Import/
│   └── GuidedCaptureSampleApp.swift
│
├── GuidedCaptureShared (Framework target)
│   ├── Models/
│   │   ├── Models.swift
│   │   ├── User.swift
│   │   ├── Theme.swift
│   │   └── Annotation.swift ✨
│   ├── Networking/
│   │   ├── NetworkProtocol.swift ✨
│   │   └── CloudStorageService.swift ✨
│   ├── SupabaseModels/
│   │   ├── ModelRecord.swift ✨
│   │   ├── AnnotationRecord.swift ✨
│   │   └── UserRecord.swift ✨
│   └── Utilities/
│       ├── FileManagerProtocol.swift
│       └── PathConstants.swift
│
├── GuidedCaptureVision (visionOS target)
│   ├── Views/
│   ├── ViewModels/
│   └── RealityKit/
│
├── GuidedCaptureTests (Test target)
│   └── mocks/
│       ├── FileManagerMocks.swift
│       └── MockNetworkService.swift ✨
│
└── Configuration/
    └── Secrets.xcconfig (gitignored)
```

---

**Need Help?**
- Review existing tests in `GuidedCaptureTests/` for patterns
- Check `CLAUDE.md` for architecture guidelines
- See plan document for full implementation roadmap
