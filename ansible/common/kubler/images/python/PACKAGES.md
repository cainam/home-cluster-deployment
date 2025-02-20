### ns/python3:20250215

Built: Do 20. Feb 21:49:54 CET 2025
Image Size: 211 MB
211 MB

211 MB

#### Installed
Package | USE Flags
--------|----------
app-alternatives/bzip2-1::gentoo | `reference -lbzip2 -pbzip2 (-split-usr)`
app-arch/bzip2-1.0.8-r5:0/1::gentoo | `-static -static-libs -verify-sig`
app-arch/xz-utils-5.6.3::gentoo | `extra-filters nls -doc -pgo -static-libs -verify-sig`
app-crypt/libb2-0.98.1-r3::gentoo | `openmp -native-cflags -static-libs`
app-misc/ca-certificates-20240203.3.98::gentoo | `-cacert`
app-misc/mime-types-2.1.54::gentoo | `-nginx`
dev-db/sqlite-3.47.2-r1:3::gentoo | `readline -debug -doc -icu -secure-delete -static-libs -tcl -test -tools`
dev-lang/python-3.12.8:3.12::gentoo | `ensurepip readline sqlite ssl -bluetooth -build -debug -examples -gdbm -libedit -ncurses -pgo -test -tk -valgrind -verify-sig`
dev-lang/python-3.13.1:3.13::gentoo | `ensurepip readline sqlite ssl -bluetooth -build -debug -examples -gdbm (-jit) -libedit -ncurses -pgo -test -tk -valgrind -verify-sig`
dev-lang/python-exec-2.4.10:2::gentoo | `(native-symlinks) -test`
dev-lang/python-exec-conf-2.4.6:2::gentoo | ` `
dev-libs/expat-2.6.4::gentoo | `unicode -examples -static-libs -test`
dev-libs/libffi-3.4.6-r3:0/8::gentoo | `-debug -exec-static-trampoline -pax-kernel -static-libs -test`
dev-libs/libpcre2-10.44-r1:0/3::gentoo | `bzip2 jit pcre16 pcre32 readline unicode zlib -libedit -static-libs -valgrind -verify-sig`
dev-libs/mpdecimal-4.0.0:4::gentoo | `-cxx -test`
dev-libs/openssl-3.3.3:0/3::gentoo | `asm quic -fips -ktls -rfc3779 -sctp -static-libs -test -tls-compression -vanilla -verify-sig -weak-ssl-ciphers`
dev-python/cachecontrol-0.14.1::gentoo | `-test`
dev-python/certifi-3024.7.22::gentoo | `-test`
dev-python/charset-normalizer-3.4.1::gentoo | `-test`
dev-python/colorama-0.4.6::gentoo | `-examples -test`
dev-python/distlib-0.3.9::gentoo | `-test`
dev-python/distro-1.9.0::gentoo | `-test`
dev-python/ensurepip-pip-24.3.1::gentoo | ` 0 `
dev-python/gentoo-common-1::gentoo | ` 0 `
dev-python/idna-3.10::gentoo | `-test`
dev-python/jaraco-collections-5.1.0::gentoo | `-test`
dev-python/jaraco-context-6.0.1::gentoo | `-test`
dev-python/jaraco-functools-4.1.0::gentoo | `-test`
dev-python/jaraco-text-4.0.0::gentoo | `-test`
dev-python/linkify-it-py-2.0.3::gentoo | `-test`
dev-python/markdown-it-py-3.0.0::gentoo | `-test`
dev-python/mdurl-0.1.2::gentoo | `-test`
dev-python/more-itertools-10.6.0::gentoo | `-doc -test`
dev-python/msgpack-1.1.0::gentoo | `native-extensions -debug -test`
dev-python/packaging-24.2::gentoo | `-test`
dev-python/pip-24.3.1-r2::gentoo | `(test-rust) -test`
dev-python/platformdirs-4.3.6::gentoo | `-test`
dev-python/pygments-2.19.1::gentoo | `-test`
dev-python/pyproject-hooks-1.2.0::gentoo | `-test`
dev-python/pysocks-1.7.1-r2::gentoo | ` `
dev-python/requests-2.32.3::gentoo | `(test-rust) -socks5 -test`
dev-python/resolvelib-1.1.0::gentoo | `-test`
dev-python/rich-13.9.4::gentoo | `-test`
dev-python/setuptools-75.8.0::gentoo | `-test`
dev-python/setuptools-scm-8.1.0::gentoo | `-test`
dev-python/trove-classifiers-2025.1.15.22::gentoo | `-test`
dev-python/truststore-0.10.0::gentoo | `-test`
dev-python/typing-extensions-4.12.2::gentoo | `-test`
dev-python/uc-micro-py-1.0.3::gentoo | `-test`
dev-python/urllib3-2.3.0::gentoo | `-brotli -http2 -test -zstd`
dev-python/wheel-0.45.1::gentoo | `-test`
sys-apps/util-linux-2.40.2::gentoo | `cramfs hardlink logger readline suid (unicode) -audit -build -caps -cryptsetup -fdformat -kill -magic -ncurses (-nls) -pam -python (-rtas) (-selinux) -slang -static-libs -su (-systemd) -test -tty-helpers -udev -uuidd -verify-sig`
sys-libs/ncurses-6.4_p20240414:0/6::gentoo | `cxx (tinfo) -ada -debug -doc -gpm -minimal -profile (-split-usr) (-stack-realign) -static-libs -test -trace -verify-sig`
sys-libs/readline-8.2_p13-r1:0/8::gentoo | `(unicode) -static-libs -utils -verify-sig`
sys-libs/zlib-1.3.1-r1:0/1::gentoo | `-minizip -static-libs -verify-sig`
#### Inherited
Package | USE Flags
--------|----------
**FROM ns/img1** |
sys-apps/busybox-1.36.1-r3 | `-debug -livecd -make-symlinks -math -mdev -pam -savedconfig (-selinux) -sep-usr -static -syslog (-systemd)`
sys-libs/libxcrypt-4.4.36-r3 | `compat system -headers-only -static-libs -test`
sys-libs/musl-1.2.5-r3 | `-crypt -headers-only (-split-usr) -verify-sig`

#### Purged
- [x] Headers
- [x] Static Libs
