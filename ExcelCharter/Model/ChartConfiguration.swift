//
//  ChartConfiguration.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 28.11.25.
//

import Foundation
import SwiftData

@Model
class ChartConfiguration {
    @Attribute(.unique) var id: UUID
    var name: String
    var chartType: String // Stored as String for SwiftData compatibility
    var xAxisColumn: Int
    var yAxisColumn: Int
    var dateCreated: Date
    
    // Customization properties
    var chartColor: String // Hex color string
    var showLegend: Bool
    var showGridLines: Bool
    var xAxisLabel: String?
    var yAxisLabel: String?
    
    // Relationship to SheetFile
    var sheetFile: SheetFile?
    
    init(
        id: UUID = UUID(),
        name: String,
        chartType: ChartType,
        xAxisColumn: Int,
        yAxisColumn: Int,
        chartColor: String = "#007AFF",
        showLegend: Bool = true,
        showGridLines: Bool = true,
        xAxisLabel: String? = nil,
        yAxisLabel: String? = nil
    ) {
        self.id = id
        self.name = name
        self.chartType = chartType.rawValue
        self.xAxisColumn = xAxisColumn
        self.yAxisColumn = yAxisColumn
        self.dateCreated = Date()
        self.chartColor = chartColor
        self.showLegend = showLegend
        self.showGridLines = showGridLines
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
    }
    
    // Helper to convert back to ChartType enum
    var chartTypeEnum: ChartType {
        ChartType(rawValue: chartType) ?? .bar
    }
}
