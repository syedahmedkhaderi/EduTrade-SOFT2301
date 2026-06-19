import XCTest
@testable import EduTrade

/// Unit tests for Validators (spec §15.1).
final class ValidatorTests: XCTestCase {

    // MARK: - Email

    func testValidUniversityEmailAccepted() {
        XCTAssertTrue(Validators.isValidUniversityEmail("ahmed@udst.edu.qa"))
        XCTAssertTrue(Validators.isValidUniversityEmail("sara.kuwari@udst.edu.qa"))
        XCTAssertTrue(Validators.isValidUniversityEmail("first.last+tag@udst.edu.qa"))
    }

    func testInvalidEmailRejected() {
        XCTAssertFalse(Validators.isValidUniversityEmail("ahmed@gmail.com"))
        XCTAssertFalse(Validators.isValidUniversityEmail("ahmed@udst.edu"))     // wrong TLD
        XCTAssertFalse(Validators.isValidUniversityEmail("ahmed@udst.ac.qa"))   // wrong subdomain
        XCTAssertFalse(Validators.isValidUniversityEmail(""))
        XCTAssertFalse(Validators.isValidUniversityEmail("not-an-email"))
    }

    func testEmailDomainNormalization() {
        // Should accept mixed case and trim whitespace.
        XCTAssertTrue(Validators.isValidUniversityEmail("Ahmed@UDST.EDU.QA"))
    }

    // MARK: - Password

    func testValidPasswordAccepted() {
        XCTAssertTrue(Validators.isValidPassword("password1"))
        XCTAssertTrue(Validators.isValidPassword("Abc12345"))
        XCTAssertTrue(Validators.isValidPassword("complexP@ss1"))
    }

    func testShortPasswordRejected() {
        XCTAssertFalse(Validators.isValidPassword("short1"))
        XCTAssertFalse(Validators.isValidPassword("abc12"))
    }

    func testPasswordMissingDigitRejected() {
        XCTAssertFalse(Validators.isValidPassword("onlyletters"))
    }

    func testPasswordMissingLetterRejected() {
        XCTAssertFalse(Validators.isValidPassword("12345678"))
    }

    func testPasswordStrengthMessages() {
        XCTAssertNil(Validators.passwordStrengthMessage(""))
        XCTAssertNotNil(Validators.passwordStrengthMessage("short"))
        XCTAssertNotNil(Validators.passwordStrengthMessage("longenough"))
        XCTAssertNil(Validators.passwordStrengthMessage("validpass1"))
    }

    // MARK: - Listing validation

    func testValidListingAccepted() {
        XCTAssertTrue(Validators.isListingValid(
            title: "Calculus Textbook",
            description: "Great condition",
            courseCode: "MATH1401",
            subject: "Mathematics",
            price: 100,
            imageCount: 2
        ))
    }

    func testListingWithoutPhotoRejected() {
        XCTAssertFalse(Validators.isListingValid(
            title: "Calculus Textbook",
            description: "Great condition",
            courseCode: "MATH1401",
            subject: "Mathematics",
            price: 100,
            imageCount: 0
        ))
    }

    func testListingWithZeroPriceRejected() {
        XCTAssertFalse(Validators.isListingValid(
            title: "Calculus Textbook",
            description: "Great condition",
            courseCode: "MATH1401",
            subject: "Mathematics",
            price: 0,
            imageCount: 1
        ))
    }

    func testListingWithEmptyFieldsRejected() {
        XCTAssertFalse(Validators.isListingValid(
            title: "", description: "d", courseCode: "C", subject: "s", price: 10, imageCount: 1
        ))
    }

    // MARK: - Price

    func testValidPriceRange() {
        XCTAssertTrue(Validators.isValidListingPrice(1))
        XCTAssertTrue(Validators.isValidListingPrice(99.99))
        XCTAssertTrue(Validators.isValidListingPrice(10_000))
    }

    func testInvalidPriceRejected() {
        XCTAssertFalse(Validators.isValidListingPrice(0))
        XCTAssertFalse(Validators.isValidListingPrice(-5))
        XCTAssertFalse(Validators.isValidListingPrice(10_001))
    }

    // MARK: - Rating

    func testValidStarCounts() {
        for s in 1...5 { XCTAssertTrue(Validators.isValidStarCount(s)) }
    }

    func testInvalidStarCounts() {
        XCTAssertFalse(Validators.isValidStarCount(0))
        XCTAssertFalse(Validators.isValidStarCount(6))
        XCTAssertFalse(Validators.isValidStarCount(-1))
    }
}
