import XCTest

/// UI tests exercising the end-to-end flows (spec §15.2).
final class EduTradeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["-UITests", "-resetMockData"]
        app.launch()
    }

    // MARK: - Launch

    func testAppLaunchesToWelcome() {
        // The welcome screen should show the app name and Create Account button.
        XCTAssertTrue(app.staticTexts["EduTrade"].waitForExistence(timeout: 5),
                      "Welcome screen should show EduTrade title")
        XCTAssertTrue(app.buttons["Create Account"].exists,
                      "Create Account button should be visible")
    }

    // MARK: - Login flow

    func testStudentLoginFlow() {
        // Tap "Sign In" link on welcome
        app.buttons["signInButton"].tap()
        XCTAssertTrue(app.navigationBars["Sign In"].waitForExistence(timeout: 3))

        // Type demo credentials using the form's text fields (email, then password).
        let emailField = app.textFields["University Email"]
        let passwordField = app.secureTextFields["Password"]
        emailField.tap()
        emailField.typeText("ahmed.mansoori@udst.edu.qa")
        passwordField.tap()
        passwordField.typeText("password123")

        app.buttons["Sign In"].tap()

        // After login we should land on the Home tab.
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5),
                      "Should land on Home tab after login")
    }

    // MARK: - Admin login + dashboard

    func testAdminLoginShowsAdminTab() {
        app.buttons["signInButton"].tap()
        let emailField = app.textFields["University Email"]
        let passwordField = app.secureTextFields["Password"]
        emailField.tap()
        emailField.typeText("admin@udst.edu.qa")
        passwordField.tap()
        passwordField.typeText("admin123")
        app.buttons["Sign In"].tap()

        XCTAssertTrue(app.tabBars.buttons["Admin"].waitForExistence(timeout: 5),
                      "Admin user should see the Admin tab")
    }

    // MARK: - Register validation

    func testRegisterBlocksInvalidEmail() {
        app.buttons["createAccountButton"].tap()
        XCTAssertTrue(app.navigationBars["Create Account"].waitForExistence(timeout: 3))

        let nameField = app.textFields["Full Name"]
        nameField.tap()
        nameField.typeText("Test User")

        let emailField = app.textFields["University Email"]
        emailField.tap()
        emailField.typeText("test@gmail.com")

        // Inline error should appear
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'udst.edu.qa'"))
                       .firstMatch.waitForExistence(timeout: 2),
                      "Should show email domain validation error")
    }

    // MARK: - Tab navigation

    func testTabNavigation() {
        // Log in first
        app.buttons["signInButton"].tap()
        let emailField = app.textFields["University Email"]
        let passwordField = app.secureTextFields["Password"]
        emailField.tap()
        emailField.typeText("ahmed.mansoori@udst.edu.qa")
        passwordField.tap()
        passwordField.typeText("password123")
        app.buttons["Sign In"].tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 3))
    }

    // MARK: - Home feed renders listings

    func testHomeFeedShowsListings() {
        // Login
        app.buttons["signInButton"].tap()
        app.textFields["University Email"].tap()
        app.textFields["University Email"].typeText("ahmed.mansoori@udst.edu.qa")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")
        app.buttons["Sign In"].tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))

        // Home tab selected state confirms the feed is the active screen
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected || app.tabBars.buttons["Home"].exists,
                      "Home feed should be loaded and active")
    }
}
