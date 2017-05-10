import Foundation
import libcouchbase

// Nothing in this file should live longer than it takes me to get actual tests setup
/// TODO:

let connstr = "couchbase://localhost,127.0.0.1/default"

var d = ["name":"greg", "age":arc4random()] as [String : Any]

guard let cluster = try? Cluster(connectionString:connstr) else {
    print("failed to initialize cluster")
    exit(1)
}
var dirty = DispatchSemaphore(value:0)

let newkey = "key-\(UUID().uuidString)"

guard let bucket = try? cluster.openBucket(name:"default") else {
    print("Unable to open bucket")
    exit(1)
}
print("Current libcouchbase version is:\(bucket.lcbVersion)")

guard let query = try? N1QLQuery(statement: "select name,age from default where name=$1",params:["greg"],namedParams:["dit":"to edit"], consistency:.None) else {
    print("Invalid query parameters")
    exit(1)
}

print(query.query())

do {
    for i in 1...5000 {
    try bucket.n1qlQuery(query: query) { result in
        switch result {
        case let .Success(meta,rows):
            //print(meta!)
            print(rows)
            break;
        case let .Error(msg):
            print("Error:\(msg)")
        }
        dirty.signal()
    }
    }
} catch let error {
    print("Error: \(error)")
    dirty.signal()
}
    
let _ = dirty.wait(timeout:DispatchTime.now() + .seconds(5))

do{
    print("The inserted key was:\(newkey)")
    let opts = StoreOptions(persistTo: 1, replicateTo: 0, expiry: 0, cas: 0)
    try bucket.insert(key: newkey, value: d, options: opts) { result in
        switch result {
        case let .Success(cas):
            print(cas)
        case let .Error(msg):
            print("Error:\(msg)")
        }
        dirty.signal()
    }
    
} catch let error {
    print("Error: \(error)")
    dirty.signal()
}
let _ = dirty.wait(timeout:DispatchTime.now() + .seconds(3))

do {
    try bucket.get(key:newkey) { result in
        switch result {
        case let .Success(value,cas):
            print("value:\(value!)")
            print("cas:\(cas)")
           
        case let .Error(msg):
            print("WRONG!--: \(msg)")
        }
         dirty.signal()
    }
}
catch let error {
    print("Error: \(error)")
    dirty.signal()
}
let _ = dirty.wait(timeout:DispatchTime.now() + .seconds(3))

do {
    try bucket.remove(key: newkey) { result in
        switch result {
        case let .Success(value,cas):
            print(cas)
        default:
            break
        }
        dirty.signal()
    }
}catch let error {
    print("Error: \(error)")
    dirty.signal()
}
let _ = dirty.wait(timeout:DispatchTime.now() + .seconds(3))


do {
    let bucket = try cluster.openBucket(name: "default")
    let keys = ["key-3634F97F-21B7-4391-B552-FDF1BE2B3BCA","key-0A13F1BD-425D-437F-9E4F-2147AF2CCA0D"]
    bucket.getMulti(keys: keys) { result in
        switch result {
        case let .Error(msg):
            print(msg)
        case let .Success(errCount, results):
            print("errorCount:\(errCount)")
            print("results:\(results)")
        }
    }
} catch {
    print("Error: \(error)")
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 45))

print("\n--Exit Program")


