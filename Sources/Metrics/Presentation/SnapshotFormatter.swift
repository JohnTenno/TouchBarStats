import Foundation

/// Turns a sample into texts and alert levels for each metric.
final class SnapshotFormatter {
    private static let placeholder = "--"
    private static let bytesPerGigabyte = 1_073_741_824.0

    func format(_ metric: Metric, in snapshot: SystemSnapshot) -> FormattedMetric {
        switch metric {
        case .cpu:
            return percentage(title: "CPU", symbol: "cpu", fraction: snapshot.cpuUsage,
                              elevatedAt: 0.60, criticalAt: 0.85, detail: nil)
        case .gpu:
            return percentage(title: "GPU", symbol: "cpu.fill", fraction: snapshot.gpuUsage,
                              elevatedAt: 0.60, criticalAt: 0.85, detail: nil)
        case .memory:
            return percentage(title: "RAM", symbol: "memorychip", fraction: snapshot.memory?.fraction,
                              elevatedAt: 0.75, criticalAt: 0.90, detail: snapshot.memory.map(Self.gigabytes))
        case .cpuTemperature:
            return temperature(title: "CPU", celsius: snapshot.thermal.cpu)
        case .gpuTemperature:
            return temperature(title: "GPU", celsius: snapshot.thermal.gpu)
        case .fan:
            return fan(snapshot.fan)
        }
    }

    private func percentage(title: String, symbol: String, fraction: Double?,
                            elevatedAt: Double, criticalAt: Double, detail: String?) -> FormattedMetric {
        guard let fraction else { return unavailable(title: title, symbol: symbol) }
        let text = "\(Int((fraction * 100).rounded()))%"
        return FormattedMetric(title: title, symbolName: symbol, shortValue: text,
                               detailValue: "\(title) \(detail ?? text)",
                               level: LoadLevel(value: fraction, elevatedAt: elevatedAt, criticalAt: criticalAt))
    }

    private func temperature(title: String, celsius: Double?) -> FormattedMetric {
        let symbol = "thermometer.medium"
        guard let celsius else { return unavailable(title: title, symbol: symbol) }
        let degrees = Int(celsius.rounded())
        return FormattedMetric(title: title, symbolName: symbol, shortValue: "\(degrees)°",
                               detailValue: "\(title) \(degrees) °C",
                               level: LoadLevel(value: celsius, elevatedAt: 70, criticalAt: 90))
    }

    private func fan(_ reading: FanReading?) -> FormattedMetric {
        let title = "Fan", symbol = "fan"
        guard let reading else { return unavailable(title: title, symbol: symbol) }
        let rpm = Int(reading.rpm.rounded())
        return FormattedMetric(title: title, symbolName: symbol, shortValue: "\(rpm)",
                               detailValue: "\(rpm) rpm",
                               level: LoadLevel(value: reading.fraction, elevatedAt: 0.5, criticalAt: 0.8))
    }

    private func unavailable(title: String, symbol: String) -> FormattedMetric {
        FormattedMetric(title: title, symbolName: symbol, shortValue: Self.placeholder,
                        detailValue: "\(title) \(Self.placeholder)", level: .normal)
    }

    private static func gigabytes(_ memory: MemoryUsage) -> String {
        let used = Double(memory.usedBytes) / bytesPerGigabyte
        let total = Double(memory.totalBytes) / bytesPerGigabyte
        return String(format: "%.1f/%.0f GB", used, total)
    }
}
