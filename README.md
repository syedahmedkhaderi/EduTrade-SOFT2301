# EduTrade

EduTrade is a SwiftUI iOS marketplace for UDST students to buy and sell academic items.

## Scope

- UDST email-based access
- Listing creation and browsing
- Search and filtering
- Checkout with platform commission
- Ratings and admin moderation
- English and Arabic support

## Stack

- SwiftUI
- MVVM
- Protocol-based services
- Mock in-memory store with disk persistence

## Run

```bash
xcodegen generate
open EduTrade.xcodeproj
```

Build with Xcode and run on an iOS 17+ simulator.

## Test

```bash
xcodebuild -project EduTrade.xcodeproj -scheme EduTrade \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -only-testing:EduTradeTests test
```

## Demo

| Role | Email | Password |
| --- | --- | --- |
| Student | `ahmed.mansoori@udst.edu.qa` | `password123` |
| Admin | `admin@udst.edu.qa` | `admin123` |

## Notes

- Seeded mock data is bundled for local development.
- Use `-resetMockData` to force a fresh demo dataset.
- Project configuration is defined in `project.yml`.
