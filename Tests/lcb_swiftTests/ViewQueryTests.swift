//
//  viewQueryTests.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import XCTest
@testable import lcb_swift

class ViewQueryTests: XCTestCase {
    override func setUp() {
        super.setUp()

    }

    override func tearDown() {
        super.tearDown()
    }

    func testViewQueryOptionsStringifyCorrectly() {
        let vq = ViewQuery(designDocument: "ddoc", viewName: "viewName")
        let query = vq.key("mykey")
            .limit(10)
            .includeDocs(true)
            .fullSet(true)
            .group(true)
            .groupLevel(1)
            .keys(["1", "2", "3"])
            .order(.ascending)
            .skip(15)

        let queryString = query.optionString()
        XCTAssertTrue(queryString.contains("limit=10"))
        XCTAssertTrue(queryString.contains("descending=false"))
        XCTAssertTrue(queryString.contains("key=mykey"))
        XCTAssertTrue(queryString.contains("skip=15"))
        XCTAssertTrue(queryString.contains("keys=[\"1\",\"2\",\"3\"]"))
        XCTAssertTrue(queryString.contains("group_level=1"))
        XCTAssertTrue(queryString.contains("full_set=true"))
        XCTAssertTrue(queryString.contains("include_docs=true"))
        XCTAssertTrue(queryString.contains("group=true"))
    }

    func testViewQueryOptionsStringDoesntIncludeFalsyValues() {
        let vq = ViewQuery(designDocument: "ddoc", viewName: "viewName")
        let query = vq.key("mykey")
            .includeDocs(false)
            .order(.descending)
            .fullSet(false)

        let queryString = query.optionString()

        XCTAssertFalse(queryString.contains("full_set=true") || queryString.contains("full_set=false"))
        XCTAssertFalse(queryString.contains("include_docs=true") || queryString.contains("include_docs=false"))
        XCTAssertTrue(queryString.contains("descending=true"))
        XCTAssertTrue(queryString.contains("key=mykey"))

    }
    
    func testSpatialQueryOptionsStringifyCorrectly() {
        let vq = SpatialQuery(designDocument: "ddoc", viewName: "viewName")
        let query = vq.limit(10)
            .skip(15).range(start:[0,1,2,3], end:[4,5,6,7])
            .boundingBox(left: 1, top: 2, right: 3, bottom: 4)
        
        let queryString = query.optionString()
        XCTAssertTrue(queryString.contains("limit=10"))
        XCTAssertTrue(queryString.contains("skip=15"))
        XCTAssertTrue(queryString.contains("start_range=[0, 1, 2, 3]"))
        XCTAssertTrue(queryString.contains("end_range=[4, 5, 6, 7]"))
        XCTAssertTrue(queryString.contains("bbox=1,2,3,4"))
    }

    static var allTests = [
        ("testQueryOptions", testViewQueryOptionsStringifyCorrectly),
        ("testNegativeQueryOptions", testViewQueryOptionsStringDoesntIncludeFalsyValues)
    ]
}
