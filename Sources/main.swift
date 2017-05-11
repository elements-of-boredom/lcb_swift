import Foundation
import libcouchbase

// Nothing in this file should live longer than it takes me to get actual tests setup
/// TODO:

let connstr = "couchbase://localhost,127.0.0.1/default"
guard let cluster = try? Cluster(connectionString:connstr) else {
    print("failed to initialize cluster")
    exit(1)
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 45))

print("\n--Exit Program")
