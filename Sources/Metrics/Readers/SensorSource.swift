/// Source of thermal readings; lets tests replace the hardware with a double.
protocol SensorSource {
    func read() -> [SensorReading]
}
