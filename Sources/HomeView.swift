import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var blinkOn: Bool = true
    @State private var showTripList: Bool = false
    @State private var showStationSelection: Bool = false

    var nextTrip: Trip? {
        guard viewModel.nextIndex < viewModel.trips.count else { return nil }
        return viewModel.trips[viewModel.nextIndex]
    }

    var displayTrip: Trip? {
        if let t = nextTrip { return t }
        return viewModel.trips.first
    }

    var noTrainsAtAll: Bool { viewModel.trips.isEmpty }
    var isPastLastTrain: Bool { !viewModel.trips.isEmpty && nextTrip == nil }

    var isDeparting: Bool {
        guard let trip = nextTrip else { return false }
        return viewModel.goodTimes.departing(trip.depart)
    }

    var ringColor: Color {
        if viewModel.swapped || isPastLastTrain { return .calSwapped }
        if isDeparting { return .calDepart }
        return .calArrive
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

            VStack {
                LinearGradient(
                    colors: [Color(white: 0.5), Color.black],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 200)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Next Caltrain")
                        .foregroundColor(.white)
                        .font(.system(size: AppStyle.fontStatusBar, weight: .bold))
                    Spacer()
                    Text(viewModel.goodTimes.fullTime())
                        .foregroundColor(.white)
                        .font(.system(size: AppStyle.fontStatusBar, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(ringColor, lineWidth: 5)
                        .frame(width: 230, height: 230)
                        .animation(.easeInOut(duration: 0.4), value: ringColor)

                    VStack(spacing: 6) {
                        VStack(spacing: 0) {
                            Text(line1)
                                .foregroundColor(.white)
                                .font(.system(size: AppStyle.fontOriginHero, weight: .bold))
                            Text(line2)
                                .foregroundColor(.white)
                                .font(.system(size: AppStyle.fontOriginHero, weight: .bold))
                        }
                        .onTapGesture { showStationSelection = true }

                        if noTrainsAtAll {
                            Text("No trains")
                                .foregroundColor(.white)
                                .font(.system(size: AppStyle.fontBlurbHero, weight: .regular))
                        } else {
                            // blurb-hero
                            if isDeparting {
                                Text("DEPARTING")
                                    .foregroundColor(.calDepart)
                                    .font(.system(size: AppStyle.fontBlurbHero, weight: .regular))
                                    .opacity(blinkOn ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.5), value: blinkOn)
                            } else if isPastLastTrain || viewModel.swapped {
                                Text(viewModel.scheduleType.label)
                                    .foregroundColor(.calPast)
                                    .font(.system(size: AppStyle.fontBlurbHero, weight: .regular))
                            } else if let countdown = viewModel.countdown {
                                Text(countdown)
                                    .foregroundColor(.calArrive)
                                    .font(.system(size: AppStyle.fontBlurbHero, weight: .regular))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }

                            // train-hero + time-hero + meridiem-hero
                            if let trip = displayTrip {
                                let infoColor: Color = (isPastLastTrain || viewModel.swapped) ? .calPast : .white
                                let (timeStr, merStr) = GoodTimes.partTime(trip.depart)
                                VStack(spacing: 2) {
                                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                                        Text("#\(trip.legs.first!.trainId)")
                                            .foregroundColor(infoColor)
                                            .font(.system(size: AppStyle.fontTrainHero, weight: .regular))
                                        Text(timeStr)
                                            .foregroundColor(infoColor)
                                            .font(.system(size: AppStyle.fontTimeHero, weight: .regular))
                                        Text(merStr)
                                            .foregroundColor(infoColor)
                                            .font(.system(size: AppStyle.fontMeridiemHero, weight: .regular))
                                    }
                                    Text(CaltrainService.trainType(trip.legs.first!.trainId))
                                        .foregroundColor(.white)
                                        .font(.system(size: AppStyle.fontTripType, weight: .regular))
                                }
                            }
                        }
                    }
                    .frame(width: 190)
                    .offset(y: 8)
                }
                .contentShape(Circle())
                .onTapGesture {
                    if !noTrainsAtAll { showTripList = true }
                }
                .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                    blinkOn = isDeparting ? !blinkOn : true
                }

                Spacer()
            }

            NavigationLink(destination: TripListView(viewModel: viewModel), isActive: $showTripList) {
                EmptyView()
            }
            NavigationLink(destination: StationSelectionView(viewModel: viewModel), isActive: $showStationSelection) {
                EmptyView()
            }
        }
        .navigationBarHidden(true)
    }
}
