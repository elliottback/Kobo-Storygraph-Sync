This is a static arm32v7 build of curl for the Kobo platform.

Flags set to reduce size.

`docker run --rm -v $(pwd):/tmp -w /tmp --platform=linux/arm64/v7 /tmp/build.sh`

Modified from [static-curl](https://github.com/moparisthebest/static-curl), see [LICENSE](LICENSE).