# PNaCl says Hi with Rust

A simple PNaCl app (in Rust!) that prints "Hello, world!" on the browser's developer console.

# Taste Testing

* *Sorry, but this is currently linux only (maybe MacOS too, but your mileage will likely vary).*

## Ingredients and Prep

* [Pepper SDK](https://developer.chrome.com/native-client/sdk/download)
  * Install ```pepper_39``` or above from the NaCl SDK.
* [The PNaCl Rust fork](https://github.com/DiamondLovesYou/rust)
  * Configure with (*must be out-of-tree*): ```path/to/rust/configure --target=le32-unknown-nacl --nacl-cross-path=path/to/pepper```
* Build Rust (Nightlies comming Soon(TM)):
  * ```$ make -j 4```
* Install:
  * ```$ sudo make install```

## Cooking and Serving

* Run ```make NACL_SDK_ROOT=path/to/pepper serve``` in a cloned copy of this repo.

After its finished building, it'll open a new tab in Chrome!

### Note:

The build will take longer than what the amount of source would otherwise indicate. This is normal, even for debug builds, and is a result of the way the PNaCl IR legalization works (it's basically LTO).
