# AK650 clock protocol


Target exactly the `AK650` product with USB VID `0x05ac`, PID `0x024f`, usage page `0xff13`. Open only that vendor control interface without seizing it.

Send 64-byte HID **feature** reports with report ID **0**. The first `04` in control packets is a data byte, not the HID report ID. Windows uses a 65-byte buffer with an extra leading zero report ID; the macOS IOKit call takes the 64-byte payload directly.

All unspecified bytes are zero. Offsets below are zero-based payload offsets.

| Packet | Bytes |
| --- | --- |
| START | `[0]=04`, `[1]=18` |
| PREAMBLE | `[0]=04`, `[1]=28`, `[8]=01` |
| CLOCK | `[0]=00`, `[1]=01`, `[2]=5a`, `[3]=year−2000`, `[4]=month`, `[5]=day`, `[6]=hour`, `[7]=minute`, `[8]=second`, `[9]=00`, `[10]=weekday` (Sunday=0), `[62]=aa`, `[63]=55` |
| SAVE | `[0]=04`, `[1]=02` |

Date/time fields are binary integers, not BCD. `[1]=01` in CLOCK comes from the vendor driver's TFT selection index plus one; this utility follows its first-slot setting. Support for other selections was not tested.

Wait 50 ms after each write, then GET_FEATURE report 0. Control responses echo the command and put `01` at payload offset 3. CLOCK echoes the payload, leaving the year at offset 3. Wait another 100 ms after SAVE.

## Evidence and sources

- [Vendor AK650 driver page](https://ajazzstore.com/blogs/software/ajazz-ak650-driver)
- [Analyzed driver ZIP](https://cdn.shopify.com/s/files/1/0554/6678/6869/files/AJAZZ_AK650_Tri-mode_with_Screen_RGB_version_Keyboard_Driver_V1.0.zip)
- [AK820 configurator reference](https://github.com/craigsdel/ajazz-ak820-config)

The driver `config.xml` matches `05AC:024F` and product name `AK650` exactly. `DeviceDriver.exe` clock function `0x4238f0` constructs the four packets and calls `GetLocalTime`. Wrapper `0x44ec60` inserts the Windows report-ID prefix and copies 64 payload bytes. `0x4511d0` calls `HidD_SetFeature`; the wrapper follows it with GET_FEATURE through `0x451270`.

SHA-256:

- Driver ZIP: `00aff2643d0ec9f8386ac96c2fad6e50fe5ac126fe69e1a8a41eb15887a705e3`
- Analyzed `DeviceDriver.exe`: `e36ec81e164b244073561978399dca7195d897d475d66cf132e8cc2b425f1ff5`

The AK820 tool filters for another USB ID and is not a direct match. Its protocol provides a useful comparison, but the packet layout above comes from the AK650 driver and live replies from this keyboard.
