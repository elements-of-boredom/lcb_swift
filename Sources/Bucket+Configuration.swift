//
//  Bucket+Configuration.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import Foundation
import libcouchbase

extension Bucket {

    // - MARK: Public Members
    public static let clientVersion: String = "0.1"

    /// The amount of time (in microseconds) that the Bucket will wait before
    /// forcing a configuration refresh. If no refresh occurs before this period
    /// while a configuration is marked invalid, an update will be triggered.
    public var configThrottle: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_CONFDELAY_THRESH, &value)
            return value
        }
        set (newValue) {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_CONFDELAY_THRESH, pointer.toOpaque())
        }
    }

    /// Initial bootstrapping timeout.
    /// This is how long the client will wait to obtain the initial configuration
    public var connectionTimeout: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_CONFIGURATION_TIMEOUT, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_CONFIGURATION_TIMEOUT, pointer.toOpaque())
        }
    }

    /// Polling grace interval for lcb_durability_poll()
    /// This is the time the client will wait between repeated probes to a given server
    public var durabilityInterval: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_DURABILITY_INTERVAL, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_DURABILITY_INTERVAL, pointer.toOpaque())
        }
    }

    /// Default timeout for how long the client will spend sending repeated probes to a
    /// given key's vBucket masters and replica's before they are deemed not to have
    /// satisfied durability requirements.
    public var durabilityTimeout: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_DURABILITY_TIMEOUT, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_DURABILITY_TIMEOUT, pointer.toOpaque())
        }
    }

    /// Returns the libcouchbase version as a string.
    public var lcbVersion: String {
        //calls to utf8String cant really fail, we could get bad data though
        return String(utf8String:lcb_get_version(nil))!
    }

    /// The management timeout is the time the bucket will wait for a response
    /// from the server for a management request. (Non-view Http Requests)
    public var managementTimeout: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_HTTP_TIMEOUT, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_HTTP_TIMEOUT, pointer.toOpaque())
        }
    }

    /// N1QL Timeout is the time that a Bucket will wait for a response from the server
    /// for a n1ql request.
    public var n1qlTimeout: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_N1QL_TIMEOUT, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_N1QL_TIMEOUT, pointer.toOpaque())
        }
    }

    /// Per node configuration timeout.
    /// The per-node configuration timeout sets the amount of time to wait for each node within the bootstrap/configuration process.
    /// This interval is a subset of the `connectionTimeout` option mentioned above and is intended to ensure that the bootstrap process
    /// does not wait too long for a given node. Nodes that are physically offline may never respond and it may take a long time until
    /// they are detected as being offline
    public var nodeConnectionTimeout: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_CONFIG_NODE_TIMEOUT, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_CONFIG_NODE_TIMEOUT, pointer.toOpaque())
        }
    }

    /// The operation timeout.
    /// The operation timeout is the maximum amount of time the SDK will wait for an operation to receive
    /// a response before invoking its callback with a failed status.
    /// Operations can timeout if the server is taking to long to respond, or an updated cluster config
    /// has not been received within the `configThrottle` time window.
    public var operationTimeout: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_OP_TIMEOUT, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_OP_TIMEOUT, pointer.toOpaque())
        }
    }

    /// The view timeout.
    /// The view timeout is the maximum amount of time the SDK will wait for HTTP requests of the `view` type
    public var viewTimeout: Int32 {
        get {
            var value: Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_OP_TIMEOUT, &value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_OP_TIMEOUT, pointer.toOpaque())
        }
    }

}
