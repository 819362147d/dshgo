// GroqChatApp.swift
// dshgo / GroqChat — app entry point.

import SwiftUI

@main
struct GroqChatApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
