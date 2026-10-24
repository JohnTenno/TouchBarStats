import Foundation

/// dlopen/dlsym wrapper for functions without public headers.
final class DynamicLibrary {
    private let handle: UnsafeMutableRawPointer

    init?(path: String) {
        guard let handle = dlopen(path, RTLD_NOW) else { return nil }
        self.handle = handle
    }

    deinit {
        dlclose(handle)
    }

    func function<T>(named name: String, as type: T.Type) -> T? {
        guard let symbol = dlsym(handle, name) else { return nil }
        return unsafeBitCast(symbol, to: type)
    }
}
