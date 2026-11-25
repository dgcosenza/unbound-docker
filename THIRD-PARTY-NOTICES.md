# Third-party notices

This image compiles and packages the following upstream open-source components.
The MIT license in `LICENSE` applies only to the container packaging, scripts,
CI workflow, and documentation maintained by Daniel G. Cosenza from FNX Labs.

| Component | Version | License | Source |
|---|---|---|---|
| NLnet Labs Unbound | 1.26.2 | BSD-3-Clause | https://nlnetlabs.nl/projects/unbound/about/ |
| NLnet Labs ldns (`drill`) | 1.9.2 | BSD-3-Clause | https://nlnetlabs.nl/projects/ldns/about/ |
| IANA Root Hints (`named.root`) | fetched at build time | Public Domain | https://www.internic.net/domain/named.root |
| Debian 13 runtime libraries | trixie | Debian Free Software Guidelines (DFSG) | https://www.debian.org/ |

Notes:

* Unbound and ldns are licensed under the 3-Clause BSD License, which permits
  compilation and redistribution in source and binary forms provided copyright
  and license notices are retained. Upstream `LICENSE` files are preserved under
  `/usr/share/doc/unbound-notices/`.
* Both source tarballs are downloaded directly from NLnet Labs over HTTPS and
  verified against their official SHA-256 digests before compilation.
* Unbound and ldns are trademarks/projects of NLnet Labs. This image is an
  independent build and is not endorsed by or affiliated with NLnet Labs.
