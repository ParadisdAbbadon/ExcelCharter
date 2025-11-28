//
//  ExcelCharterApp.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 28.11.25.
//

import SwiftUI
import SwiftData

@main
struct ExcelCharterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SheetFile.self,
            ChartConfiguration.self,
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
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
