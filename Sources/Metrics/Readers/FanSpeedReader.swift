/// Reads the fans from the SMC (keys FNum, F<n>Ac, F<n>Mn, F<n>Mx) and reports the fastest one.
final class FanSpeedReader {
    private let smc: SMCConnection?

    init(smc: SMCConnection?) {
        self.smc = smc
    }

    func read() -> FanReading? {
        guard let smc, let count = smc.readNumber("FNum"), count > 0 else { return nil }
        let fans = (0..<Int(count)).compactMap { index -> FanReading? in
            guard let rpm = smc.readNumber("F\(index)Ac") else { return nil }
            return FanReading(rpm: rpm, maximumRPM: smc.readNumber("F\(index)Mx") ?? 0,
                              minimumRPM: smc.readNumber("F\(index)Mn") ?? 0)
        }
        return fans.max { $0.rpm < $1.rpm }
    }
}
