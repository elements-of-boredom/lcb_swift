import Foundation
import libcouchbase

var d = [["name":"greg"], ["age": arc4random()]]
var loop = true

let cluster = Cluster()
do{
    let bucket = try cluster.openBucket(name: "default")
    let newkey = "key-\(UUID().uuidString)"
    print("The inserted key was:\(newkey)")
    try bucket.insert(key: newkey, value: d) { result in
        switch result {
        case let .Success(cas):
            print(cas)
            bucket.get(key:newkey) { result in
                switch result {
                case let .Success(value,cas):
                    print("value:\(value!)")
                    print("cas:\(cas)")
                    bucket.remove(key: newkey, options: nil) { result in
                        switch result {
                        case let .Success(value,cas):
                            print(cas)
                        default:
                            break
                        }
                    }
                case let .Error(msg):
                    print("WRONG!--: \(msg)")
                    
                }
            }
        case let .Error(msg):
            print("Error:\(msg)")
        }
    }
    
} catch CouchbaseError.FailedInit(let err) {
    print("Error: \(err)")
}

do {
    let bucket = try cluster.openBucket(name: "default")
    let keys = ["key-01D613A6-30BC-4D1D-849F-1A853A79262E","key-0A13F1BD-425D-437F-9E4F-2147AF2CCA0D"]
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


