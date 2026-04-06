# Ortio XR System - Documentation

Welcome to the Ortio XR documentation. This guide will help you navigate all available documentation.

---

## 📂 Documentation Structure

### 🚀 Getting Started
**Path:** `/docs/getting-started/`

Start here if you're new to the project or setting up for the first time.

- **[QUICK_START.md](./getting-started/QUICK_START.md)**
  - ⏱️ 2-3 hours to first build
  - 3-step setup guide
  - Development tips
  - Common issues & fixes

- **[FRAMEWORK_SETUP_GUIDE.md](./getting-started/FRAMEWORK_SETUP_GUIDE.md)**
  - Detailed Xcode configuration
  - Step-by-step instructions
  - Supabase integration
  - Troubleshooting guide

---

### 🏗️ Implementation
**Path:** `/docs/implementation/`

Reference these for understanding progress, architecture, and planning.

- **[SUMMARY.md](./implementation/SUMMARY.md)**
  - ✨ **START HERE** for overview
  - What's been built (45% complete)
  - Architecture highlights
  - Next steps summary

- **[IMPLEMENTATION_PLAN.md](./implementation/IMPLEMENTATION_PLAN.md)**
  - Complete 12-part implementation plan
  - Detailed specifications for each feature
  - Code examples and pseudocode
  - Timeline: 7 weeks

- **[IMPLEMENTATION_PROGRESS.md](./implementation/IMPLEMENTATION_PROGRESS.md)**
  - Detailed progress by epic/story
  - What's done vs what's next
  - File structure breakdown
  - Success metrics

---

### 🗄️ Database
**Path:** `/docs/database/`

Database schema and backend infrastructure.

- **[schema.sql](./database/schema.sql)**
  - PostgreSQL schema for Supabase
  - Row-Level Security policies
  - Indexes and triggers
  - Heavily commented

---

## 🎯 Quick Navigation

### I want to...

**...get the project running**
→ Read [QUICK_START.md](./getting-started/QUICK_START.md)

**...understand what's been built**
→ Read [SUMMARY.md](./implementation/SUMMARY.md)

**...configure Xcode targets**
→ Follow [FRAMEWORK_SETUP_GUIDE.md](./getting-started/FRAMEWORK_SETUP_GUIDE.md)

**...see the full plan**
→ Review [IMPLEMENTATION_PLAN.md](./implementation/IMPLEMENTATION_PLAN.md)

**...check progress**
→ Check [IMPLEMENTATION_PROGRESS.md](./implementation/IMPLEMENTATION_PROGRESS.md)

**...deploy the database**
→ Use [schema.sql](./database/schema.sql)

---

## 📊 Project Status

**Overall Completion:** 45%

| Component | Status | Documentation |
|-----------|--------|---------------|
| Shared Framework | ✅ Code Ready | SUMMARY.md |
| visionOS App | ✅ Scaffold Ready | SUMMARY.md |
| Database Schema | ✅ Ready to Deploy | schema.sql |
| Cloud Sync | ⏸️ Not Started | PLAN.md Part 10 |
| Tests | 🔶 60% Coverage | PROGRESS.md |

**Next Blocker:** Xcode configuration (see QUICK_START.md)

---

## 🏛️ Architecture Overview

```
┌─────────────────────────────────────────────────┐
│           iOS App (Capture)                     │
│  ┌──────────────────────────────────────────┐  │
│  │  Object Capture + Photogrammetry         │  │
│  │  Upload Models to Cloud                  │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────┘
                      │
        ┌─────────────▼─────────────┐
        │  OrtioShared      │
        │  - Data Models            │
        │  - Network Protocol       │
        │  - DTOs                   │
        └─────────────┬─────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│           visionOS App (View & Annotate)        │
│  ┌──────────────────────────────────────────┐  │
│  │  RealityKit 3D Viewer                    │  │
│  │  Spatial Annotations                     │  │
│  │  Download Models from Cloud              │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────┘
                      │
        ┌─────────────▼─────────────┐
        │    Supabase Backend       │
        │  - PostgreSQL Database    │
        │  - Storage (USDZ files)   │
        │  - Authentication         │
        │  - Row-Level Security     │
        └───────────────────────────┘
```

---

## 🔑 Key Files in Root

- **[/CLAUDE.md](../CLAUDE.md)** - Project instructions for Claude Code
- **[/README.md](../README.md)** - Original Apple sample README

---

## 📝 File Naming Conventions

All documentation files use:
- **UPPERCASE.md** for primary docs
- **Descriptive names** (not abbreviations)
- **Prefixes** to group related docs:
  - `IMPLEMENTATION_*` - Planning and progress
  - `FRAMEWORK_*` - Setup and configuration
  - No prefix - General guides

---

## 🤝 Contributing

When adding new documentation:

1. **Place in appropriate folder:**
   - User guides → `/docs/getting-started/`
   - Technical specs → `/docs/implementation/`
   - Database stuff → `/docs/database/`

2. **Update this README** with a link and description

3. **Follow existing format:**
   - Clear headings with emoji
   - Code examples in fenced blocks
   - Internal links using relative paths

---

## 📞 Need Help?

1. Start with [QUICK_START.md](./getting-started/QUICK_START.md)
2. Check [FRAMEWORK_SETUP_GUIDE.md](./getting-started/FRAMEWORK_SETUP_GUIDE.md) troubleshooting
3. Review inline code comments (all Swift files have TODO markers)
4. Check [SUMMARY.md](./implementation/SUMMARY.md) for architecture overview

---

**Last Updated:** 2026-02-12
**Project:** Ortio XR Capture & Visualization System
**Status:** Foundation Phase Complete (45%)
