//
//  ViewQueryIntegrationTests.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/15/17.
//
//

import Foundation
import XCTest
@testable import lcb_swift

/// This class is not enabled in the test suite by default as it is not
/// a traditional unit test and has chained dependencies which really defeats the purpose
/// of a unit test. However, tests are tests and this needs to be tested somehow.
class ViewQueryIntegrationTests: XCTestCase {
    
    private var bucket: Bucket!
    private var cluster: Cluster!
    let docKey = "key-\(UUID().uuidString)"
    override func setUp() {
        super.setUp()
        
        do {
            cluster = try Cluster() //use the default localhost/default
            bucket = try cluster.openBucket(name:"beer-sample")
        } catch {
            XCTFail("Failed to initalize cluster, check to  make sure couchbase is running")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        bucket.disconnect()
    }
    
    func testViewQueryWorks() {
        let exp = expectation(description: "beer query")
        let query = ViewQuery(designDocument: "beer", viewName: "brewery_beers")
        try? bucket.query(query: query) { result in
            switch result {
            case let .error(msg):
                XCTFail(msg)
            case let .success(results, meta):
                if let docid = results, let firstrow = docid.first {
                    XCTAssert(firstrow.doc == nil, "No document should exist as include_docs was not added")
                    XCTAssert(firstrow.errors == nil)
                    XCTAssert(meta != nil)
                }
                exp.fulfill()
            }
            
        }
        expect()
    }
    
    func testViewQueryWorksWithLimit() {
        let exp = expectation(description: "beer query")
        let query = ViewQuery(designDocument: "beer", viewName: "brewery_beers")
        let mquery = query.limit(10).includeDocs(true)
        try? bucket.query(query: mquery) { result in
            switch result {
            case let .error(msg):
                XCTFail(msg)
            case let .success(results, meta):
                if let docid = results, let firstrow = docid.first {
                    print(firstrow.key)
                    XCTAssert(firstrow.doc != nil)
                    XCTAssert(firstrow.errors == nil)
                    XCTAssert(results?.count == 10)
                    XCTAssert(meta != nil)
                    XCTAssert((meta?.totalRows)! >= (results?.count)!)
                }
                exp.fulfill()
            }
            
        }
        expect()
    }

    
    func expect() {
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
            
        }
    }
}
