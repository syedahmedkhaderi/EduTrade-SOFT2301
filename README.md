# EduTrade iOS Application

A peer-to-peer marketplace for UDST students to buy and sell used academic materials — textbooks, lab kits, and notes. Built with SwiftUI following the MVVM architecture, targeting iOS 17+.

**Course:** UDST Software Project Management (SOFT2301)

---

## Features

- **University email verification** — registration restricted to `@udst.edu.qa` addresses
- **Material listings** — create listings with photos, course codes, condition tags, and prices
- **Search & filtering** — full-text search plus filters by subject, course code, price range, and condition
- **Secure checkout** — payment flow with automatic 10% platform commission calculation
- **Ratings & reviews** — 1–5 star ratings after completed transactions
- **Admin dashboard** — moderation queue, transaction log, user management, analytics
- **Bilingual** — full English + Arabic localization with RTL layout support
- **Accessibility** — Dynamic Type, VoiceOver labels, 4.5:1 contrast ratios

---

## Project Structure

```
EduTrade/
├── App/
│   ├── EduTradeApp.swift        # @main entry point
│   └── AppState.swift           # Global session state + navigation root
├── Models/                      # Codable data models
│   ├── User.swift
│   ├── Listing.swift            # + Condition, ListingStatus, ModerationStatus
│   ├── Transaction.swift        # + TransactionStatus
│   ├── Rating.swift
│   └── Report.swift             # + ReportStatus
├── Services/                    # Protocol-oriented data layer
│   ├── AuthService.swift        (protocol)
│   ├── ListingService.swift     (protocol)
│   ├── TransactionService.swift (protocol)
│   ├── RatingService.swift      (protocol)
│   ├── StorageAndAdminService.swift (protocols)
│   ├── ServiceTypes.swift       # SearchQuery, CheckoutPreview, etc.
│   ├── MockStore.swift          # In-memory store with disk persistence
│   ├── MockAuthService.swift
│   ├── MockListingService.swift
│   ├── MockTransactionService.swift
│   ├── MockRatingService.swift
│   ├── MockAdminService.swift
│   ├── MockStorageService.swift
│   ├── ServiceContainer.swift   # Dependency injection container
│   └── ToastCenter.swift        # In-app notifications
├── ViewModels/                  # MVVM business logic (ObservableObject)
├── Views/                       # SwiftUI screens
│   ├── RootView.swift
│   ├── MainTabView.swift
│   ├── Authentication/          # Welcome, Register, Login, VerifyEmail
│   ├── Home/                    # HomeFeed
│   ├── Search/                  # Search + FilterSheet
│   ├── ListingDetail/           # Detail + Report sheet
│   ├── CreateListing/           # 3-step create flow
│   ├── Checkout/                # Checkout + Confirmation
│   ├── Profile/                 # Profile, MyListings, Orders, Edit, Language
│   ├── Ratings/                 # RateTransaction
│   └── Admin/                   # Dashboard, Moderation, Transactions, Users
├── Components/                  # Reusable UI (buttons, cards, star ratings)
├── Utilities/                   # Validators, Formatters, Constants
└── Resources/
    ├── Assets.xcassets/         # AppIcon, AccentColor, LaunchLogo
    ├── en.lproj/                # English strings
    └── ar.lproj/                # Arabic strings
```

---

## How to Build & Run

### Prerequisites

- **macOS** with **Xcode 16+** (project built & tested on Xcode 26.5)
- **iOS 17.0+** simulator or device
- **xcodegen** (for regenerating the `.xcodeproj` from `project.yml`):
  ```bash
  brew install xcodegen
  ```

### Option A — Open in Xcode (recommended)

1. Open Terminal and navigate to the project:
   ```bash
   cd /path/to/edutrade
   ```
2. Generate the Xcode project (creates `EduTrade.xcodeproj`):
   ```bash
   xcodegen generate
   ```
3. Open in Xcode:
   ```bash
   open EduTrade.xcodeproj
   ```
4. Select a simulator (e.g. **iPhone 16**) from the device dropdown.
5. Press **Cmd+R** to build and run.

### Option B — Build from the command line

```bash
# Generate project
xcodegen generate

# Build
xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run in simulator
xcrun simctl install booted <path-to-DerivedData>/EduTrade.app
xcrun simctl launch booted qa.udst.edutrade.app
```

---

## Demo Accounts

The app ships with a seeded mock database (9 users, 21 listings, sample transactions). Use these to log in:

| Role    | Email                           | Password     |
|---------|---------------------------------|--------------|
| Student | `ahmed.mansoori@udst.edu.qa`    | `password123`|
| Admin   | `admin@udst.edu.qa`             | `admin123`   |

You can also **register a new account** with any `@udst.edu.qa` email — verification is automatic in demo mode (click "I've verified — check now").

---

## Running Tests

```bash
# All tests (unit + UI)
xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test

# Unit tests only
xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:EduTradeTests test

# UI tests only
xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:EduTradeUITests test
```

**Test coverage:**
- **ValidatorTests** (16 tests) — email domain, password strength, listing validation, price, stars
- **TransactionTests** (5 tests) — 10% commission math, fractional prices, payout calculation
- **MockServiceTests** (25 tests) — auth, listings, search, checkout, ratings, admin flows
- **EduTradeUITests** (6 tests) — app launch, login, registration validation, tab navigation, admin tab, home feed rendering

---

## Architecture: Protocol-Oriented Services

Every data service is defined as a **protocol** with a **mock implementation** and a **Firebase implementation point**. This means:

- The app is **fully functional offline** today using the mock backend (in-memory + disk persistence).
- Swapping to **live Firebase/Stripe** requires implementing the protocol methods — no View or ViewModel changes needed.

To switch to Firebase, implement the protocols in `Services/` (e.g. `FirebaseAuthService: AuthServiceProtocol`) and wire them up in `ServiceContainer.swift`.

---

## Language Switching

Go to **Profile → Language** to switch between English and Arabic. Arabic activates full RTL layout mirroring.

---

## Resetting Demo Data

To reset the mock database to its seeded state, delete the app from the simulator (which clears its container), or run with the launch argument `-resetMockData`:

```bash
xcrun simctl launch booted qa.udst.edutrade.app -resetMockData
```
