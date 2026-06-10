import SwiftUI

struct TripListView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var showStationSelection: Bool = false
    @State private var blinkOn: Bool = true
    @State private var dragShift: Int = 0

    private let rowHeight: CGFloat = 44

    // Effective offset including live drag shift
    var effectiveOffset: Int {
        let shifted = viewModel.offset + dragShift
        return max(0, min(shifted, viewModel.trips.count - 1))
    }

    // All header values derived from effectiveOffset for live updates during drag
    var selectedTrip: Trip? {
        guard effectiveOffset < viewModel.trips.count else { return nil }
        return viewModel.trips[effectiveOffset]
    }

    var isSelectedPast: Bool {
        guard let trip = selectedTrip else { return false }
        return viewModel.goodTimes.inThePast(trip.depart)
    }

    var isSelectedDeparting: Bool {
        guard let trip = selectedTrip else { return false }
        return viewModel.goodTimes.departing(trip.depart)
    }

    var serviceLabel: String {
        guard let trip = selectedTrip else { return "" }
        return CaltrainService.trainType(trip.legs.first!.trainId) + " Service"
    }

    var statusColor: Color {
        if viewModel.swapped     { return .calSwapped }
        if isSelectedPast        { return .calPast }
        if isSelectedDeparting   { return .calDepart }
        return .calArrive
    }

    var statusText: String {
        if viewModel.swapped || isSelectedPast {
            return "\(viewModel.scheduleType.label) Schedule"
        }
        if isSelectedDeparting { return "DEPARTING" }
        if let trip = selectedTrip {
            let c = viewModel.goodTimes.countdown(trip.depart)
            return c.isEmpty ? "" : c
        }
        return ""
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

    func tripAt(_ slot: Int) -> Trip? {
        let idx = effectiveOffset + slot
        guard idx >= 0 && idx < viewModel.trips.count else { return nil }
        return viewModel.trips[idx]
    }

    func isNext(_ slot: Int) -> Bool {
        return slot == 0 && !viewModel.swapped
    }

    func isPast(_ slot: Int) -> Bool {
        if viewModel.swapped { return false }
        let idx = effectiveOffset + slot
        guard idx < viewModel.trips.count else { return false }
        return viewModel.goodTimes.inThePast(viewModel.trips[idx].depart)
    }

    func isDepartingSlot(_ slot: Int) -> Bool {
        return slot == 0 && isSelectedDeparting
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {

                // statusbar — service label updates with drag
                HStack {
                    Text(serviceLabel)
                        .foregroundColor(viewModel.swapped ? .calSwapped : .white)
                        .font(.system(size: AppStyle.fontStatusBar, weight: .regular))
                    Spacer()
                    Text(viewModel.goodTimes.fullTime())
                        .foregroundColor(.white)
                        .font(.system(size: AppStyle.fontStatusBar, weight: .regular))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // origin / destination
                VStack(spacing: 2) {
                    Text(line1)
                        .font(.system(size: AppStyle.fontOriginHero, weight: .bold))
                        .foregroundColor(.white)
                    Text(line2)
                        .font(.system(size: AppStyle.fontOriginHero, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
                .onTapGesture { showStationSelection = true }

                // blurb — updates live during drag
                Text(statusText)
                    .font(.system(size: AppStyle.fontBlurbHero, weight: .regular))
                    .foregroundColor(statusColor)
                    .opacity(isSelectedDeparting ? (blinkOn ? 1 : 0) : 1)
                    .animation(.easeInOut(duration: 0.5), value: blinkOn)
                    .padding(.top, 4)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .onTapGesture { viewModel.cycleSchedule() }

                // Static trip slots
                VStack(spacing: 0) {
                    ForEach(0..<min(20, max(viewModel.trips.count, 1)), id: \.self) { slot in
                        if let trip = tripAt(slot) {
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
                                    isNext: isNext(slot),
                                    isPast: isPast(slot),
                                    isDeparting: isDepartingSlot(slot),
                                    swapped: viewModel.swapped
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            let newShift = -Int((value.translation.height / rowHeight).rounded())
                            let proposed = viewModel.offset + newShift
                            if proposed >= 0 && proposed < viewModel.trips.count {
                                dragShift = newShift
                            }
                        }
                        .onEnded { value in
                            let finalShift = -Int((value.translation.height / rowHeight).rounded())
                            let proposed = viewModel.offset + finalShift
                            if proposed >= 0 && proposed < viewModel.trips.count {
                                viewModel.offset = proposed
                            }
                            dragShift = 0
                        }
                )
                .padding(.top, 8)

                Spacer()
            }

            NavigationLink(destination: StationSelectionView(viewModel: viewModel), isActive: $showStationSelection) {
                EmptyView()
            }
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            blinkOn = isSelectedDeparting ? !blinkOn : true
        }
    }
}
