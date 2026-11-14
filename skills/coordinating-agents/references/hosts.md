# Host notes

Read this when running the channel scripts on Windows, or to check which platforms the Docker command was tested on.

## Windows

Docker Desktop in **Linux-container mode** (Windows-container mode cannot run BusyBox: report that as the blocker). The source is a Windows path, for example `source=C:\Users\me\repo\.git\coordination\review-gap`. The scripts need LF line endings (`.gitattributes` pins them; re-normalise an older checkout): a CRLF script fails with `set: illegal option -`.

## Tested platforms

Tested on macOS Docker Desktop (arm64 and emulated amd64); not exercised on native Windows, PowerShell or a Linux host.
