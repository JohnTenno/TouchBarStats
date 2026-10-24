import Foundation

/// Reads Apple Silicon thermal sensors through IOHIDEventSystemClient (private IOKit API, no sudo needed).
final class HIDTemperatureSensors: SensorSource {
    private typealias CreateClient = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
    private typealias SetMatching = @convention(c) (AnyObject, CFDictionary) -> Int32
    private typealias CopyServices = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
    private typealias CopyProperty = @convention(c) (AnyObject, CFString) -> Unmanaged<AnyObject>?
    private typealias CopyEvent = @convention(c) (AnyObject, Int64, Int32, Int64) -> Unmanaged<AnyObject>?
    private typealias FloatValue = @convention(c) (AnyObject, Int32) -> Double

    private static let iokitPath = "/System/Library/Frameworks/IOKit.framework/IOKit"
    private static let temperatureEventType: Int64 = 15
    private static let temperatureField: Int32 = 15 << 16
    private static let matching = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5] as CFDictionary

    private let library: DynamicLibrary
    private let client: AnyObject
    private let copyServices: CopyServices
    private let copyProperty: CopyProperty
    private let copyEvent: CopyEvent
    private let floatValue: FloatValue

    init?() {
        guard let library = DynamicLibrary(path: Self.iokitPath),
              let create = library.function(named: "IOHIDEventSystemClientCreate", as: CreateClient.self),
              let setMatching = library.function(named: "IOHIDEventSystemClientSetMatching", as: SetMatching.self),
              let copyServices = library.function(named: "IOHIDEventSystemClientCopyServices", as: CopyServices.self),
              let copyProperty = library.function(named: "IOHIDServiceClientCopyProperty", as: CopyProperty.self),
              let copyEvent = library.function(named: "IOHIDServiceClientCopyEvent", as: CopyEvent.self),
              let floatValue = library.function(named: "IOHIDEventGetFloatValue", as: FloatValue.self),
              let client = create(kCFAllocatorDefault)?.takeRetainedValue()
        else { return nil }

        _ = setMatching(client, Self.matching)
        self.library = library
        self.client = client
        self.copyServices = copyServices
        self.copyProperty = copyProperty
        self.copyEvent = copyEvent
        self.floatValue = floatValue
    }

    func read() -> [SensorReading] {
        guard let services = copyServices(client)?.takeRetainedValue() as? [AnyObject] else { return [] }
        return services.compactMap(reading(from:))
    }

    private func reading(from service: AnyObject) -> SensorReading? {
        guard let name = copyProperty(service, "Product" as CFString)?.takeRetainedValue() as? String,
              let event = copyEvent(service, Self.temperatureEventType, 0, 0)?.takeRetainedValue()
        else { return nil }
        return SensorReading(name: name, celsius: floatValue(event, Self.temperatureField))
    }
}
