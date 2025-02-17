// Don't touch

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var levelManager = LevelManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(levelManager)
        }
    }
}
