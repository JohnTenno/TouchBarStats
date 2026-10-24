/// A row of the Settings list: which item and whether it is shown. Its position in the list is its order in the bar.
struct BarItemEntry: Codable, Equatable {
    let item: BarItem
    var isVisible: Bool
}
