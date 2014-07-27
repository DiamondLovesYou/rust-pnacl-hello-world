#![crate_name = "pnacl-hello-world"]
#![crate_type = "bin"]
#![no_main]

extern crate ppapi;

use std::collections::hashmap::HashMap;

#[no_mangle]
#[cfg(target_os = "nacl")]
// Called when an instance is created. Return a boxed trait for your callbacks.
pub extern fn ppapi_instance_created(_instance: ppapi::Instance,
                                     _args: || -> HashMap<String, String>) -> Box<ppapi::InstanceCallbacks> {
    println!("Hello, world!");
    box NoOpt as Box<ppapi::InstanceCallbacks>
}

struct NoOpt;
impl ppapi::InstanceCallbacks for NoOpt { }
