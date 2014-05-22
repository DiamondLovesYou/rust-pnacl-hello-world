# PNaCl says Hi with Rust

A simple PNaCl app (in Rust!) that prints "Hello, world!" as an error on the browser's developer console.

# Taste Testing

* *Sorry, but this is currently linux only (maybe MacOS too, but your mileage will likely vary).*

## Ingredients and Prep

* [The PNaCl Rust fork](https://github.com/DiamondLovesYou/rust)
  * Configure with: ```path/to/rust/configure --target=le32-unknown-nacl --nacl-cross-path=path/to/pepper_canary``` (note [Pepper 34](https://code.google.com/p/chromium/issues/detail?id=343594) and previous have a bug that prevents use of pnacl-translate).
* [Pepper SDK](https://developer.chrome.com/native-client/sdk/download)
  * I recommend installing the ```pepper_canary``` version of pepper.

### Prep

```bash
git submodule update --init
```

## Cooking and Serving

* Run ```make SYSROOT=path/to/rust/build NACL_SDK=path/to/pepper serve```

### Note:

1. You will see a number of warnings. This is normal, and is being worked on.
2. The build will take longer than what the amount of source would otherwise indicate. This is also normal, and is also being worked on.
