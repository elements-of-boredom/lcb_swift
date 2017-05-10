//
//  viewQueryTests.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import XCTest
@testable import lcb_swift


class viewQueryTests : XCTestCase {
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
            .keys(["1","2","3"])
            .order(.Ascending)
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
            .order(.Descending)
            .fullSet(false)
        
        let queryString = query.optionString()
        
        XCTAssertFalse(queryString.contains("full_set=true") || queryString.contains("full_set=false"))
        XCTAssertFalse(queryString.contains("include_docs=true") || queryString.contains("include_docs=false"))
        XCTAssertTrue(queryString.contains("descending=true"))
        XCTAssertTrue(queryString.contains("key=mykey"))
        
        
    }
    
    static var allTests = [
        ("testQueryOptions", testViewQueryOptionsStringifyCorrectly),
        ("testNegativeQueryOptions",testViewQueryOptionsStringDoesntIncludeFalsyValues)
    ]
}
