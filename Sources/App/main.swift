import AppKit

// Composition root: every piece is created and wired here.
let location = SettingsLocation.standard
let settingsStore = SettingsStore(file: location.settingsFile)
let settingsWindow = SettingsWindowController(store: settingsStore, library: MediaLibrary(directory: location.mediaDirectory))

let formatter = SnapshotFormatter()
let monitor = SystemMonitor(cpuReader: CPUUsageReader(),
                            gpuReader: GPUUsageReader(),
                            memoryReader: MemoryUsageReader(),
                            temperatureReader: TemperatureReader(source: HIDTemperatureSensors()),
                            fanReader: FanSpeedReader(smc: SMCConnection()),
                            interval: settingsStore.settings.refreshInterval)
let fanControl = FanControlItem(client: FanControlClient(), formatter: formatter)
let claudeMonitor = ClaudeUsageMonitor(client: ClaudeUsageClient())
let claudeUsage = ClaudeUsageItem { claudeMonitor.refresh(replacingCurrent: true) }
claudeMonitor.add(claudeUsage)

let media = MediaTouchBarItem()
let settingsButton = SettingsButtonItem { settingsWindow.show() }
let detail = DetailTouchBar(formatter: formatter, fanControl: fanControl.buttonItem, claudeUsage: claudeUsage.buttonItem,
                            media: media.item, settingsButton: settingsButton.item)
monitor.add(detail)
monitor.add(fanControl)

let strip = ControlStripItem()
let coordinator = TouchBarCoordinator(bridge: SystemTouchBarBridge(), strip: strip, detail: detail,
                                      fanControl: fanControl, claudeUsage: claudeUsage)
let statusMenu = StatusMenuController { settingsWindow.show() }
let delegate = AppDelegate(monitor: monitor, claudeMonitor: claudeMonitor, coordinator: coordinator,
                           settingsWindow: settingsWindow)
([strip, media, detail, statusMenu, delegate] as [SettingsObserver]).forEach { settingsStore.add($0) }

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
