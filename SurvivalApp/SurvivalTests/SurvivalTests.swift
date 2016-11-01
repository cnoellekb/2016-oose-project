//
//  SurvivalTests.swift
//  SurvivalTests
//
//  Created by 张国晔 on 2016/10/5.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

@testable import Survival
import XCTest
import CoreLocation

class SurvivalTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAvoidLinkIds() {
        let semaphore = DispatchSemaphore(value: 0)
        var linkIds: AvoidLinkIds?
        RoutingState.avoidLinkIds(from: CLLocationCoordinate2D(latitude: 38.987194, longitude: -76.945999), to: CLLocationCoordinate2D(latitude: 39.004611, longitude: -76.875671)) {
            linkIds = $0
            semaphore.signal()
        }
        semaphore.wait()
        let red = Set(linkIds!.red)
        let yellow = Set(linkIds!.yellow)
        XCTAssertEqual(red, [39503765,39571806,39572844,39664759])
        XCTAssertEqual(yellow, [39303826,39370877,39484084,39530425,39643466,39643812,39646304,39651557,39659946,39667437])
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
