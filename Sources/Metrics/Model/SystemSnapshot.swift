/// Snapshot of the system state at one instant.
struct SystemSnapshot {
    let cpuUsage: Double?
    let gpuUsage: Double?
    let memory: MemoryUsage?
    let thermal: ThermalReading
    let fan: FanReading?
}
