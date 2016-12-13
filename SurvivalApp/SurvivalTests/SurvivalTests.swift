//
//  SurvivalTests.swift
//  SurvivalTests
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

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
        RoutingState.avoidLinkIds(from: CLLocationCoordinate2D(latitude: 39.3251732, longitude: -76.6233443), to: CLLocationCoordinate2D(latitude: 39.3254388, longitude: -76.6148042)) {
            linkIds = $0
            semaphore.signal()
        }
        semaphore.wait()
        let red = Set(linkIds!.red)
        let yellow = Set(linkIds!.yellow)
        XCTAssertEqual(red, [52361440,52361443,55411534,43671584,52357502,52375443,55349147,27911542,52427570,55331729,1191119,52427561,55413761,43384745])
        XCTAssertEqual(yellow, [27021437,52357539,1179576,52375364,30667799,57803600,52184078,52184076,27021381,52375483,55349141,52374379,57803602,52375387,57803375,55413765,57803542,52375177,57787716,28820051])
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
