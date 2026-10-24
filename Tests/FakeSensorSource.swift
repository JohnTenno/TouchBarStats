/// Test double: returns fixed readings instead of reading the hardware.
final class FakeSensorSource: SensorSource {
    private let readings: [SensorReading]

    init(_ readings: [SensorReading]) {
        self.readings = readings
    }

    func read() -> [SensorReading] {
        readings
    }
}
