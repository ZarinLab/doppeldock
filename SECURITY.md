# Security policy

## Supported versions

Only the latest release of DoppelDock gets fixes. To update, run the install
line from the README again.

## Reporting a problem

Please **don't** open a public issue for a security problem. Report it
privately through
[Security › Report a vulnerability](https://github.com/ZarinLab/doppeldock/security/advisories/new).

Include what you found, how to reproduce it, and which macOS and app versions
you used. You can expect a first reply within a week. Once a fix is released,
the report is published with credit to you, unless you'd rather stay anonymous.

## What counts

Examples of what we want to hear about:

- DoppelDock deleting, overwriting or exposing data it shouldn't (another app,
  the original app, a profile's data, files outside its own folders).
- Ways a crafted app, profile name or setting could run commands or change
  files.
- Problems in the install line or in how profiles rebuild themselves.

By design, and documented in the README and `docs/details.md`: an own icon copy
is signed on your Mac instead of by the app's maker, and accepts code libraries
not signed by the maker. Reports that only restate this are not
vulnerabilities, but ideas to reduce it are welcome as issues.
