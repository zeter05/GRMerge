import SwiftUI

struct ContentView: View {
    @StateObject private var vm = CompareViewModel()

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(vm: vm)
                .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } detail: {
            ResultsView(vm: vm)
        }
        .frame(minWidth: 820, minHeight: 520)
    }
}
