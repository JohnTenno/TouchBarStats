import Foundation

let t = TestRunner()

// CPUTicks
t.check(CPUTicks(busy: 150, total: 300).usage(since: CPUTicks(busy: 100, total: 200)) == 0.5, "50% usage")
t.check(CPUTicks(busy: 100, total: 200).usage(since: CPUTicks(busy: 100, total: 200)) == 0, "no progress = 0")

// TemperatureReader
let mixed = TemperatureReader(source: FakeSensorSource([
    SensorReading(name: "pACC MTR Temp Sensor2", celsius: 50),
    SensorReading(name: "eACC MTR Temp Sensor0", celsius: 40),
    SensorReading(name: "GPU MTR Temp Sensor1", celsius: 30),
    SensorReading(name: "GPU MTR Temp Sensor4", celsius: 55),
    SensorReading(name: "PMU tdev4", celsius: -21),
])).read()
t.check(mixed.cpu == 45, "CPU = average of cores")
t.check(mixed.gpu == 55, "GPU = hottest sensor")

let fallback = TemperatureReader(source: FakeSensorSource([
    SensorReading(name: "PMU tdie1", celsius: 60),
    SensorReading(name: "PMU tdie2", celsius: 70),
])).read()
t.check(fallback.cpu == 65, "uses PMU tdie when there are no core sensors")
t.check(fallback.gpu == nil, "no GPU = nil")
t.check(TemperatureReader(source: nil).read().cpu == nil, "no sensors = nil")

// LoadLevel
t.check(LoadLevel(value: 0.5, elevatedAt: 0.6, criticalAt: 0.85) == .normal, "normal")
t.check(LoadLevel(value: 0.6, elevatedAt: 0.6, criticalAt: 0.85) == .elevated, "elevated at the threshold")
t.check(LoadLevel(value: 0.9, elevatedAt: 0.6, criticalAt: 0.85) == .critical, "critical")

// SnapshotFormatter
let formatter = SnapshotFormatter()
let snapshot = SystemSnapshot(cpuUsage: 0.234,
                              gpuUsage: 0.88,
                              memory: MemoryUsage(usedBytes: 8 * 1_073_741_824, totalBytes: 16 * 1_073_741_824),
                              thermal: ThermalReading(cpu: 92.4, gpu: nil),
                              fan: FanReading(rpm: 6000, maximumRPM: 7200))
let cpu = formatter.format(.cpu, in: snapshot)
t.check(cpu.shortValue == "23%" && cpu.level == .normal, "CPU 23% normal")
let ram = formatter.format(.memory, in: snapshot)
t.check(ram.shortValue == "50%" && ram.detailValue == "RAM 8.0/16 GB", "RAM short and detail: \(ram.detailValue)")
let hot = formatter.format(.cpuTemperature, in: snapshot)
t.check(hot.shortValue == "92°" && hot.detailValue == "CPU 92 °C" && hot.level == .critical, "critical temperature")
t.check(formatter.format(.gpuTemperature, in: snapshot).shortValue == "--", "no data = --")

let fan = formatter.format(.fan, in: snapshot)
t.check(fan.detailValue == "6000 rpm" && fan.level == .critical, "fan at 83% = critical")
let gpu = formatter.format(.gpu, in: snapshot)
t.check(FanReading(rpm: 4200, maximumRPM: 7200, minimumRPM: 1200).rangeFraction == 0.5, "rpm at mid range")
t.check(FanReading(rpm: 900, maximumRPM: 7200, minimumRPM: 1200).rangeFraction == 0, "below minimum = 0")
t.check(gpu.shortValue == "88%" && gpu.detailValue == "GPU 88%" && gpu.level == .critical, "GPU 88% critical")

// SMCKeyData must have the same size as the C struct
t.check(MemoryLayout<SMCKeyData>.stride == 80, "SMCKeyData = 80 bytes")

// FanCommand: what travels over the socket to the helper
t.check(FanCommand(line: "auto") == .automatic, "auto")
t.check(FanCommand(line: "manual 0.42") == .manual(fraction: 0.42), "manual 42%")
t.check(FanCommand(line: "manual 7") == .manual(fraction: 1), "fraction clamped to 1")
t.check(FanCommand(line: "manual nan") == nil && FanCommand(line: "turbo") == nil, "invalid commands")
t.check(FanCommand(line: FanCommand.manual(fraction: 0.3).line) == .manual(fraction: 0.3), "round trip")

// AppSettings: order, visibility and old or partial JSON
var settings = AppSettings.defaults
t.check(settings.visibleItems.first == .cpu && !settings.visibleItems.contains(.media), "defaults without animation")
settings.setVisible(.media, true)
t.check(!settings.visibleItems.contains(.media), "animation without a file is hidden")
settings.media.path = "/tmp/a.gif"
settings.move(.media, by: -100)
t.check(settings.visibleItems.first == .media, "animation moved to the start")
settings.move(.cpu, by: 1)
t.check(Array(settings.visibleItems.prefix(3)) == [.media, .gpu, .cpu], "cpu moves down one place")
let partial = try! JSONDecoder().decode(AppSettings.self, from: Data(#"{"items":[{"item":"claude","isVisible":true},{"item":"turbo","isVisible":true},{"item":"claude","isVisible":false}],"mediaWidth":9999}"#.utf8))
t.check(partial.items.first?.item == .claude && partial.items.count == BarItem.allCases.count, "unknown and duplicate items dropped, missing ones added")
t.check(partial.mediaWidth == AppSettings.mediaWidthRange.upperBound && partial.refreshInterval == 2, "values clamped and defaulted")
let roundTrip = try! JSONDecoder().decode(AppSettings.self, from: try! JSONEncoder().encode(settings))
t.check(roundTrip == settings, "JSON round trip")

// FrameGeometry: GIF frames are pre-rendered at the visible size only
let strip = FrameGeometry(imageSize: CGSize(width: 498, height: 480), targetSize: CGSize(width: 380, height: 60), fit: .fill)
t.check(strip.outputSize == CGSize(width: 380, height: 60), "fill crops to the view size")
t.check(strip.drawRect.width.rounded() == 380 && strip.drawRect.midY == 30, "fill scales to width and centers vertically")
let letterbox = FrameGeometry(imageSize: CGSize(width: 498, height: 480), targetSize: CGSize(width: 380, height: 60), fit: .fit)
t.check(letterbox.outputSize == CGSize(width: 62, height: 60), "fit keeps the whole image inside the view")
let small = FrameGeometry(imageSize: CGSize(width: 100, height: 50), targetSize: CGSize(width: 1200, height: 60), fit: .fill)
t.check(small.outputSize == CGSize(width: 100, height: 5) && small.drawRect.width == 100, "fill never upscales, only crops")
let tiny = FrameGeometry(imageSize: CGSize(width: 64, height: 64), targetSize: CGSize(width: 128, height: 128), fit: .fit)
t.check(tiny.outputSize == CGSize(width: 64, height: 64), "fit never upscales")

t.finish()
