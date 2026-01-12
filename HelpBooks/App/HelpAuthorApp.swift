import SwiftUI

@main
struct HelpAuthorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(replacing: .help) {
                Button("HelpAuthor Help") {
                    // Will open HelpAuthor's own help when implemented
                }
            }
        }
    }
}

