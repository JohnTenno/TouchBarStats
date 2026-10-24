import SwiftUI

/// List of detail bar items: a checkbox to show or hide and arrows to reorder.
struct BarItemsSection: View {
    @Binding var settings: AppSettings

    var body: some View {
        Section {
            ForEach(Array(settings.items.enumerated()), id: \.element.item) { index, entry in
                HStack {
                    Toggle(isOn: visibility(of: entry.item)) {
                        Label(entry.item.title, systemImage: entry.item.symbolName)
                    }
                    .toggleStyle(.checkbox)
                    if entry.item == .media && settings.media.path == nil {
                        Text("choose a file below").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { settings.move(entry.item, by: -1) } label: { Image(systemName: "chevron.up") }
                        .disabled(index == 0)
                    Button { settings.move(entry.item, by: 1) } label: { Image(systemName: "chevron.down") }
                        .disabled(index == settings.items.count - 1)
                }
                .buttonStyle(.borderless)
            }
        } header: {
            Text("Detail bar")
        } footer: {
            Text("Left to right, in this order. If they don't all fit, the Touch Bar hides the last ones.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func visibility(of item: BarItem) -> Binding<Bool> {
        Binding(get: { settings.isVisible(item) }, set: { settings.setVisible(item, $0) })
    }
}
