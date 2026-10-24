/// What can go in the detail bar; the user picks the order and visibility in Settings.
/// The rawValue is stored in the settings JSON, so the cases must not be renamed.
enum BarItem: String, Codable, CaseIterable {
    case cpu
    case gpu
    case memory
    case cpuTemperature
    case gpuTemperature
    case fan
    case fanControl
    case claude
    case media
    case settings

    var title: String {
        switch self {
        case .cpu: return "CPU usage"
        case .gpu: return "GPU usage"
        case .memory: return "RAM"
        case .cpuTemperature: return "CPU temperature"
        case .gpuTemperature: return "GPU temperature"
        case .fan: return "Fan speed"
        case .fanControl: return "Fan control"
        case .claude: return "Claude usage"
        case .media: return "Animation (GIF / video)"
        case .settings: return "Settings button"
        }
    }

    var symbolName: String {
        switch self {
        case .cpu: return "cpu"
        case .gpu: return "cpu.fill"
        case .memory: return "memorychip"
        case .cpuTemperature, .gpuTemperature: return "thermometer.medium"
        case .fan: return "fan"
        case .fanControl: return "slider.horizontal.3"
        case .claude: return "sparkle"
        case .media: return "play.rectangle"
        case .settings: return "gearshape"
        }
    }

    /// Visible the first time the app opens (or when a new item appears in a future version).
    var isVisibleByDefault: Bool {
        switch self {
        case .media, .settings: return false
        default: return true
        }
    }

    /// The metric this item draws, if it is a metric.
    var metric: Metric? {
        switch self {
        case .cpu: return .cpu
        case .gpu: return .gpu
        case .memory: return .memory
        case .cpuTemperature: return .cpuTemperature
        case .gpuTemperature: return .gpuTemperature
        case .fan: return .fan
        case .fanControl, .claude, .media, .settings: return nil
        }
    }
}
