import Foundation

/// Runs every fan at maximum for a while and guarantees handing them back to automatic.
final class FanBoostSession {
    private let controller: FanController
    private let duration: Int
    private let cooldownReport: Int

    init(controller: FanController, duration: Int, cooldownReport: Int) {
        self.controller = controller
        self.duration = duration
        self.cooldownReport = cooldownReport
    }

    func run() -> Bool {
        let fans = Array(0..<controller.fanCount)
        guard !fans.isEmpty else {
            print("No fans found.")
            return false
        }
        defer { restore(fans) }

        for fan in fans {
            let maximum = controller.maximumRPM(fan: fan) ?? 0
            guard maximum > 0, controller.setManual(fan: fan, rpm: maximum) else {
                print("The SMC rejected manual mode for fan \(fan).")
                return false
            }
            print("Fan \(fan) → maximum (\(Int(maximum)) rpm) for \(duration) s")
        }
        report(fans, seconds: duration)
        return true
    }

    func restore(_ fans: [Int]) {
        for fan in fans {
            let restored = controller.restoreAutomatic(fan: fan)
            print("Fan \(fan) → automatic \(restored ? "✓" : "✗ (check with Macs Fan Control or reboot)")")
        }
        report(fans, seconds: cooldownReport)
    }

    private func report(_ fans: [Int], seconds: Int) {
        for second in 1...seconds {
            Thread.sleep(forTimeInterval: 1)
            let speeds = fans.map { "\(Int(controller.currentRPM(fan: $0) ?? 0)) rpm" }.joined(separator: ", ")
            print("  \(second) s: \(speeds)")
        }
    }
}
