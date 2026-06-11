import SwiftUI

private struct RowWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct StationSelectionView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveConfirm = false

    var stations: [String] { viewModel.schedule.southStops }

    var isFlipped: Bool {
        Calendar.current.component(.hour, from: Date()) >= 12
    }

    // Morning/Evening map onto origin/destination depending on time of day.
    var morningStation: String {
        isFlipped ? viewModel.destination : viewModel.origin
    }
    var eveningStation: String {
        isFlipped ? viewModel.origin : viewModel.destination
    }

    func setMorningStation(_ station: String) {
        if isFlipped {
            viewModel.destination = station
        } else {
            viewModel.origin = station
        }
        viewModel.refresh()
    }

    func setEveningStation(_ station: String) {
        if isFlipped {
            viewModel.origin = station
        } else {
            viewModel.destination = station
        }
        viewModel.refresh()
    }

    var isAlreadyDefault: Bool {
        let s = viewModel.schedule.southStops
        let savedAM = (UserDefaults.standard.object(forKey: "stopAM") as? Int) ?? 15
        let savedPM = (UserDefaults.standard.object(forKey: "stopPM") as? Int) ?? 0
        guard savedAM < s.count, savedPM < s.count else { return false }
        let defaultMorning = s[savedAM]
        let defaultEvening = s[savedPM]
        return morningStation == defaultMorning && eveningStation == defaultEvening
    }

    @State private var morningRowWidth: CGFloat = 0
    @State private var eveningRowWidth: CGFloat = 0

    func stationRow(_ station: String, selected: String, columnWidth: CGFloat) -> some View {
        Text(station)
            .foregroundColor(.white)
            .font(.system(size: AppStyle.fontOriginHero, weight: .regular))
            .fixedSize(horizontal: true, vertical: false)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: RowWidthKey.self, value: geo.size.width)
                }
            )
            .frame(width: columnWidth > 0 ? columnWidth : nil, alignment: .leading)
            .overlay(alignment: .leading) {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .opacity(station == selected ? 1 : 0)
                    .offset(x: -32)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .offset(x: 12)
            .contentShape(Rectangle())
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.green)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {

                // Top half — Morning
                ScrollViewReader { proxy in
                    List(stations, id: \.self) { station in
                        stationRow(station, selected: morningStation, columnWidth: morningRowWidth)
                            .listRowBackground(Color.black)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .id(station)
                            .onTapGesture {
                                setMorningStation(station)
                            }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    .onPreferenceChange(RowWidthKey.self) { width in
                        morningRowWidth = width
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        sectionHeader("Morning Station")
                    }
                    .onAppear {
                        proxy.scrollTo(morningStation, anchor: .center)
                    }
                    .onChange(of: morningStation) { newStation in
                        withAnimation { proxy.scrollTo(newStation, anchor: .center) }
                    }
                }
                .frame(maxHeight: .infinity)

                Divider().background(Color.gray)

                // Bottom half — Evening
                ScrollViewReader { proxy in
                    List(stations, id: \.self) { station in
                        stationRow(station, selected: eveningStation, columnWidth: eveningRowWidth)
                            .listRowBackground(Color.black)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .id(station)
                            .onTapGesture {
                                setEveningStation(station)
                            }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    .onPreferenceChange(RowWidthKey.self) { width in
                        eveningRowWidth = width
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        sectionHeader("Evening Station")
                    }
                    .onAppear {
                        proxy.scrollTo(eveningStation, anchor: .center)
                    }
                    .onChange(of: eveningStation) { newStation in
                        withAnimation { proxy.scrollTo(newStation, anchor: .center) }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle("Stations")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isAlreadyDefault {
                    Button {
                        showSaveConfirm = true
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .alert("Save Default Stations", isPresented: $showSaveConfirm) {
            Button("Save") {
                viewModel.saveStops()
                dismiss()
            }
            Button("Don't Save", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Save \(morningStation) as your morning departure and \(eveningStation) as your evening departure?")
        }
    }
}
