import SwiftUI

struct StationSelectionView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveConfirm = false
    @State private var pendingDismiss = false

    var stations: [String] { viewModel.schedule.southStops }

    var isFlipped: Bool {
        Calendar.current.component(.hour, from: Date()) >= 12
    }

    var morningStation: String { isFlipped ? viewModel.destination : viewModel.origin }
    var eveningStation: String { isFlipped ? viewModel.origin : viewModel.destination }

    var isAlreadyDefault: Bool {
        let s = viewModel.schedule.southStops
        let savedAM = (UserDefaults.standard.object(forKey: "stopAM") as? Int) ?? 15
        let savedPM = (UserDefaults.standard.object(forKey: "stopPM") as? Int) ?? 0
        guard savedAM < s.count, savedPM < s.count else { return false }
        let defaultOrigin = isFlipped ? s[savedPM] : s[savedAM]
        let defaultDest   = isFlipped ? s[savedAM] : s[savedPM]
        return viewModel.origin == defaultOrigin && viewModel.destination == defaultDest
    }

    func handleBack() {
        if !isAlreadyDefault {
            showSaveConfirm = true
        } else {
            dismiss()
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {

                // Top half — Origin
                VStack(spacing: 0) {
                    Text("Origin")
                        .foregroundColor(.green)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)

                    ScrollViewReader { proxy in
                        List(stations, id: \.self) { station in
                            HStack {
                                Text(station)
                                    .foregroundColor(.white)
                                Spacer()
                                if station == viewModel.origin {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .listRowBackground(Color.black)
                            .id(station)
                            .onTapGesture {
                                viewModel.origin = station
                                viewModel.refresh()
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.black)
                        .onAppear {
                            proxy.scrollTo(viewModel.origin, anchor: .center)
                        }
                        .onChange(of: viewModel.origin) { newOrigin in
                            withAnimation { proxy.scrollTo(newOrigin, anchor: .center) }
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                Divider().background(Color.gray)

                // Bottom half — Destination
                VStack(spacing: 0) {
                    Text("Destination")
                        .foregroundColor(.green)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black)

                    ScrollViewReader { proxy in
                        List(stations, id: \.self) { station in
                            HStack {
                                Text(station)
                                    .foregroundColor(.white)
                                Spacer()
                                if station == viewModel.destination {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .listRowBackground(Color.black)
                            .id(station)
                            .onTapGesture {
                                viewModel.destination = station
                                viewModel.refresh()
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.black)
                        .onAppear {
                            proxy.scrollTo(viewModel.destination, anchor: .center)
                        }
                        .onChange(of: viewModel.destination) { newDest in
                            withAnimation { proxy.scrollTo(newDest, anchor: .center) }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle("Stations")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    handleBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.swapStations()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.white)
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
