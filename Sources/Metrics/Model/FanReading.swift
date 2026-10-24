/// Speed of the fastest fan and its range, in rpm.
struct FanReading {
    let rpm: Double
    let maximumRPM: Double
    let minimumRPM: Double

    init(rpm: Double, maximumRPM: Double, minimumRPM: Double = 0) {
        self.rpm = rpm
        self.maximumRPM = maximumRPM
        self.minimumRPM = minimumRPM
    }

    var fraction: Double {
        maximumRPM > 0 ? rpm / maximumRPM : 0
    }

    /// Position within the minimum–maximum range (0...1); it is the manual slider's scale.
    var rangeFraction: Double {
        guard maximumRPM > minimumRPM else { return 0 }
        return min(max((rpm - minimumRPM) / (maximumRPM - minimumRPM), 0), 1)
    }
}
