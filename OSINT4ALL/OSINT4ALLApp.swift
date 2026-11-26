import SwiftUI

@main
struct OSINT4ALLApp: App {
    @StateObject private var store = DirectoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
