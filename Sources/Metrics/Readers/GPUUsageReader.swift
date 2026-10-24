import IOKit
import Foundation

/// GPU usage (0…1) from the "Device Utilization %" the driver publishes in the IORegistry.
final class GPUUsageReader {
    private static let statisticsKey = "PerformanceStatistics"
    private static let utilizationKey = "Device Utilization %"

    func read() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator)
                == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        var highest: Double?
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            if let percent = utilization(of: entry) {
                highest = max(highest ?? 0, percent)
            }
        }
        return highest.map { min($0, 100) / 100 }
    }

    private func utilization(of entry: io_registry_entry_t) -> Double? {
        guard let stats = IORegistryEntryCreateCFProperty(entry, Self.statisticsKey as CFString, nil, 0)?
                .takeRetainedValue() as? [String: Any],
              let value = stats[Self.utilizationKey] as? NSNumber
        else { return nil }
        return value.doubleValue
    }
}
