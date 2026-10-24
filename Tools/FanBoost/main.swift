import Foundation

// Composition root of FanBoost: fan at maximum for 10 s and back to automatic.
guard getuid() == 0 else {
    print("FanBoost necesita root: sudo ./fan-boost.sh")
    exit(1)
}
guard let smc = SMCConnection() else {
    print("Could not open the SMC.")
    exit(1)
}

let controller = FanController(smc: smc)
let session = FanBoostSession(controller: controller, duration: 10, cooldownReport: 5)

// If cancelled with Ctrl-C, the fan is still returned to automatic.
for signalNumber in [SIGINT, SIGTERM] {
    signal(signalNumber) { _ in
        if let smc = SMCConnection() {
            let controller = FanController(smc: smc)
            for fan in 0..<controller.fanCount { _ = controller.restoreAutomatic(fan: fan) }
        }
        print("\nCancelled: fans on automatic.")
        exit(130)
    }
}

exit(session.run() ? 0 : 1)
