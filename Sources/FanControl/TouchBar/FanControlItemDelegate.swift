/// Whoever presents the bars: opens the fan one.
protocol FanControlItemDelegate: AnyObject {
    func fanControlDidRequestOpen(_ item: FanControlItem)
}
