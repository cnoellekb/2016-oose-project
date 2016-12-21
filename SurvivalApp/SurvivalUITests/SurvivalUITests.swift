//
//  SurvivalUITests.swift
//  SurvivalUITests
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import XCTest

class SurvivalUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAll() {
        let exists = NSPredicate(format: "exists == 1")
        let app = XCUIApplication()
        
        let fromTextField = app.textFields["My Location"]
        fromTextField.tap()
        fromTextField.typeText("Baltimore\n")
        
        let setButton = app.tables.children(matching: .cell).element(boundBy: 0).buttons["Set"]
        expectation(for: exists, evaluatedWith: setButton, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        setButton.tap()
        
        let toTextField = app.textFields.containing(.staticText, identifier:"To: ").element
        toTextField.tap()
        toTextField.typeText("Towson\n")
        
        expectation(for: exists, evaluatedWith: setButton, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        setButton.tap()
        
        Thread.sleep(forTimeInterval: 5)
        app.buttons["Start"].tap()
        
        let speakerButton = app.buttons["Speaker"]
        speakerButton.tap()
        speakerButton.tap()
        app.buttons["Delete"].tap()
        app.alerts["Stop navigation?"].buttons["Stop"].tap()
    }
}
