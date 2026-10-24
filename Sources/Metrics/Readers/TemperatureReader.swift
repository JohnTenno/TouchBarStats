/// Summarizes raw readings: CPU = average of the cores, GPU = hottest sensor.
final class TemperatureReader {
    private static let validRange = 1.0...150.0
    private static let cpuPrefixes = ["pACC MTR", "eACC MTR"]
    private static let cpuFallbackPrefixes = ["PMU tdie"]
    private static let gpuPrefixes = ["GPU MTR"]

    private let source: SensorSource?

    init(source: SensorSource?) {
        self.source = source
    }

    func read() -> ThermalReading {
        let readings = (source?.read() ?? []).filter { Self.validRange.contains($0.celsius) }
        let cpuValues = Self.values(in: readings, prefixes: Self.cpuPrefixes)
        let cpu = cpuValues.isEmpty ? Self.values(in: readings, prefixes: Self.cpuFallbackPrefixes) : cpuValues
        let gpu = Self.values(in: readings, prefixes: Self.gpuPrefixes)
        return ThermalReading(cpu: Self.average(cpu), gpu: gpu.max())
    }

    private static func values(in readings: [SensorReading], prefixes: [String]) -> [Double] {
        readings.filter { reading in prefixes.contains { reading.name.hasPrefix($0) } }.map(\.celsius)
    }

    private static func average(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}
