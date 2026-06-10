import SwiftUI

struct TripListView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var showStationSelection: Bool = false

    var isPastLastTrain: Bool {
        !viewModel.trips.isEmpty && viewModel.nextIndex >= viewModel.trips.count
    }

    var isDeparting: Bool {
        guard viewModel.nextIndex < viewModel.trips.count else { return false }
        return viewModel.goodTimes.departing(viewModel.trips[viewModel.nextIndex].depart)
    }

    var statusColor: Color {
        if viewModel.swapped   { return .calSwapped }
        if isPastLastTrain     { return .calPast }
        if isDeparting         { return .calDepart }
        return .calArrive
    }

    var statusText: String {
        if viewModel.swapped || isPastLastTrain {
            return "\(viewModel.scheduleType.label) Schedule"
        }
        if isDeparting { return "DEPARTING" }
        return viewModel.countdown ?? ""
    }

    var line1: String {
        let o = viewModel.origin
        let d = viewModel.destination
        return o.count + 3 >= d.count ? o : "\(o) to"
    }

    var line2: String {
        let o = viewModel.origin
        let d = viewModel.destination
        return o.count + 3 >= d.count ? "to \(d)" : d
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                HStack {
                    Text(viewModel.serviceLabel)
                        .foregroundColor(viewModel.swapped ? .calSwapped : .white)
                        .font(.headline)
                    Spacer()
                    Text(viewModel.goodTimes.fullTime())
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Origin / Destination
                VStack(spacing: 2) {
                    Text(line1)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text(line2)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
                .onTapGesture { showStationSelection = true }

                // Status line
                Text(statusText)
                    .font(.title3.bold())
                    .foregroundColor(statusColor)
                    .padding(.top, 4)
                    .onTapGesture { viewModel.cycleSchedule() }

                // Trip list
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.trips.enumerated()), id: \.offset) { index, trip in
                                NavigationLink {
                                    TripDetailView(
                                        trip: trip,
                                        schedule: viewModel.schedule,
                                        origin: viewModel.origin,
                                        destination: viewModel.destination,
                                        scheduleType: viewModel.scheduleType,
                                        goodTimes: viewModel.goodTimes
                                    )
                                } label: {
                                    TripRow(
                                        trip: trip,
                                        isNext: isPastLastTrain ? index == 0 : (index == viewModel.nextIndex && !viewModel.swapped),
                                        isPast: viewModel.swapped ? false : index < viewModel.nextIndex,
                                        isDeparting: index == viewModel.nextIndex && isDeparting,
                                        swapped: viewModel.swapped || isPastLastTrain
                                    )
                                }
                                .buttonStyle(.plain)
                                .id(index)
                            }
                        }
                        .onAppear {
                            let scrollTo = isPastLastTrain ? 0 : viewModel.nextIndex
                            proxy.scrollTo(max(0, scrollTo), anchor: .top)
                        }
                        .onChange(of: viewModel.nextIndex) { idx in
                            let scrollTo = isPastLastTrain ? 0 : idx
                            proxy.scrollTo(max(0, scrollTo), anchor: .top)
                        }
                    }
                }
                .padding(.top, 8)
            }

            NavigationLink(destination: StationSelectionView(viewModel: viewModel), isActive: $showStationSelection) {
                EmptyView()
            }
        }
    }
}
