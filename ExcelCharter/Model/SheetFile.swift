//
//  SheetFile.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//
//  Model detailing how .csv file
//  data will be handled when imported
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
