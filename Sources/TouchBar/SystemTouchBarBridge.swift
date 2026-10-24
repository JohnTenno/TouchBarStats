import AppKit

/// Access to the private APIs (the same ones MTMR and Pock use) to put a button in the Control Strip.
final class SystemTouchBarBridge {
    private typealias SetControlStripPresence = @convention(c) (CFString, Bool) -> Void
    private typealias ShowCloseBox = @convention(c) (Bool) -> Void

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
        showCloseBox?(true)
        _ = (NSTouchBar.self as AnyObject).perform(
            NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:"),
            with: touchBar, with: item.identifier.rawValue)
    }
}
