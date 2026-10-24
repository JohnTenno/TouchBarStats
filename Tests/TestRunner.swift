import Foundation

/// Tiny test runner without XCTest (which requires full Xcode).
final class TestRunner {
    private var failures = 0
    private var checks = 0

    func check(_ condition: Bool, _ message: String, line: Int = #line) {
        checks += 1
        if !condition {
            failures += 1
            print("FAIL (line \(line)): \(message)")
        }
    }

    func finish() -> Never {
        print(failures == 0 ? "OK: \(checks) checks" : "\(failures) of \(checks) checks failed")
        exit(failures == 0 ? 0 : 1)
    }
}
