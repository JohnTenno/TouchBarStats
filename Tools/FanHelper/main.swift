import Darwin

// Composition root of the root helper (LaunchDaemon) that controls the fans for the app.
guard getuid() == 0 else {
    fputs("FanHelper needs root: install it with Tools/FanHelper/install.sh\n", stderr)
    exit(1)
}
guard let smc = SMCConnection() else {
    fputs("FanHelper: could not open the SMC\n", stderr)
    exit(1)
}

let controller = FanController(smc: smc)
_ = controller.restoreAutomatic()

// If launchd stops the helper, the fans must not stay in manual.
for signalNumber in [SIGINT, SIGTERM] {
    signal(signalNumber) { _ in
        if let smc = SMCConnection() { _ = FanController(smc: smc).restoreAutomatic() }
        exit(0)
    }
}
signal(SIGPIPE, SIG_IGN)

FanHelperServer(controller: controller).run()
