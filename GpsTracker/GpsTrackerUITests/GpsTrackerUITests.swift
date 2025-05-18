//
//  GpsTrackerUITests.swift
//  GpsTrackerUITests
//
//  Created by tanel teemusk on 17.05.2025.
//

import XCTest

final class GpsTrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    private func wait(for duration: TimeInterval) {
        let expectation = XCTestExpectation(description: "Waiting \(duration) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: duration + 1)
    }

    @MainActor
    func testElementExistance() throws {
        let app = XCUIApplication()
        app.launch()

        let locationIcon = app.images["locationIcon"]
        XCTAssertTrue(locationIcon.exists, "Location icon not found")
        XCTAssertTrue(locationIcon.isHittable, "Location icon is not interactive")

        let appTitle = app.staticTexts["appTitle"]
        XCTAssertTrue(appTitle.exists, "App title not found")
        XCTAssertEqual(appTitle.label, "GPS Tracker", "App title text doesn't match expected value")

        let appDescription = app.staticTexts["appDescription"]
        XCTAssertTrue(appDescription.exists, "App description text not found")
        XCTAssertTrue(appDescription.label.contains("location tracking"), "App description doesn't contain expected text")

        let trackingButton = app.buttons["trackingButton"]
        XCTAssertTrue(trackingButton.exists, "Tracking button not found")
        XCTAssertTrue(trackingButton.isEnabled, "Tracking button should be enabled initially")
        XCTAssertEqual(trackingButton.label, "START", "Button should display START initially")

        let errorMessageExists = app.staticTexts["errorMessage"].exists
        if errorMessageExists {
            let errorMessage = app.staticTexts["errorMessage"]
            XCTAssertTrue(errorMessage.exists, "Error message should be visible if present in UI")
        }
    }
}
