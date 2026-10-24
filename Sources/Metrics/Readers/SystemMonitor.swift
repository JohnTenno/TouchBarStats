import Foundation

/// Observer pattern subject: takes a periodic sample and hands it to the observers.
final class SystemMonitor {
    private let cpuReader: CPUUsageReader
    private let gpuReader: GPUUsageReader
    private let memoryReader: MemoryUsageReader
    private let temperatureReader: TemperatureReader
    private let fanReader: FanSpeedReader
    private var interval: TimeInterval
    private var observers: [SnapshotObserver] = []
    private var timer: Timer?

    init(cpuReader: CPUUsageReader, gpuReader: GPUUsageReader, memoryReader: MemoryUsageReader,
         temperatureReader: TemperatureReader, fanReader: FanSpeedReader, interval: TimeInterval) {
        self.cpuReader = cpuReader
        self.gpuReader = gpuReader
        self.memoryReader = memoryReader
        self.temperatureReader = temperatureReader
        self.fanReader = fanReader
        self.interval = interval
    }

    func add(_ observer: SnapshotObserver) {
        observers.append(observer)
    }

    deinit { timer?.invalidate() }

    func start() {
        guard timer == nil else { return }
        capture()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.capture()
        }
        timer?.tolerance = min(interval * 0.1, 0.1)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Changes the sampling interval; if already running, restarts the timer.
    func setInterval(_ value: TimeInterval) {
        guard value != interval else { return }
        interval = value
        guard timer != nil else { return }
        stop()
        start()
    }

    private func capture() {
        let snapshot = SystemSnapshot(cpuUsage: cpuReader.read(),
                                      gpuUsage: gpuReader.read(),
                                      memory: memoryReader.read(),
                                      thermal: temperatureReader.read(),
                                      fan: fanReader.read())
        observers.forEach { $0.monitorDidCapture(snapshot) }
    }
}
