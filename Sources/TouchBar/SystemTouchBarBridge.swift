import AppKit
import ObjectiveC.runtime

/// Access to the private APIs used to put a button in the Control Strip.
final class SystemTouchBarBridge {
    private typealias SetControlStripPresence = @convention(c) (CFString, Bool) -> Void
    private typealias ShowCloseBox = @convention(c) (Bool) -> Void
    private typealias PresentWithPlacement = @convention(c) (AnyClass, Selector, NSTouchBar, Int64, NSString) -> Void
    private typealias Present = @convention(c) (AnyClass, Selector, NSTouchBar, NSString) -> Void

    private static let dfrPath = "/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation"

    private let library = DynamicLibrary(path: SystemTouchBarBridge.dfrPath)
    private lazy var setControlStripPresence =
        library?.function(named: "DFRElementSetControlStripPresenceForIdentifier", as: SetControlStripPresence.self)
    private lazy var showCloseBox =
        library?.function(named: "DFRSystemModalShowsCloseBoxWhenFrontMost", as: ShowCloseBox.self)

    func addToControlStrip(_ item: NSTouchBarItem) {
        _ = (NSTouchBarItem.self as AnyObject).perform(NSSelectorFromString("addSystemTrayItem:"), with: item)
        setControlStripPresence?(item.identifier.rawValue as CFString, true)
    }

    func present(_ touchBar: NSTouchBar, from item: NSTouchBarItem) {
        // Finish the Control Strip's tap tracking before replacing its bar. Otherwise
        // its tracking cleanup can dismiss the bar that was just presented.
        DispatchQueue.main.async { [self] in
            showCloseBox?(true)
            let selector = NSSelectorFromString("presentSystemModalTouchBar:placement:systemTrayItemIdentifier:")
            if let method = class_getClassMethod(NSTouchBar.self, selector) {
                let present = unsafeBitCast(method_getImplementation(method), to: PresentWithPlacement.self)
                // Placement 0 shares the bar with the system controls.
                present(NSTouchBar.self, selector, touchBar, 0, item.identifier.rawValue as NSString)
            } else {
                let fallback = NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:")
                if let method = class_getClassMethod(NSTouchBar.self, fallback) {
                    let present = unsafeBitCast(method_getImplementation(method), to: Present.self)
                    present(NSTouchBar.self, fallback, touchBar, item.identifier.rawValue as NSString)
                } else {
                    NSLog("TouchBarStats: system modal Touch Bar API is unavailable")
                }
            }
            // Presenting a system bar changes tray presence. Keep the entry registered
            // so it is available again when the user closes the full bar.
            setControlStripPresence?(item.identifier.rawValue as CFString, true)
        }
    }
}
