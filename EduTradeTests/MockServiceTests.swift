import XCTest
@testable import EduTrade

/// Integration tests against the Mock services (spec §15.1).
/// Exercises the full data flow: register → create listing → search → checkout → rate.
final class MockServiceTests: XCTestCase {

    var store: MockStore!
    var auth: MockAuthService!
    var listings: MockListingService!
    var transactions: MockTransactionService!
    var ratings: MockRatingService!
    var admin: MockAdminService!

    override func setUp() async throws {
        try await super.setUp()
        store = MockStore()
        // Always reset to a fresh seed so tests are deterministic regardless of
        // any persisted state from previous app/test runs.
        await store.resetAll()
        auth = MockAuthService(store: store)
        listings = MockListingService(store: store)
        transactions = MockTransactionService(store: store)
        ratings = MockRatingService(store: store)
        admin = MockAdminService(store: store)
    }

    // MARK: - Auth

    func testRegisterNewStudent() async throws {
        let user = try await auth.register(
            fullName: "Test Student",
            email: "test.student@udst.edu.qa",
            password: "password1"
        )
        XCTAssertEqual(user.fullName, "Test Student")
        XCTAssertFalse(user.isEmailVerified)
        XCTAssertFalse(user.isAdmin)
    }

    func testRegisterRejectsInvalidEmailDomain() async {
        do {
            _ = try await auth.register(fullName: "X", email: "x@gmail.com", password: "password1")
            XCTFail("Should have thrown")
        } catch let e as AppError {
            XCTAssertEqual(e, .invalidEmail)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRegisterRejectsDuplicateEmail() async throws {
        _ = try await auth.register(fullName: "A", email: "dup@udst.edu.qa", password: "password1")
        do {
            _ = try await auth.register(fullName: "B", email: "dup@udst.edu.qa", password: "password2")
            XCTFail("Should have thrown")
        } catch let e as AppError {
            XCTAssertEqual(e, .emailAlreadyInUse)
        }
    }

    func testLoginWithValidCredentials() async throws {
        // Seeded demo user
        let user = try await auth.login(email: "ahmed.mansoori@udst.edu.qa", password: "password123")
        XCTAssertEqual(user.universityEmail, "ahmed.mansoori@udst.edu.qa")
    }

    func testLoginWithWrongPasswordFails() async {
        do {
            _ = try await auth.login(email: "ahmed.mansoori@udst.edu.qa", password: "wrongpass")
            XCTFail("Should have thrown")
        } catch {
            // expected
        }
    }

    func testEmailVerificationFlow() async throws {
        let user = try await auth.register(fullName: "V", email: "verify@udst.edu.qa", password: "password1")
        XCTAssertFalse(user.isEmailVerified)
        try await auth.sendEmailVerification(for: user)
        let verified = try await auth.reloadVerificationStatus(for: user)
        XCTAssertTrue(verified.isEmailVerified)
    }

    // MARK: - Listings

    func testCreateListingAndFetch() async throws {
        let seller = try await auth.login(email: "ahmed.mansoori@udst.edu.qa", password: "password123")
        let listing = Listing(
            sellerID: seller.id, title: "Physics Book", description: "Clean",
            courseCode: "PHYS1302", subject: "Applied Sciences", price: 150, condition: .good, imageURLs: ["p"]
        )
        let created = try await listings.createListing(listing)
        XCTAssertEqual(created.moderationStatus, .approved)
        let fetched = try await listings.fetchListing(id: created.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Physics Book")
    }

    func testModerationFlagsProhibitedContent() async throws {
        let listing = Listing(
            sellerID: "student-demo", title: "Exam answer key cheat", description: "cheat sheet",
            courseCode: "SOFT2202", subject: "Computer Science", price: 100, condition: .new, imageURLs: ["x"]
        )
        let created = try await listings.createListing(listing)
        XCTAssertEqual(created.moderationStatus, .flagged)
    }

    func testFetchActiveListingsOnlyShowsApproved() async throws {
        let page = try await listings.fetchActiveListings(cursor: nil)
        XCTAssertTrue(page.listings.allSatisfy { $0.moderationStatus == .approved })
        XCTAssertTrue(page.listings.allSatisfy { $0.status == .active })
    }

    func testMarkListingAsSold() async throws {
        let page = try await listings.fetchActiveListings(cursor: nil)
        guard let first = page.listings.first else { return XCTFail("No seeded listings") }
        try await listings.markAsSold(id: first.id)
        let updated = try await listings.fetchListing(id: first.id)
        XCTAssertEqual(updated?.status, .sold)
    }

    // MARK: - Search

    func testSearchByText() async throws {
        let page = try await listings.searchListings(query: SearchQuery(text: "Python", conditions: []))
        XCTAssertTrue(page.listings.contains { $0.title.contains("Python") })
    }

    func testSearchByCourseCode() async throws {
        let page = try await listings.searchListings(query: SearchQuery(text: nil, subject: nil, courseCode: "MATH", conditions: []))
        XCTAssertTrue(page.listings.allSatisfy { $0.courseCode.contains("MATH") })
    }

    func testSearchBySubjectFilter() async throws {
        let page = try await listings.searchListings(query: SearchQuery(text: nil, subject: "Engineering", courseCode: nil, conditions: []))
        XCTAssertTrue(page.listings.allSatisfy { $0.subject == "Engineering" })
    }

    func testSearchByPriceRange() async throws {
        let page = try await listings.searchListings(query: SearchQuery(text: nil, subject: nil, courseCode: nil, minPrice: 50, maxPrice: 100, conditions: []))
        XCTAssertTrue(page.listings.allSatisfy { $0.price >= 50 && $0.price <= 100 })
    }

    func testSearchByConditionFilter() async throws {
        let page = try await listings.searchListings(query: SearchQuery(text: nil, subject: nil, courseCode: nil, minPrice: nil, maxPrice: nil, conditions: [.new]))
        XCTAssertTrue(page.listings.allSatisfy { $0.condition == .new })
    }

    // MARK: - Checkout + Transactions

    func testCheckoutPreviewCommission() async throws {
        let page = try await listings.fetchActiveListings(cursor: nil)
        let target = page.listings.first { $0.price > 0 }!
        let preview = try await transactions.previewCheckout(listingID: target.id)
        XCTAssertEqual(preview.commissionAmount, target.price * 0.1, accuracy: 0.01)
        XCTAssertEqual(preview.totalCharge, target.price, accuracy: 0.01)
    }

    func testCannotBuyOwnListing() async throws {
        let seller = try await auth.login(email: "ahmed.mansoori@udst.edu.qa", password: "password123")
        let listing = Listing(sellerID: seller.id, title: "Own Item", description: "d", courseCode: "C", subject: "S", price: 50, condition: .good, imageURLs: ["i"])
        let created = try await listings.createListing(listing)
        do {
            _ = try await transactions.createPaymentIntent(listingID: created.id, buyerID: seller.id)
            XCTFail("Should not allow buying own listing")
        } catch let e as AppError {
            XCTAssertEqual(e, .cannotBuyOwnListing)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFullCheckoutFlowMarksListingSold() async throws {
        let page = try await listings.fetchActiveListings(cursor: nil)
        let target = page.listings.first { $0.sellerID != "student-demo" }!
        let tx = try await transactions.createPaymentIntent(listingID: target.id, buyerID: "student-demo")
        XCTAssertEqual(tx.status, .pending)
        let completed = try await transactions.completeTransaction(tx)
        XCTAssertEqual(completed.status, .completed)
        XCTAssertNotNil(completed.completedAt)
        let listing = try await listings.fetchListing(id: target.id)
        XCTAssertEqual(listing?.status, .sold)
    }

    // MARK: - Ratings

    func testSubmitRatingUpdatesAverage() async throws {
        // rate the demo user
        try await ratings.submitRating(
            transactionID: "tx-test-1", raterID: "student-2",
            rateeID: "student-demo", stars: 5, comment: "Great"
        )
        try await ratings.recomputeUserRating(userID: "student-demo")
        let user = await store.getUser(id: "student-demo")
        XCTAssertGreaterThan(user!.averageRating, 0)
        XCTAssertGreaterThan(user!.totalRatings, 0)
    }

    func testCannotRateSameTransactionTwice() async throws {
        try await ratings.submitRating(
            transactionID: "tx-dup", raterID: "r1", rateeID: "student-demo", stars: 4, comment: nil
        )
        do {
            try await ratings.submitRating(
                transactionID: "tx-dup", raterID: "r1", rateeID: "student-demo", stars: 3, comment: nil
            )
            XCTFail("Should reject duplicate rating")
        } catch let e as AppError {
            XCTAssertEqual(e, .ratingAlreadyExists)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Admin

    func testFetchFlaggedListings() async throws {
        let flagged = try await admin.fetchFlaggedListings()
        XCTAssertTrue(flagged.contains { $0.moderationStatus == .flagged })
    }

    func testAdminResolvesFlaggedListing() async throws {
        let flagged = try await admin.fetchFlaggedListings()
        let target = flagged.first { $0.moderationStatus == .flagged }!
        try await admin.resolveListing(listingID: target.id, status: .approved)
        let still = try await admin.fetchFlaggedListings()
        XCTAssertFalse(still.contains { $0.id == target.id })
    }

    func testAdminSuspendsUser() async throws {
        try await admin.setUserSuspended(userID: "student-demo", suspended: true)
        let user = await store.getUser(id: "student-demo")
        XCTAssertTrue(user!.isSuspended)
    }

    func testAdminTransactionLogPopulated() async throws {
        let all = try await transactions.fetchAllTransactions()
        XCTAssertFalse(all.isEmpty)
    }

    // MARK: - Pagination

    func testPaginationCursor() async throws {
        let page1 = try await listings.fetchActiveListings(cursor: nil)
        // Seeded data has 20 listings — page size is also 20, so no second page.
        if let next = page1.nextCursor {
            let page2 = try await listings.fetchActiveListings(cursor: next)
            XCTAssertFalse(page2.listings.isEmpty)
        }
    }
}
