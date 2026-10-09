// AK650 clock sync, derived from AJAZZ AK650 driver Beta 1.0.0.0.
// macOS / IOKit. Build: swiftc ak650-clock.swift -o ak650-clock
import Foundation
import IOKit.hid

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8)); exit(1)
}
func hex(_ bytes: [UInt8]) -> String { bytes.map { String(format: "%02x", $0) }.joined(separator: " ") }
let args = Array(CommandLine.arguments.dropFirst())
if args.contains("--help") {
    print("Usage: ak650-clock [--dry-run] [--timezone Asia/Jakarta]\nSyncs the attached USB AK650 clock to the current time. Default timezone: Asia/Jakarta.")
    exit(0)
}
var zoneName = "Asia/Jakarta"
var dryRun = false
var index = 0
while index < args.count {
    switch args[index] {
    case "--dry-run": dryRun = true
    case "--timezone":
        index += 1
        guard index < args.count else { fail("--timezone needs a timezone name") }
        zoneName = args[index]
    default: fail("Unknown argument: \(args[index])")
    }
    index += 1
}
guard let zone = TimeZone(identifier: zoneName) else { fail("Unknown timezone: \(zoneName)") }
var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone
func reports(at date: Date) -> [(String, [UInt8])] {
    let c = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second,.weekday], from: date)
    guard let year=c.year, (2000...2099).contains(year) else { fail("Supported years: 2000–2099") }
    var start = [UInt8](repeating: 0, count: 64)
    start[0]=4; start[1]=0x18
    var preamble = [UInt8](repeating: 0, count: 64)
    preamble[0]=4; preamble[1]=0x28; preamble[8]=1
    var data = [UInt8](repeating: 0, count: 64)
    data[1]=1; data[2]=0x5a; data[3]=UInt8(year % 2000)
    data[4]=UInt8(c.month!); data[5]=UInt8(c.day!)
    data[6]=UInt8(c.hour!); data[7]=UInt8(c.minute!); data[8]=UInt8(c.second!)
    data[10]=UInt8(c.weekday!-1); data[62]=0xaa; data[63]=0x55
    var save = [UInt8](repeating: 0, count: 64)
    save[0]=4; save[1]=2
    return [("START", start),("PREAMBLE", preamble),("CLOCK", data),("SAVE", save)]
}
let formatter = DateFormatter(); formatter.timeZone=zone; formatter.dateFormat="yyyy-MM-dd HH:mm:ss zzz"
if dryRun {
    let date=Date(); print("Target: \(formatter.string(from: date))")
    for (label, bytes) in reports(at: date) { print("\(label): \(hex(bytes))") }
    exit(0)
}
let manager=IOHIDManagerCreate(kCFAllocatorDefault, 0)
IOHIDManagerSetDeviceMatching(manager, [kIOHIDVendorIDKey:0x05ac, kIOHIDProductIDKey:0x024f] as CFDictionary)
// Enumerate without opening the standard keyboard collections.
let devices=IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
let controls=devices.filter {
    (IOHIDDeviceGetProperty($0,kIOHIDPrimaryUsagePageKey as CFString) as? Int)==0xff13 &&
    (IOHIDDeviceGetProperty($0,kIOHIDProductKey as CFString) as? String)=="AK650"
}
guard controls.count==1, let device=controls.first else { fail("Expected one USB AK650 control interface (05ac:024f / ff13); found \(controls.count).") }
let opened=IOHIDDeviceOpen(device,0)
guard opened==kIOReturnSuccess else { fail(String(format:"Cannot open AK650 control interface: 0x%08x",opened)) }
defer { IOHIDDeviceClose(device,0) }
let date=Date(); print("Target: \(formatter.string(from: date))")
var acknowledgements=0
var clockEcho=false
for (label, bytes) in reports(at: date) {
    let result=bytes.withUnsafeBufferPointer { IOHIDDeviceSetReport(device,kIOHIDReportTypeFeature,0,$0.baseAddress!,bytes.count) }
    guard result==kIOReturnSuccess else { fail(String(format:"%@ write failed: 0x%08x",label,result)) }
    print("\(label) sent: \(hex(bytes))")
    Thread.sleep(forTimeInterval:0.05)
    var reply=[UInt8](repeating:0,count:64); var count=reply.count
    let read=IOHIDDeviceGetReport(device,kIOHIDReportTypeFeature,0,&reply,&count)
    guard read==kIOReturnSuccess else { fail(String(format:"%@ readback failed: 0x%08x",label,read)) }
    print("\(label) reply: \(hex(Array(reply.prefix(count))))")
    // Control replies have a status at offset 3. CLOCK echoes the data, so
    // offset 3 remains the year rather than becoming a status byte.
    if label == "CLOCK" {
        clockEcho = count == 64 && reply == bytes
        guard clockEcho else { fail("Unexpected clock data readback; stopping.") }
    } else {
        guard count == 64, reply[0] == bytes[0], reply[1] == bytes[1], reply[3] == 1 else {
            fail("\(label): missing control acknowledgement; stopping.")
        }
        acknowledgements += 1
    }
}
Thread.sleep(forTimeInterval:0.1)
print("Clock sequence complete: \(acknowledgements)/3 control acknowledgements; clock payload echoed: \(clockEcho). Check the keyboard screen for visual confirmation.")
