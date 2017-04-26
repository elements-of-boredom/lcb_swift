import Foundation
import libcouchbase

var d = [["name":"greg"], ["age":34]]
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
                    loop = false
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





print("\n--Exit Program")


