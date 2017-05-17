//
//  bucketIntegrationTests.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/11/17.
//
//

import XCTest
@testable import lcb_swift

/// This class is not enabled in the test suite by default as it is not
/// a traditional unit test and has chained dependencies which really defeats the purpose
/// of a unit test. However, tests are tests and this needs to be tested somehow.
class BucketIntegrationTests: XCTestCase {

    private var bucket: Bucket!
    private var cluster: Cluster!
    let docKey = "key-\(UUID().uuidString)"
    override func setUp() {
        super.setUp()

        do {
            cluster = try Cluster() //use the default localhost/default
            bucket = try cluster.openBucket(name:"default")
        } catch {
            XCTFail("Failed to initalize cluster, check to  make sure couchbase is running")
            exit(1)
        }
    }

    override func tearDown() {
        super.tearDown()
        bucket.disconnect()
    }

    func testCRUDChain() {

        _ = createRecord()

        let readE = expectation(description: "ReadDoc")
        try? bucket.get(key:docKey) { result in
            switch result {
            case .success(_):
                readE.fulfill()

            case let .error(msg):
                XCTFail(msg)
            }
        }
        expect()

        deleteRecord()
    }

    func testN1QLReadSuccess() {
        _ = createRecord(data:["name": "greg", "age": 3920])

        guard let query = try? N1QLQuery(statement: "select name,age from default where name=$1",
                                            params:["greg"], consistency:.none) else {
            XCTFail("Invalid query parameters")
            return
        }
         let n1qlE = expectation(description: "N1QL")

        try? bucket.query(query: query) { result in
            switch result {
            case let .success(_, rows):
                XCTAssert(rows.count > 0)
                n1qlE.fulfill()
                break
            case let .error(msg):
                XCTFail(msg)
            case let .queryFailed(summary):
                if let failed = summary as? [String:Any], let errors = failed["errors"] as? [[String:Any]] {
                    XCTFail("failed query because:\(errors[0]["msg"] ?? "")")
                    break
                }
                XCTFail("failed query because:")
                break
            }
        }
        expect()

        deleteRecord()
    }

    func testN1QLReadFail() {
        _ = createRecord()

        guard let query = try? N1QLQuery(statement: "select name,age, *.* from default where name=$1", params:["greg"], consistency:.none) else {
            XCTFail("Invalid query parameters")
            return
        }
        let n1qlE = expectation(description: "N1QL")

        try? bucket.query(query: query) { result in
            switch result {
            case .success(_, _):
                XCTFail("Read did not return an error with invalid syntax...check the test")
                break
            case let .error(msg):
                XCTFail(msg)
                break
            case .queryFailed(_):
                n1qlE.fulfill()
                break
            }
        }
        expect()

        deleteRecord()

    }

    func testMultiReadSucceedsWithMissingDocument() {
        _ = createRecord()
        let readE = expectation(description: "ReadDocs")

        let keys = [docKey, "key-NeverGoingToBEHere"]
        bucket.getMulti(keys: keys) { result in
            switch result {
            case let .error(msg):
                XCTFail(msg)
            case let .success(errCount, results):
                XCTAssert(errCount == 1)
                XCTAssert(results[keys[0]] != nil)
                readE.fulfill()
            }
        }

        expect()

        deleteRecord()
    }

    func testAppendFailsWhenDocumentMissing() {
        let createE = expectation(description:"appendDoc")

        try? bucket.append(key:"DocumentDoesntExist1092384023870", value:"Holla ") { result in
            switch result {
            case .success(_):
                XCTFail("Append should not create a document")
            case let .error(msg):
                XCTAssert(msg.contains("not stored"))
                createE.fulfill()
            }
        }
        expect()
    }

    func testAppendWorks() {
        deleteRecord(key:"appendDoc")
        let createE = expectation(description: "CreateDoc")

        let opts = StoreOptions(persistTo: 0, replicateTo: 0, expiry: 0, cas: 0)
        try? bucket.insert(key: "appendDoc", value: "Holla ", options: opts) { result in
            switch result {
            case .success(_):
                createE.fulfill()
            case .error(_):
                XCTFail()
                createE.fulfill()
            }
        }
        expect()

        let updateE = expectation(description:"updateDoc")

        try? bucket.append(key:"appendDoc", value:"Back!") { result in
            switch result {
            case .success(_):
                updateE.fulfill()
            case let .error(msg):
                XCTFail(msg)
            }
        }
        expect()

        let readE = expectation(description:"updateDoc")

        try? bucket.get(key:"appendDoc") { result in
            switch result {
            case let .success(doc, _):
                if let result = (doc as? String) {
                    XCTAssert(result == "Holla Back!")
                    readE.fulfill()
                }
                else{
                    XCTFail(doc as! String)
                }
                case let .error(msg):
                XCTFail(msg)
            }
        }

        expect()

        deleteRecord(key: "appendDoc")
    }

    func testPrependWorks() {
        let docKey = "prependDoc"
        deleteRecord(key:docKey)
        let createE = expectation(description: "CreateDoc")

        let opts = StoreOptions(persistTo: 0, replicateTo: 0, expiry: 0, cas: 0)
        try? bucket.insert(key: docKey, value: "Holla ", options: opts) { result in
            switch result {
            case .success(_):
                createE.fulfill()
            case .error(_):
                XCTFail()
                createE.fulfill()
            }
        }
        expect()

        let updateE = expectation(description:"updateDoc")

        try? bucket.prepend(key:docKey, value:"Back!") { result in
            switch result {
            case .success(_):
                updateE.fulfill()
            case .error(_):
                XCTFail()
                updateE.fulfill()
            }
        }
        expect()

        let readE = expectation(description:"updateDoc")

        try? bucket.get(key:docKey) { result in
            switch result {
            case let .success(doc, _):
                if let result = (doc as? String) {
                    XCTAssert(result == "Back!Holla ")
                    readE.fulfill()
                } else {
                    XCTFail()
                }
            case let .error(msg):
                XCTFail(msg)
                readE.fulfill()
            }
        }

        expect()

        deleteRecord(key: docKey)
    }

    func testReplaceFailsWhenNoDocumentExists() {
        let replaceE = expectation(description:"replace")

        let data = ["name": "greg", "age": arc4random()] as [String : Any]
        try? bucket.replace(key:docKey, value:data) { result in
            switch result {
            case .success(_, _):
                XCTFail("This should not succeed when the document did not already exist")
            case let .error(msg):
                XCTAssertNotNil(msg)
                replaceE.fulfill()
            }
        }
        expect()
    }

    func testReplaceWorks() {

        let docKey = "replaceDoc"
        deleteRecord(key:docKey)
        var cas: UInt64 = 0
        let createE = expectation(description: "CreateDoc")
        var data = ["name": "greg", "age": arc4random()] as [String : Any]

        let opts = StoreOptions(persistTo: 0, replicateTo: 0, expiry: 0, cas: 0)
        try? bucket.insert(key: docKey, value: data, options: opts) { result in
            switch result {
            case let .success(_, newCas):
                cas = newCas
                createE.fulfill()
            case .error(_):
                XCTFail()
                createE.fulfill()
            }
        }
        expect()

        let replaceE = expectation(description:"replace")
        data["age"] = 0
        try? bucket.replace(key:docKey, value:data) { result in
            switch result {
            case let .success(_, newCas):
                XCTAssert(cas != newCas)
                replaceE.fulfill()
            case let .error(msg):
                XCTFail(msg)
                replaceE.fulfill()
            }
        }
        expect()

        deleteRecord(key:docKey)
    }

    func testTouchUpdatesDocumentExpiry() {
        _ = createRecord()
        let touchE = expectation(description:"touch")
        //give it the kiss of expiration.
        try? bucket.touch(key:docKey, expiry:1) { result in
            switch result {
            case .success(_):
                touchE.fulfill()
            case let .error(msg):
                XCTFail(msg)
            }
        }
        expect()
    }

    func testCounterWorks() {
        let docId = "counterDoc"
        deleteRecord(key:docId)
        let counterE = expectation(description:"counter")
        try? bucket.counter(key:docId, delta:1, initial:33) { result in
            switch result {
            case let .success(value, cas):
                if let counter = (value as? UInt64) {
                    XCTAssert(counter == 33)
                    XCTAssert(cas != 0)
                    counterE.fulfill()
                } else {
                    XCTFail("Invalid values from server response")
                }
            case let .error(msg):
                XCTFail(msg)
            }
        }
        expect()
        
        deleteRecord(key:docId)

    }
    
    func testGetAndLockWorks() {
        var ocas = createRecord()
        let lockE = expectation(description:"getandlock")
        try? bucket.getAndLock(key: docKey, lockTime:25) { result in
            switch result {
            case let .success(_, cas):
                XCTAssert(ocas != cas) //cas should change if we lock.
                print("cas is:\(cas)")
                ocas = cas
                lockE.fulfill()
            case let .error(msg):
                XCTFail(msg)
            }
        }
        expect()
        //Now try and update it without specifying a cas
        let updateE = expectation(description: "update")
        let ddata = ["name": "gregish", "age": arc4random()] as [String : Any]
        try? bucket.upsert(key: docKey, value: ddata) { result in
            switch result {
            case .success(_):
                XCTFail("Shouldn't be able to modify the document without a CAS")
            case let .error(msg):
                print("upsert failed with:\(msg)")
                updateE.fulfill()
            }
        }
        expect()
        
        //Now update with cas
        let update2E = expectation(description: "update2")
        let opts = StoreOptions(persistTo: 0, replicateTo: 0, expiry: 0, cas: ocas)
        try? bucket.upsert(key: docKey, value: ddata, options: opts) { result in
            switch result {
            case let .success(_, cas):
                XCTAssert(ocas != cas)
                update2E.fulfill()
            case let .error(msg):
                XCTFail(msg)
            }
        }
        expect()
        deleteRecord()
    }
    
    func testGetAndTouchWorks() {
        _ = createRecord()
        let touchE = expectation(description:"touchE")
        //get it and set it to expire immediately
        try? bucket.getAndTouch(key: docKey, expiry: 1) { result in
            switch result {
            case .success(_):
                touchE.fulfill()
            case let .error(msg):
                XCTFail(msg)
            }
        }
        expect()
        
        //Give it some time to expire the document
        var expired = false
        for _ in 1...10 {
            if expired {
                break
            }
            let touchE = expectation(description:"touchE")
            try? bucket.get(key: docKey) { result in
                switch result {
                case .success(_):
                    touchE.fulfill()
                case .error(_):
                    expired = true
                    touchE.fulfill()
                }
            }
            expect()
            sleep(1)
        }
        XCTAssertTrue(expired)
    }

// - MARK: HELPERS
    func createRecord(key: String? = nil, data: [String:Any]? = nil) -> UInt64 {
        let ddata = data ?? ["name": "greg", "age": arc4random()] as [String : Any]
        let dKey = key ?? docKey
        let createE = expectation(description: "CreateDoc")

        var outCas: UInt64 = 0

        let opts = StoreOptions(persistTo: 0, replicateTo: 0, expiry: 0, cas: 0)
        try? bucket.insert(key: dKey, value: ddata, options: opts) { result in
            switch result {
            case let .success(_, cas):
                outCas = cas
                createE.fulfill()
            case .error(_):
                XCTFail()
            }
        }
        expect()

        return outCas
    }

    func deleteRecord(key: String? = nil) {
        let documentKey = key ?? docKey
        let deleteE = expectation(description: "RemoveDoc")
        try? bucket.remove(key: documentKey) { result in
            switch result {
            case .success(_):
                break
            default:
                break
            }
            deleteE.fulfill()
        }
        expect()
    }

    func expect() {
        waitForExpectations(timeout: 3) { error in
            if let error = error {
                XCTFail(error.localizedDescription)
            }

        }
    }

}
