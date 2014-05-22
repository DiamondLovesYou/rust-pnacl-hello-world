#![crate_id(name = "pnacl-hello-world", vers = "0.0")]
#![crate_type = "bin"]
#![no_main]

extern crate ppapi;
extern crate collections;

use collections::hashmap::HashMap;

#[no_mangle]
#[cfg(target_os = "nacl")]
// Called when an instance is created. Return a boxed trait for your callbacks.
pub extern fn ppapi_instance_created
    (instance: ppapi::Instance,
     _args: || -> HashMap<~str, ~str>) -> Box<ppapi::InstanceCallback> {
        use ppapi::ppb::ConsoleInterface;
        let console = instance.console();
        console.log(ppapi::ffi::PP_LOGLEVEL_LOG, "Hello, world!");
        box NoOpt as Box<ppapi::InstanceCallback>
    }

struct NoOpt;
impl ppapi::InstanceCallback for NoOpt { }
