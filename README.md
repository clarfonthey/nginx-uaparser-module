# `nginx-uaparser-module`

Wrapper for [uap-cpp] as an nginx module.

This software can be freely used and modified under the [CC0 1.0 Universal License], although nginx
itself has a more restrictive license.

[uap-cpp]: https://github.com/ua-parser/uap-cpp
[CC0 1.0 Universal License]: LICENSE.md

## Usage

This module will (lazily) parse the user agent for each request for device, OS, and browser
information using [uap-core]. Instead of configuring what YAML file is used for the rules, the
module loads `/usr/share/uap-core/regexes.yaml` every time nginx starts.

The following variables are available, as defined by the uap-core spec:

* `$uap_device_family`
* `$uap_device_model`
* `$uap_device_brand`
* `$uap_os_family`
* `$uap_os_version_major`
* `$uap_os_version_minor`
* `$uap_os_version_patch`
* `$uap_os_version_patch_minor`
* `$uap_browser_family`
* `$uap_browser_version_major`
* `$uap_browser_version_minor`
* `$uap_browser_version_patch`
* `$uap_browser_version_patch_minor`

[uap-core]: https://github.com/ua-parser/uap-core/blob/master/docs/specification.md

## Compatibility

At the time of writing, ahe module will be maintained to ensure compatibility with the latest patch
release of the latest mainline release of nginx, and all stable releases since 1.0. This can be
verified using `make test`.

If nginx changes enough to the point that breaking changes are desired, this will be clearly marked
on a release.

Unfortunately, because uap-cpp does not have a versioning scheme, this module is only guaranteed
to work on the latest commit of uap-cpp.

## Building/testing

This project depends on uap-cpp, which must be installed globally to `/usr/lib/libuaparser_cpp.so`
and `/usr/include/UaParser.h` separately. This project's `Makefile` includes a custom build script
which downloads the relevant source for nginx to build the module, and that step is not required.

The makefile includes a number of options to build and test the project as listed below,
substituting `$VERSION` for the necessary version of nginx.

* `make download-$VERSION`: downloads and extracts nginx source code.
* `make configure-$VERSION`: downloads and configures nginx source for building module.
* `make lint-$VERSION`: attempts to build the module with both Clang and GCC, without linking.
    `lint-gcc-$VERSION` and `lint-clang-$VERSION` are also available if you only want to test one
    or the other.
* `make build-$VERSION`: builds the module and copies it to `nginx-$VERSION-uaparser-module.so`.
    although the actual name of the module will have to be `ngx_http_uaparser_module.so` when
    installed, this naming scheme includes the nginx version as well.
* `make test-$VERSION`: builds nginx with the module included and runs a test suite.

There also exist the following shortcuts:

* `make lint`: runs `make lint-$VERSION` for several versions of nginx. also includes
    `lint-eclint`, which lints according to `.editorconfig`, and `lint-cppcheck`, which lints
    according to `cppcheck`.
* `make quick-lint`: similar to `lint`, but only for the latest mainline and stable release.
* `make build`: runs `make build-$VERSION` for the lastest mainline and stable releases.
* `make test`: runs `make test-$VERSION` for several versions of nginx.
