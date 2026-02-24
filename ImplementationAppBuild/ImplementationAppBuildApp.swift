import SwiftUI
import SwiftData
import UIKit

@main
struct ImplementationAppBuildApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Baby.self,
            BabyEvent.self,
            ConversationEntry.self,
            Vaccination.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        UIApplication.shared.applicationSupportsShakeToEdit = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
