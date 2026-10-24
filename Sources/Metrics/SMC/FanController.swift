/// Manual fan control via the SMC (F<n>Md = mode, F<n>Tg = target rpm). Requires root.
final class FanController {
    private static let automaticMode = 0.0
    private static let manualMode = 1.0

    private let smc: SMCConnection

    init(smc: SMCConnection) {
        self.smc = smc
    }

    var fanCount: Int {
        Int(smc.readNumber("FNum") ?? 0)
    }

    func currentRPM(fan: Int) -> Double? {
        smc.readNumber("F\(fan)Ac")
    }

    func minimumRPM(fan: Int) -> Double? {
        smc.readNumber("F\(fan)Mn")
    }

    func maximumRPM(fan: Int) -> Double? {
        smc.readNumber("F\(fan)Mx")
    }

    /// Switches the fan to manual mode at the given speed.
    func setManual(fan: Int, rpm: Double) -> Bool {
        smc.writeNumber("F\(fan)Md", Self.manualMode) && smc.writeNumber("F\(fan)Tg", rpm)
    }

    /// Manual mode at a fraction (0...1) of each fan's minimum–maximum range.
    func setManual(fraction: Double) -> Bool {
        (0..<fanCount).allSatisfy { fan in
            guard let maximum = maximumRPM(fan: fan), maximum > 0 else { return false }
            let minimum = min(minimumRPM(fan: fan) ?? 0, maximum)
            return setManual(fan: fan, rpm: minimum + (maximum - minimum) * fraction)
        }
    }

    /// Hands the fan back to macOS automatic control.
    func restoreAutomatic(fan: Int) -> Bool {
        smc.writeNumber("F\(fan)Md", Self.automaticMode)
    }

    func restoreAutomatic() -> Bool {
        (0..<fanCount).map(restoreAutomatic(fan:)).allSatisfy { $0 }
    }
}
