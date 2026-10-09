# AJAZZ AK650 Clock Sync for macOS

Sync the mini-screen clock on an AJAZZ AK650 / AK650 Pro over USB from macOS, without the Windows driver.

Hardware-tested on a SONiX `AK650` with USB ID **05ac:024f**, device version **1.05**, running macOS on Apple Silicon. The keyboard acknowledged the commands and its owner visually confirmed the correct date and time.

## Quick start

1. Connect the keyboard using a USB data cable and select wired mode.
2. [Download the repository ZIP](https://github.com/geraeldo/ajazz-ak650-clock/archive/refs/heads/main.zip) and extract it.
3. Keep the files together and double-click **Sync-AK650-Clock.command** in Finder.

The included executable is for **Apple Silicon Macs**. The launcher sets the clock to the current time in **Asia/Jakarta (WIB, UTC+7)**.

From Terminal, inside the extracted folder:

```sh
./ak650-clock
./ak650-clock --timezone Europe/London
./ak650-clock --dry-run
```

`--timezone` accepts an IANA timezone name. The default is `Asia/Jakarta`. `--dry-run` prints the packets without accessing the keyboard.

## Build from source

Requires macOS and Xcode Command Line Tools. There are no third-party runtime dependencies.

```sh
swiftc ak650-clock.swift -o ak650-clock
```

Building on an Intel Mac produces an Intel executable; Intel hardware has not been tested.

## Scope and compatibility

The utility targets only product name `AK650`, USB `05ac:024f`, and vendor HID usage page `ff13`. Other keyboard revisions and models have not been tested. The AK820 configurator's device filter does not match this keyboard.

It sends the clock-setting sequence once and exits. It does not install a background service. Feature-report readback confirms the USB exchange; the clock data is echoed rather than independently read from the RTC. Check the screen after syncing.

## Protocol and credits

The packet layout was decoded by static analysis of the matching [AJAZZ AK650 Windows driver](https://ajazzstore.com/blogs/software/ajazz-ak650-driver), then verified on the keyboard on 9 October 2026. See [PROTOCOL.md](PROTOCOL.md) for packet offsets, acknowledgements, driver function addresses, and hashes of the analyzed files.

The [AK820 configurator by craigsdel](https://github.com/craigsdel/ajazz-ak820-config) inspired this investigation and provided a useful protocol comparison. This repository contains the independently written Swift utility and protocol notes; the vendor installer and binaries are not redistributed.

Independent community project, unaffiliated with AJAZZ.
