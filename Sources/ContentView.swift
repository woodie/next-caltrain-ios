import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TripViewModel()

    var body: some View {
        NavigationStack {
            HomeView(viewModel: viewModel)
        }
    }
}
