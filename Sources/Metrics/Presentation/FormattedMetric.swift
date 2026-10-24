/// A metric ready to display: short text (Control Strip) and detail text (full Touch Bar).
struct FormattedMetric {
    let title: String
    let symbolName: String
    let shortValue: String
    let detailValue: String
    let level: LoadLevel
}
