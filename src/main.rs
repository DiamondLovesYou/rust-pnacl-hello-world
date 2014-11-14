#![crate_name = "pnacl-hello-world"]
#![crate_type = "bin"]
#![no_main]

extern crate ppapi;

use std::collections::HashMap;

#[no_mangle]
// Called when an instance is created.
// This is called from a new task. It is perfectly "safe" to panic!() here, or in
// any callback (though it will result in instance termination).
pub extern fn ppapi_instance_created(_instance: ppapi::Instance,
                                     _args: HashMap<String, String>) {
    println!("Hello, world!");
}

#[no_mangle]
pub extern fn ppapi_instance_destroyed() {
}
