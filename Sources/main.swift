import Foundation
import libcouchbase

// Nothing in this file should live longer than it takes me to get actual tests setup
/// TODO:

var d = [["name":"greg"], ["age": arc4random()]]

let cluster = Cluster()
var dirty = DispatchSemaphore(value:0)

let newkey = "key-\(UUID().uuidString)"

guard let bucket = try? cluster.openBucket(name:"default") else {
    print("Unable to open bucket")
    exit(1)
}
print("Current libcouchbase version is:\(bucket.lcbVersion)")
do{
    print("The inserted key was:\(newkey)")
    try bucket.insert(key: newkey, value: d) { result in
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
    try bucket.remove(key: newkey, options: nil) { result in
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


