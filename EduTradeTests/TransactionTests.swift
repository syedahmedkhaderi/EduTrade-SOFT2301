import XCTest
@testable import EduTrade

/// Unit tests for commission math and Transaction factory (spec §4.6, §15.1).
final class TransactionTests: XCTestCase {

    func testCommissionCalculation10Percent() {
        let listing = Listing(
            sellerID: "s1", title: "T", description: "D",
            courseCode: "C", subject: "S", price: 100, condition: .new, imageURLs: ["i"]
        )
        let tx = Transaction.make(listing: listing, buyerID: "b1")
        XCTAssertEqual(tx.commissionAmount, 10.0, accuracy: 0.001)
        XCTAssertEqual(tx.sellerPayout, 90.0, accuracy: 0.001)
        XCTAssertEqual(tx.itemPrice, 100.0, accuracy: 0.001)
    }

    func testCommissionOnFractionalPrice() {
        let listing = Listing(
            sellerID: "s1", title: "T", description: "D",
            courseCode: "C", subject: "S", price: 149.99, condition: .good, imageURLs: ["i"]
        )
        let tx = Transaction.make(listing: listing, buyerID: "b1")
        XCTAssertEqual(tx.commissionAmount, 15.0, accuracy: 0.01)
        XCTAssertEqual(tx.sellerPayout, 134.99, accuracy: 0.01)
    }

    func testCommissionOnZeroPrice() {
        let listing = Listing(
            sellerID: "s1", title: "T", description: "D",
            courseCode: "C", subject: "S", price: 0, condition: .fair, imageURLs: ["i"]
        )
        let tx = Transaction.make(listing: listing, buyerID: "b1")
        XCTAssertEqual(tx.commissionAmount, 0)
        XCTAssertEqual(tx.sellerPayout, 0)
    }

    func testTransactionLinksBuyerAndSeller() {
        let listing = Listing(
            sellerID: "seller-9", title: "T", description: "D",
            courseCode: "C", subject: "S", price: 50, condition: .new, imageURLs: ["i"]
        )
        let tx = Transaction.make(listing: listing, buyerID: "buyer-3")
        XCTAssertEqual(tx.buyerID, "buyer-3")
        XCTAssertEqual(tx.sellerID, "seller-9")
        XCTAssertEqual(tx.listingID, listing.id)
    }

    func testRoundedTo2Precision() {
        XCTAssertEqual(Double(3.14159).roundedTo2(), 3.14)
        XCTAssertEqual(Double(9.999).roundedTo2(), 10.0)
        XCTAssertEqual(Double(0.005).roundedTo2(), 0.01)
        XCTAssertEqual(Double(0.004).roundedTo2(), 0.0)
    }
}
