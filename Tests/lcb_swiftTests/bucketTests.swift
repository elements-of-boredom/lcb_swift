//
//  bucketPropertyTests.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/4/17.
//
//

import XCTest
@testable import lcb_swift

class bucketTests : XCTestCase {
    private var bucket:Bucket!
    private var cluster: Cluster!
    
    override func setUp() {
        super.setUp()

        do {
            cluster = try Cluster() //use the default localhost/default
            bucket = try cluster.openBucket(name:"default")
        }catch {
            XCTFail("Failed to initalize cluster, check to  make sure couchbase is running")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        bucket.disconnect()
    }
    
    func testBucketThrowsErrorWhenBadBucketNameIsProvided(){
        do {
            _ = try cluster.openBucket(name: "badname")
            //We shouldn't reach this or we failed
            XCTFail()
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testBucketThrowsErrorWhenUrlIsBad(){
        do {
            let url = URL(string:"couchbasdase://localhost")!
            _ = try Bucket(bucketName: "default", connection: url, password: nil)
            //We shouldn't reach this or we failed
            XCTFail()
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testConfigThrottleWorks() {
        let original = bucket.configThrottle
        XCTAssert(original > 0)
        bucket.configThrottle = original + 1
        XCTAssertNotEqual(original, bucket.configThrottle)
        bucket.configThrottle = original
    }
    
    func testConnectionTimeoutWorks() {
        let original = bucket.connectionTimeout
        XCTAssert(original > 0)
        bucket.connectionTimeout = original + 1
        XCTAssertNotEqual(original, bucket.connectionTimeout)
        bucket.connectionTimeout = original
    }
    
    func testDurabilityIntervalWorks() {
        let original = bucket.durabilityInterval
        XCTAssert(original > 0)
        bucket.durabilityInterval = original + 1
        XCTAssertNotEqual(original, bucket.durabilityInterval)
        bucket.durabilityInterval = original
    }
    
    func testDurabilityTimeoutWorks() {
        let original = bucket.durabilityTimeout
        XCTAssert(original > 0)
        bucket.durabilityTimeout = original + 1
        XCTAssertNotEqual(original, bucket.durabilityTimeout)
        bucket.durabilityTimeout = original
    }
    
    func testLCBVersionWorks() {
        XCTAssert(bucket.lcbVersion != "")
    }
    
    func testManagementTimeoutWorks() {
        let original = bucket.managementTimeout
        XCTAssert(original > 0)
        bucket.managementTimeout = original + 1
        XCTAssertNotEqual(original, bucket.managementTimeout)
        bucket.managementTimeout = original
    }
    
    func testN1qlTimeoutWorks() {
        let original = bucket.n1qlTimeout
        XCTAssert(original > 0)
        bucket.n1qlTimeout = original + 1
        XCTAssertNotEqual(original, bucket.n1qlTimeout)
        bucket.n1qlTimeout = original
    }
    
    func testNodeConnectionTimeoutWorks() {
        let original = bucket.nodeConnectionTimeout
        XCTAssert(original > 0)
        bucket.nodeConnectionTimeout = original + 1
        XCTAssertNotEqual(original, bucket.nodeConnectionTimeout)
        bucket.nodeConnectionTimeout = original
    }
    
    func testOperationTimeoutWorks() {
        let original = bucket.operationTimeout
        XCTAssert(original > 0)
        bucket.operationTimeout = original + 1
        XCTAssertNotEqual(original, bucket.operationTimeout)
        bucket.operationTimeout = original
    }
    
    func testViewTimeoutWorks() {
        let original = bucket.viewTimeout
        XCTAssert(original > 0)
        bucket.viewTimeout = original + 1
        XCTAssertNotEqual(original, bucket.viewTimeout)
        bucket.viewTimeout = original
    }
    
    static var allTests = [
        ("configThrottle", testConfigThrottleWorks),
        ("connectionTimeout", testConnectionTimeoutWorks),
        ("durabilityInterval", testDurabilityIntervalWorks),
        ("durabilityTimeout", testDurabilityTimeoutWorks),
        ("lcbVersion", testLCBVersionWorks),
        ("managementTimeout", testManagementTimeoutWorks),
        ("n1qlTimeout", testN1qlTimeoutWorks),
        ("nodeConnectionTimeout", testNodeConnectionTimeoutWorks),
        ("operationTimeout", testOperationTimeoutWorks),
        ("viewTimeout", testViewTimeoutWorks),
        ("bucketConnectionFails",testBucketThrowsErrorWhenBadBucketNameIsProvided),
        ("bucketConnectWithBadURLFails",testBucketThrowsErrorWhenUrlIsBad)
    ]
}
