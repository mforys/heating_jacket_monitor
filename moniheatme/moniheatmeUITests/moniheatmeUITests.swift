//
//  moniheatmeUITests.swift
//  moniheatmeUITests
//
//  Created by Marek Forys on 31/12/2021.
//

import XCTest

class moniheatmeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMainScreen() throws {

        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app/*@START_MENU_TOKEN@*/.staticTexts["User"]/*[[".buttons[\"User\"].staticTexts[\"User\"]",".staticTexts[\"User\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
        XCTAssertTrue(app.staticTexts["Current Temperature"].exists)
        XCTAssertTrue(app.staticTexts["Heating Level"].exists)
        XCTAssertTrue(app.staticTexts["None"].exists)
        XCTAssertTrue(app.staticTexts["Steps today"].exists)
        XCTAssertTrue(app.staticTexts["Work safely"].exists)
    }

    func testSetUserName() throws {
        // UI tests must launch the application that they test.
        //let app = XCUIApplication()
        //app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app/*@START_MENU_TOKEN@*/.staticTexts["User"]/*[[".buttons[\"User\"].staticTexts[\"User\"]",".staticTexts[\"User\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)

        app/*@START_MENU_TOKEN@*/.staticTexts["User"]/*[[".buttons[\"User\"].staticTexts[\"User\"]",".staticTexts[\"User\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .textField).element.tap()

        XCTAssertTrue(app.staticTexts["Set"].exists)
        app/*@START_MENU_TOKEN@*/.staticTexts["Set"]/*[[".buttons[\"Set\"].staticTexts[\"Set\"]",".staticTexts[\"Set\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
