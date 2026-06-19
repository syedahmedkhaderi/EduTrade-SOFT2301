# EduTrade iOS Application
## Complete Technical Specification and Build Plan

Prepared for: UDST Software Project Management (SOFT2301)
Platform: iOS, built with Swift and SwiftUI in Xcode
Purpose: Full implementation reference for AI assisted development

---

## 1. Executive Summary

EduTrade is a peer to peer marketplace iOS application that allows UDST students to buy and sell previously used academic materials such as textbooks, lab kits, and notes. The platform verifies users through university email, lists items with photos and condition tags, supports search and filtering by course code and subject, processes secure payments with an automatic ten percent commission, and maintains a ratings and review system for trust between buyers and sellers. The platform also includes an admin dashboard for moderation and transaction reporting.

This document defines the complete product requirements, data architecture, backend services, API contracts, screen by screen UI specification, and the Xcode project structure required to build the application end to end.

---

## 2. Goals and Success Criteria

The application must support the following measurable outcomes derived from the original project charter.

1. A functional MVP covering registration, listing, search, payment, and ratings within the development window.
2. Support for at least two hundred active student users after launch.
3. Support for at least fifty completed transactions in the first month of operation.
4. All core flows tested and stable with minimal critical bugs before pilot launch.

---

## 3. User Roles

### 3.1 Student User
A verified UDST student who can act as both a buyer and a seller within the same account. There is no separate buyer or seller account type. Every student account has full access to listing, browsing, purchasing, messaging through order context, and rating.

### 3.2 Administrator
A privileged account used by the project team to moderate listings, resolve disputes, monitor transactions, and view platform analytics. Administrators access a separate dashboard interface, which for the mobile app phase will be a restricted set of screens gated behind an admin flag on the user account.

---

## 4. Functional Requirements

Each requirement below is mapped to its originating user story from the product backlog so traceability is preserved.

### 4.1 Authentication and Account Security (PB-01, PB-03)
The app must allow a student to register using a valid UDST university email address ending in udst.edu.qa. The system must send a verification code to that email before the account becomes active. Login must support email and password with secure credential handling. Sessions must persist using a secure token that refreshes automatically. Only verified university accounts can browse, list, or purchase. Unverified accounts are restricted to the verification screen until confirmed.

### 4.2 Accessible and Usable Interface (PB-02)
The interface must follow Apple Human Interface Guidelines, support Dynamic Type for accessibility, maintain a minimum color contrast ratio of four point five to one for text, support VoiceOver labels on all interactive elements, and provide a clean and intuitive navigation structure using a tab bar as the primary navigation pattern.

### 4.3 Material Listings (PB-06, Charter Scope)
A student must be able to create a listing that includes a title, description, course code, subject category, condition rating selected from a fixed set of values, price, and at least one photo. A listing cannot be submitted unless every required field is present and at least one photo has been uploaded. Listings must support an editable draft state before publishing and a published state visible to other students. Sellers can mark their own listings as sold, which removes them from active search results.

### 4.4 Search and Filtering (PB-07)
Students must be able to search listings by free text matching against title and course code, and filter results by subject, course code, price range, and condition. Search results must return within a reasonable time and support pagination for large result sets. Recent searches should be stored locally for convenience.

### 4.5 Ratings and Reviews (PB-04, PB-08)
After a transaction is marked complete, both the buyer and the seller may submit a rating from one to five stars along with an optional written review. Ratings can only be submitted once per completed transaction per direction, meaning a buyer rates the seller and the seller rates the buyer, but neither can submit more than one rating for the same transaction. The average rating must be displayed consistently on every profile and listing card.

### 4.6 Secure Payments and Commission (PB-05)
The app must process payment through a third party payment gateway integrated into the checkout flow. Every completed transaction must automatically deduct a ten percent platform commission before crediting the seller, with no manual intervention required. Transaction records must be stored with full breakdown of item price, commission amount, and net seller payout. Payment confirmation must trigger an email or push notification to both parties.

### 4.7 Product Review Before Sale (PB-010)
Every new listing must pass through a basic automated content check before becoming publicly visible, flagging prohibited categories such as illegal items. Listings flagged by the automated check are routed to the admin queue for manual review before publication is allowed.

### 4.8 Platform Stability and Functional Completeness (PB-09)
The application must handle network failures gracefully with retry logic and user facing error states. All core flows must be covered by unit and UI tests before each sprint is considered complete, consistent with the testing approach already used in earlier sprints.

### 4.9 Admin Dashboard (Charter Scope)
Administrators require a moderation queue for flagged listings, a transaction log with filtering by date and status, a user management view to suspend or reinstate accounts, and basic analytics covering total users, total transactions, and total commission collected.

### 4.10 Bilingual Interface (Charter Scope)
The app must support English and Arabic, including full right to left layout mirroring when Arabic is selected. All user facing strings must be externalized into localization files rather than hardcoded.

---

## 5. Non Functional Requirements

1. The app targets iOS seventeen and later, built with SwiftUI as the primary UI framework.
2. The app must follow the MVVM architectural pattern throughout, separating views, view models, and services cleanly.
3. All network calls must use async await concurrency rather than completion handler based networking.
4. Sensitive data such as authentication tokens must be stored in the iOS Keychain, never in UserDefaults.
5. The app must support offline viewing of previously loaded listings using local caching.
6. All forms must perform client side validation before submission to reduce unnecessary network calls.
7. The codebase must be modular, with clear separation between Models, Views, ViewModels, Services, and Utilities.
8. Crash free session rate target is above ninety nine percent during the pilot phase.

---

## 6. Technology Stack

### 6.1 Client
Swift five point ten or later. SwiftUI for all interface construction. Swift Concurrency, meaning async await and actors, for asynchronous work. Combine used sparingly only where SwiftUI publishers are required for binding. SwiftData or Core Data for local persistence and offline caching, with SwiftData preferred for new projects on iOS seventeen and later. Keychain Services for secure token storage.

### 6.2 Backend
Firebase is recommended as the backend platform because it provides authentication, a document database through Firestore, file storage for images, and cloud functions for server side logic such as commission calculation, all of which map cleanly onto the requirements without standing up custom infrastructure. The specification below is written against Firebase, but every endpoint described maps to an equivalent REST service if a custom backend is later preferred.

Firebase Authentication handles email and password accounts with custom email domain validation enforced in a Cloud Function trigger on account creation.

Cloud Firestore stores all structured data including users, listings, transactions, ratings, and reports.

Firebase Storage stores listing photos and profile photos.

Cloud Functions handle the ten percent commission calculation on transaction completion, the automated content check on new listings, and email or push notification dispatch.

Firebase Cloud Messaging handles push notifications for new messages, sold confirmations, and payment confirmations.

### 6.3 Payment Gateway
Stripe is recommended for payment processing because it has a mature iOS SDK and supports marketplace style split payments through Stripe Connect, which directly satisfies the automatic commission requirement by routing ninety percent to the seller's connected account and ten percent to the platform account at the moment of transaction.

---

## 7. Data Model

All models below are expressed as Swift structs conforming to Codable and Identifiable so they map directly onto Firestore documents.

### 7.1 User
```swift
struct User: Codable, Identifiable {
    var id: String
    var fullName: String
    var universityEmail: String
    var isEmailVerified: Bool
    var profileImageURL: String?
    var averageRating: Double
    var totalRatings: Int
    var isAdmin: Bool
    var isSuspended: Bool
    var createdAt: Date
    var stripeConnectedAccountID: String?
}
```

### 7.2 Listing
```swift
struct Listing: Codable, Identifiable {
    var id: String
    var sellerID: String
    var title: String
    var description: String
    var courseCode: String
    var subject: String
    var condition: Condition
    var price: Double
    var imageURLs: [String]
    var status: ListingStatus
    var createdAt: Date
    var updatedAt: Date
    var moderationStatus: ModerationStatus
}

enum Condition: String, Codable, CaseIterable {
    case new
    case likeNew
    case good
    case fair
    case poor
}

enum ListingStatus: String, Codable {
    case draft
    case active
    case sold
    case removed
}

enum ModerationStatus: String, Codable {
    case pending
    case approved
    case flagged
    case rejected
}
```

### 7.3 Transaction
```swift
struct Transaction: Codable, Identifiable {
    var id: String
    var listingID: String
    var buyerID: String
    var sellerID: String
    var itemPrice: Double
    var commissionAmount: Double
    var sellerPayout: Double
    var status: TransactionStatus
    var stripePaymentIntentID: String
    var createdAt: Date
    var completedAt: Date?
}

enum TransactionStatus: String, Codable {
    case pending
    case completed
    case refunded
    case disputed
}
```

### 7.4 Rating
```swift
struct Rating: Codable, Identifiable {
    var id: String
    var transactionID: String
    var raterID: String
    var rateeID: String
    var stars: Int
    var comment: String?
    var createdAt: Date
}
```

### 7.5 Report
```swift
struct Report: Codable, Identifiable {
    var id: String
    var listingID: String
    var reporterID: String
    var reason: String
    var status: ReportStatus
    var createdAt: Date
}

enum ReportStatus: String, Codable {
    case open
    case resolved
    case dismissed
}
```

---

## 8. Firestore Collection Structure

```
users
  {userID}

listings
  {listingID}

transactions
  {transactionID}

ratings
  {ratingID}

reports
  {reportID}
```

Each top level collection is flat rather than deeply nested, which keeps queries simple and avoids the read amplification problems associated with deeply nested subcollections. Listings reference sellerID. Transactions reference both buyerID and sellerID along with listingID. Ratings reference transactionID, raterID, and rateeID.

### 8.1 Firestore Indexes Required
A composite index on listings for status and createdAt to support the default active listings feed sorted by newest first.
A composite index on listings for subject, courseCode, and price to support filtered search.
A composite index on transactions for buyerID and status, and a second for sellerID and status, to support order history screens.

---

## 9. Cloud Functions Specification

### 9.1 onUserCreate
Triggered when a new Firebase Authentication account is created. Validates that the email domain matches udst.edu.qa, rejecting and deleting the account immediately if the domain does not match. Sends the verification email through Firebase Authentication's built in flow.

### 9.2 onListingCreate
Triggered when a new listing document is written with moderationStatus equal to pending. Runs an automated keyword check against a maintained list of prohibited terms. If a match is found, sets moderationStatus to flagged and creates an entry in the admin moderation queue. If no match is found, sets moderationStatus to approved automatically.

### 9.3 createPaymentIntent
A callable function invoked by the client at the start of checkout. Accepts a listingID and the authenticated buyer's ID. Looks up the listing price, calculates a ten percent commission, creates a Stripe PaymentIntent using Stripe Connect with application_fee_amount set to the commission and transfer_data pointing at the seller's connected account, and returns the client secret to the app.

### 9.4 onPaymentSucceeded
A Stripe webhook handled through a Cloud Function HTTPS endpoint. On a successful payment intent, creates a Transaction document with status completed, updates the related Listing status to sold, and sends push notifications to both buyer and seller confirming the transaction.

### 9.5 onTransactionCompleted
Triggered when a transaction status changes to completed. Unlocks the ability for both parties to submit a rating for that transaction, and schedules a reminder notification after twenty four hours if no rating has been submitted yet.

---

## 10. REST and Callable Function Contracts

The following describes the callable interface the iOS app uses, written as if calling a typed networking layer over Firebase callable functions. Each function below corresponds to a Cloud Function defined in section 9.

### 10.1 createListing
Request body includes title, description, courseCode, subject, condition, price, and an array of already uploaded image URLs. Response returns the created Listing object with its generated id and moderationStatus.

### 10.2 searchListings
Request body includes an optional text query, optional subject filter, optional courseCode filter, optional minimum and maximum price, optional condition filter, and a pagination cursor. Response returns an array of Listing objects and a nextCursor value for pagination.

### 10.3 createPaymentIntent
Request body includes listingID. Response returns clientSecret and the calculated commissionAmount for display in the checkout confirmation screen before the user commits to paying.

### 10.4 submitRating
Request body includes transactionID, stars, and an optional comment. Response returns the created Rating object and the rateee's updated averageRating.

### 10.5 reportListing
Request body includes listingID and reason. Response returns the created Report object with status open.

### 10.6 adminResolveReport
Restricted to admin accounts. Request body includes reportID and a resolution action of either approve listing, remove listing, or dismiss report. Response returns the updated Report and, if applicable, the updated Listing.

---

## 11. iOS App Architecture

### 11.1 Pattern
The app follows MVVM throughout. Every screen has a corresponding ViewModel class marked with the Observable macro, which owns all state and business logic for that screen. Views remain declarative and free of logic beyond simple presentation conditionals.

### 11.2 Layered Structure
```
EduTrade
  App
    EduTradeApp.swift
    AppState.swift
  Models
    User.swift
    Listing.swift
    Transaction.swift
    Rating.swift
    Report.swift
  Services
    AuthService.swift
    ListingService.swift
    TransactionService.swift
    RatingService.swift
    StorageService.swift
    NotificationService.swift
  ViewModels
    AuthViewModel.swift
    HomeFeedViewModel.swift
    ListingDetailViewModel.swift
    CreateListingViewModel.swift
    SearchViewModel.swift
    CheckoutViewModel.swift
    ProfileViewModel.swift
    AdminDashboardViewModel.swift
  Views
    Authentication
      WelcomeView.swift
      RegisterView.swift
      VerifyEmailView.swift
      LoginView.swift
    Home
      HomeFeedView.swift
      ListingCardView.swift
    Search
      SearchView.swift
      FilterSheetView.swift
    ListingDetail
      ListingDetailView.swift
      SellerProfileSnippetView.swift
    CreateListing
      CreateListingView.swift
      ImagePickerView.swift
    Checkout
      CheckoutView.swift
      PaymentConfirmationView.swift
    Profile
      ProfileView.swift
      MyListingsView.swift
      OrderHistoryView.swift
      EditProfileView.swift
    Ratings
      RateTransactionView.swift
    Admin
      AdminDashboardView.swift
      ModerationQueueView.swift
      TransactionLogView.swift
      UserManagementView.swift
  Components
    PrimaryButton.swift
    LoadingOverlay.swift
    ErrorBanner.swift
    StarRatingView.swift
    ConditionTagView.swift
  Utilities
    Validators.swift
    Formatters.swift
    Constants.swift
  Resources
    Localizable.strings (English)
    Localizable.strings (Arabic)
    Assets.xcassets
```

### 11.3 Networking Layer
A single FirebaseClient wrapper class centralizes all Firestore and Cloud Function access so that ViewModels never call Firebase SDK methods directly. This isolation makes the data layer swappable later without touching any View or ViewModel code, and makes unit testing straightforward through protocol based dependency injection.

```swift
protocol ListingServiceProtocol {
    func fetchActiveListings(cursor: String?) async throws -> ([Listing], String?)
    func createListing(_ listing: Listing) async throws -> Listing
    func searchListings(query: SearchQuery) async throws -> [Listing]
}
```

Every service in the Services folder follows this protocol oriented pattern, with a live Firebase backed implementation and a mock implementation used in unit tests and SwiftUI previews.

---

## 12. Screen by Screen Specification

### 12.1 Welcome Screen
The entry point shown to unauthenticated users. Displays the EduTrade logo, a short tagline describing the platform, a primary button labeled Create Account, and a secondary text link labeled Already have an account, Sign In.

### 12.2 Register Screen
Form fields for full name, university email, password, and confirm password. The email field validates in real time that the domain matches udst.edu.qa, showing an inline error otherwise. The submit button is disabled until all fields pass validation. On success, the app navigates to the Verify Email screen.

### 12.3 Verify Email Screen
Instructs the user to check their university inbox for a verification link. Includes a resend code button with a sixty second cooldown timer. Polls the authentication state every few seconds and automatically advances to the Home Feed once verification is detected.

### 12.4 Login Screen
Standard email and password fields with a forgot password link that triggers Firebase's password reset email flow. Includes basic error states for invalid credentials and unverified accounts.

### 12.5 Home Feed
The default landing screen after login, presented as the first tab. Displays a scrollable grid of ListingCardView items showing the listing photo, title, price, and condition tag. Includes a search bar at the top that navigates to the Search screen on tap. Supports pull to refresh and infinite scroll pagination.

### 12.6 Search Screen
A dedicated search experience with a text field bound to a debounced query, a filter button that opens the Filter Sheet, and a results list identical in card style to the home feed. Recent searches are shown when the query field is empty.

### 12.7 Filter Sheet
A modal sheet with controls for subject category selected from a fixed list, course code text entry, a price range slider, and condition checkboxes. Includes Apply and Reset buttons.

### 12.8 Listing Detail Screen
Displays a photo carousel, title, full description, course code and subject tags, condition badge, price, and a Seller Profile Snippet showing the seller's name, profile photo, and average star rating. Includes a primary Buy Now button that navigates to Checkout, and a Report button that opens a reason picker and submits a Report.

### 12.9 Create Listing Screen
A multi step form. Step one captures photos through an image picker supporting up to six images with at least one required. Step two captures title, description, course code, subject, condition, and price. Step three is a review screen before final submission. Validation prevents advancing between steps until required fields are complete, directly enforcing the requirement that a listing cannot be submitted without a photo and a condition.

### 12.10 Checkout Screen
Displays the listing summary, the item price, the calculated ten percent commission shown transparently to the buyer as a platform fee, and the total charge. Integrates the Stripe Payment Sheet for card entry. On successful payment, navigates to the Payment Confirmation screen.

### 12.11 Payment Confirmation Screen
A simple success state confirming the transaction, with a button to return to the Home Feed and a note that the seller has been notified.

### 12.12 Profile Screen
The final tab, showing the current user's name, profile photo, average rating, and three navigation rows leading to My Listings, Order History, and Edit Profile. Includes a sign out button.

### 12.13 My Listings Screen
A segmented control switching between Active, Sold, and Draft listings, each rendered as a list with edit and remove actions available on active and draft items.

### 12.14 Order History Screen
A segmented control switching between Purchases and Sales, each showing past Transaction records with status, date, and a Rate button that appears once a transaction is completed and unrated.

### 12.15 Rate Transaction Screen
A modal presenting a star selector from one to five and an optional comment field, submitting through the submitRating function described in section ten.

### 12.16 Edit Profile Screen
Allows updating full name and profile photo. Email is not editable after verification for security reasons.

### 12.17 Admin Dashboard
Visible only to accounts where isAdmin is true, accessed through a hidden settings row on the Profile screen. Presents three navigation rows leading to Moderation Queue, Transaction Log, and User Management, along with summary cards showing total users, total active listings, and total commission collected to date.

### 12.18 Moderation Queue Screen
Lists all listings with moderationStatus flagged and all reports with status open, each with Approve and Remove actions that call adminResolveReport.

### 12.19 Transaction Log Screen
A filterable list of all Transaction records with date range and status filters, supporting the post launch monitoring and reporting requirement from the project charter.

### 12.20 User Management Screen
A searchable list of all users with a suspend or reinstate toggle per account, writing to the isSuspended field on the User model.

---

## 13. Navigation Structure

The app root presents a TabView with three tabs for a standard verified student account, namely Home, Search, and Profile. The Create Listing flow is presented as a fourth floating action button accessible from Home rather than a fixed tab, since listing creation is an occasional action rather than a primary navigation destination. Admin accounts see an additional Admin tab appended conditionally based on the isAdmin flag on the authenticated user.

Each tab owns its own NavigationStack so that drill in navigation within Home, such as moving from the feed into a Listing Detail screen and then into Checkout, does not interfere with the navigation history of the Search or Profile tabs.

---

## 14. Localization

All strings live in Localizable.strings files for English and Arabic. The app reads the user's preferred language from device settings by default but exposes a manual language toggle in Edit Profile. SwiftUI's built in layoutDirection environment value is used to mirror layouts automatically when Arabic is active, and all custom views must avoid hardcoded leading or trailing assumptions, using leading and trailing alignment rather than left and right throughout.

---

## 15. Testing Plan

### 15.1 Unit Tests
Validators for email domain checking, password strength, and listing field completeness. ViewModel logic for search filtering, checkout commission calculation display, and rating submission state transitions. Mock service implementations are used throughout so unit tests never touch live Firebase infrastructure.

### 15.2 UI Tests
End to end registration and verification flow. End to end listing creation flow confirming that submission is blocked without a photo. End to end checkout flow using Stripe's test mode card numbers. End to end rating submission flow.

### 15.3 Manual QA Checklist
Verification email actually arrives and link works correctly. Commission math is correct across several price points. Search filters return only matching results. Arabic layout mirrors correctly with no clipped text. Admin moderation actions correctly update listing visibility.

---

## 16. Security Considerations

Firestore security rules must enforce that a user can only write to their own User document, only the listing's sellerID can edit or delete that listing, only admins can write to moderationStatus or isSuspended fields, and Transaction documents are immutable from the client, writable only through Cloud Functions using the Admin SDK. Stripe secret keys and webhook signing secrets must never be embedded in the iOS client, living only in Cloud Functions environment configuration.

---

## 17. Build Phases for Implementation

### Phase One, Foundation
Set up the Xcode project with the folder structure defined in section eleven. Configure Firebase project and connect through GoogleService Info plist. Implement the Models folder. Implement AuthService and the full authentication flow from Welcome through Login.

### Phase Two, Core Marketplace
Implement ListingService, the Home Feed, Listing Detail, and Create Listing screens. Implement Firebase Storage integration for photo uploads.

### Phase Three, Search and Discovery
Implement SearchViewModel and the Filter Sheet, wiring up the composite Firestore indexes described in section eight.

### Phase Four, Payments
Integrate the Stripe iOS SDK, implement the createPaymentIntent Cloud Function, and build the Checkout and Payment Confirmation screens.

### Phase Five, Ratings and Profile
Implement Order History, Rate Transaction, and Edit Profile screens along with the RatingService.

### Phase Six, Admin Tools
Implement the Admin tab and its three subscreens along with the adminResolveReport function.

### Phase Seven, Localization and Polish
Add Arabic localization, run the full manual QA checklist from section fifteen, and address accessibility audit findings.

### Phase Eight, Testing and Pilot Preparation
Complete the unit and UI test suites, run a closed pilot with a small group of students, and address bugs surfaced during the pilot before full launch.

---

## 18. Mapping Back to Original Project Documents

This specification translates every product backlog item from PB-01 through PB-010 into a concrete screen, service, or Cloud Function. The Gantt chart's three sprint structure maps onto build phases one through three for sprint one equivalent work, phases four through five for sprint two equivalent work, and phases six through eight for sprint three equivalent work. The Quality Plan's eight quality criteria are each addressed through the security rules in section sixteen, the testing plan in section fifteen, and the moderation pipeline in sections nine and twelve. The Risk Register's highest scored risks, namely payment service failures, legal exposure from prohibited listings, and website or app technical malfunctions, are directly mitigated by the Stripe Connect integration, the automated moderation check in section nine, and the offline caching and error handling requirements in section five.
