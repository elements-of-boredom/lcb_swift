import Foundation
import libcouchbase

//callbacks
let storage_callback:lcb_store_callback = {
    (instance, cookie, op, err, resp) -> Void in
    let key =  Data(bytes: resp!.pointee.v.v0.key, count: resp!.pointee.v.v0.nkey)
    print("Stored key \(String(data: key, encoding: String.Encoding.utf8)!)")
}

let get_callback:lcb_get_callback = {
    (instance, cookie, err, resp) -> Void in
    let key =  Data(bytes: resp!.pointee.v.v0.key, count: resp!.pointee.v.v0.nkey)
    print("Retreived key \(String(data: key, encoding: String.Encoding.utf8)!)")
    
    let bytes = Data(bytes:resp!.pointee.v.v0.bytes, count:resp!.pointee.v.v0.nbytes)
    print("Value is \(String(data: bytes , encoding: String.Encoding.utf8)!)")
}

let cluster = Cluster()
do{
    let bucket = try cluster.openBucket(name: "default", callback: "blah")
} catch CouchbaseError.FailedInit(let err) {
    print("Error: \(err)")
}


var cropts:lcb_create_st = lcb_create_st()
cropts.version = 3;
cropts.v.v3.connstr = ("couchbase://localhost/default" as NSString).utf8String //NSString is used to interop with C

print(String(cString: cropts.v.v3.connstr)) //Must put parameter name cString

var err:lcb_error_t
var instance:lcb_t?

err = lcb_create( &instance, &cropts )
if ( err != LCB_SUCCESS ) {
    print("Couldn't create instance!")
    exit(1)
}

// connecting
lcb_connect(instance)
lcb_wait(instance)
err = lcb_get_bootstrap_status(instance)
if ( err != LCB_SUCCESS ) {
    print("Couldn't bootstrap!")
    exit(1);
}

// Installing callbacks
lcb_set_store_callback(instance, storage_callback)
lcb_set_get_callback(instance, get_callback)

// Store operation
var scmd:lcb_store_cmd_t = lcb_store_cmd_t()
var scmdlist:UnsafePointer<lcb_store_cmd_t>? = withUnsafePointer(to: &scmd) {
    UnsafePointer<lcb_store_cmd_t>($0)
}
let kkey = "Hello"
scmd.v.v0.key = UnsafeRawPointer((kkey as NSString).utf8String!)
scmd.v.v0.nkey = kkey.characters.count
scmd.v.v0.bytes = UnsafeRawPointer(("Couchbase" as NSString).utf8String!)
scmd.v.v0.nbytes = 9
scmd.v.v0.operation = LCB_SET
err = lcb_store(instance, nil, 1, &scmdlist)
if (err != LCB_SUCCESS) {
    print("Couldn't schedule storage operation! \(err)");
    exit(1);
}
lcb_wait(instance); //storage_callback is invoked here


// Get operation
var gcmd:lcb_get_cmd_t = lcb_get_cmd_t();
var gcmdlist:UnsafePointer<lcb_get_cmd_t>? = withUnsafePointer(to: &gcmd) {
    UnsafePointer<lcb_get_cmd_t>($0)
}
gcmd.v.v0.key = UnsafeRawPointer(("Hello" as NSString).utf8String!)
gcmd.v.v0.nkey = 5;
err = lcb_get(instance, nil, 1, &gcmdlist);
if (err != LCB_SUCCESS) {
    print("Couldn't schedule get operation! \(err)");
    exit(1);
}
lcb_wait(instance); // get_callback is invoked here


//Store and retrieve json doc
var doc:NSString = "{ \"json\" : \"data\" }"
var docKey:NSString = "a_simple_key"
var cmd = lcb_store_cmd_st()
var cmdlist:UnsafePointer<lcb_store_cmd_st>? = withUnsafePointer(to: &cmd) {
    UnsafePointer<lcb_store_cmd_st>($0)
}
cmd.v.v0.key = UnsafeRawPointer(docKey.utf8String!)
cmd.v.v0.nkey = docKey.length
cmd.v.v0.bytes = UnsafeRawPointer(doc.utf8String!)
cmd.v.v0.nbytes = doc.length
cmd.v.v0.operation = LCB_ADD

err = lcb_store(instance, nil, 1, &cmdlist);
if (err == LCB_SUCCESS) {
    lcb_wait(instance)
} else {
    print("Could not store json doc: \(lcb_strerror(instance, err))")
}


gcmd.v.v0.key = UnsafeRawPointer(docKey.utf8String!)
gcmd.v.v0.nkey = docKey.length;
err = lcb_get(instance, nil, 1, &gcmdlist);
if (err != LCB_SUCCESS) {
    print("Couldn't schedule get operation! \(err)");
    exit(1);
}
lcb_wait(instance);

lcb_destroy(instance);


print("\n--Exit Program")


