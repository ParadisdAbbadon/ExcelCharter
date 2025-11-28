//
//  SheetFile.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 28.11.25.
//

import Foundation
import SwiftData

@Model
class SheetFile {
    @Attribute(.unique) var id: UUID
    var title: String
    var dateImported: Date
    var fileExtension: String
    
    // Store the 2D array as JSON data
    @Attribute(.externalStorage) private var rawData: Data?
    
    // Relationship to chart configurations
    @Relationship(deleteRule: .cascade, inverse: \ChartConfiguration.sheetFile)
    var chartConfigurations: [ChartConfiguration]? = []
    
    // Computed property to access the data array
    var data: [[String]]? {
        get {
            guard let rawData = rawData else { return nil }
            return try? JSONDecoder().decode([[String]].self, from: rawData)
        }
        set {
            guard let newValue = newValue else {
                rawData = nil
                return
            }
            rawData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(id: UUID = UUID(), title: String, data: [[String]]? = nil, fileExtension: String = "") {
        self.id = id
        self.title = title
        self.dateImported = Date()
        self.fileExtension = fileExtension
        self.data = data
    }
}
