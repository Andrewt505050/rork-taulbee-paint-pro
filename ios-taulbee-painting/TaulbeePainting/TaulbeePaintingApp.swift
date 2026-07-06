//
//  TaulbeePaintingApp.swift
//  TaulbeePainting
//
//  Created by Rork on May 31, 2026.
//

import SwiftUI
import SwiftData

@main
struct TaulbeePaintingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PaintScan.self,
            VisionProject.self,
            HomeRecord.self,
            RecordAttachment.self,
            ChatMessage.self,
            PaintRoom.self,
            RoomPhoto.self,
            SavedColor.self,
            PaintReminder.self,
            ActivityEvent.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
