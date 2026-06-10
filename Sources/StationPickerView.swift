import SwiftUI

struct StationPickerView: View {
    let title: String
    let stations: [String]
    let selected: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(stations, id: \.self) { station in
            HStack {
                Text(station)
                    .foregroundColor(.primary)
                Spacer()
                if station == selected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(station)
                dismiss()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
