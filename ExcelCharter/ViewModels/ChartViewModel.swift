//
//  ChartViewModel.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 28.11.25.
//

import Foundation
import Observation

@Observable
class ChartViewModel {
    // MARK: - Properties
    var chartType: ChartType = .bar
    var xAxisColumn: Int = 0
    var yAxisColumn: Int = 1
    var errorMessage: String?
    var isDataValid: Bool = false
    
    private(set) var columnTypes: [ColumnType] = []
    private(set) var columnNames: [String] = []
    private(set) var availableDataRange: Range<Int>?
    
    // MARK: - Public Methods
    
    /// Initialize the view model with data from a sheet file
    func initialize(with data: [[String]]) {
        guard !data.isEmpty else {
            errorMessage = "No data available"
            isDataValid = false
            return
        }
        
        // Extract column names from first row (header)
        columnNames = data.first ?? []
        
        // Detect column types for all columns
        columnTypes = detectColumnTypes(data: data)
        
        // Set available data range (excluding header)
        if data.count > 1 {
            availableDataRange = 1..<data.count
        }
        
        // Validate initial selection
        _ = validateSelection(data: data)
    }
    
    /// Validate if the current column selection can produce a valid chart
    func validateSelection(data: [[String]]) -> Bool {
        errorMessage = nil
        
        // Check if data exists
        guard !data.isEmpty else {
            errorMessage = "No data available"
            isDataValid = false
            return false
        }
        
        // Check if we have at least header + 1 data row
        guard data.count >= 2 else {
            errorMessage = "Need at least one data row (plus header)"
            isDataValid = false
            return false
        }
        
        // Validate column indices
        guard xAxisColumn >= 0 && xAxisColumn < columnNames.count else {
            errorMessage = "Invalid X-axis column selection"
            isDataValid = false
            return false
        }
        
        guard yAxisColumn >= 0 && yAxisColumn < columnNames.count else {
            errorMessage = "Invalid Y-axis column selection"
            isDataValid = false
            return false
        }
        
        // Check if columns are different
        guard xAxisColumn != yAxisColumn else {
            errorMessage = "X and Y axes must use different columns"
            isDataValid = false
            return false
        }
        
        // Validate Y-axis must be numeric
        guard columnTypes.indices.contains(yAxisColumn),
              columnTypes[yAxisColumn] == .numeric else {
            errorMessage = "Y-axis must contain numeric data"
            isDataValid = false
            return false
        }
        
        // Check if we have valid data points
        let chartData = prepareChartData(from: data)
        guard !chartData.isEmpty else {
            errorMessage = "No valid data points found"
            isDataValid = false
            return false
        }
        
        // Additional validation: check for minimum data points
        guard chartData.count >= 2 else {
            errorMessage = "Need at least 2 data points to create a chart"
            isDataValid = false
            return false
        }
        
        isDataValid = true
        return true
    }
    
    /// Prepare data for charting by extracting selected columns
    func prepareChartData(from data: [[String]]) -> [ChartDataPoint] {
        guard data.count > 1 else { return [] }
        
        var chartData: [ChartDataPoint] = []
        
        // Skip header row (index 0)
        for rowIndex in 1..<data.count {
            let row = data[rowIndex]
            
            // Ensure row has enough columns
            guard row.indices.contains(xAxisColumn),
                  row.indices.contains(yAxisColumn) else {
                continue
            }
            
            let xValue = row[xAxisColumn].trimmingCharacters(in: .whitespacesAndNewlines)
            let yValueString = row[yAxisColumn].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty values
            guard !xValue.isEmpty, !yValueString.isEmpty else {
                continue
            }
            
            // Convert Y value to Double
            guard let yValue = Double(yValueString) else {
                continue
            }
            
            chartData.append(ChartDataPoint(
                x: xValue,
                y: yValue,
                rowIndex: rowIndex
            ))
        }
        
        return chartData
    }
    
    /// Detect the data type of each column
    func detectColumnTypes(data: [[String]]) -> [ColumnType] {
        guard let firstRow = data.first else { return [] }
        
        var types: [ColumnType] = []
        
        for columnIndex in firstRow.indices {
            let columnType = detectColumnType(data: data, columnIndex: columnIndex)
            types.append(columnType)
        }
        
        return types
    }
    
    /// Get a preview of values for a specific column (excluding header)
    func getColumnPreview(data: [[String]], columnIndex: Int, maxItems: Int = 5) -> [String] {
        guard columnIndex >= 0 && columnIndex < columnNames.count else {
            return []
        }
        
        var preview: [String] = []
        
        // Start from index 1 to skip header
        for rowIndex in 1..<min(data.count, maxItems + 1) {
            if data[rowIndex].indices.contains(columnIndex) {
                let value = data[rowIndex][columnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    preview.append(value)
                }
            }
        }
        
        return preview
    }
    
    /// Check if a column is suitable for Y-axis (must be numeric)
    func isColumnValidForYAxis(columnIndex: Int) -> Bool {
        guard columnTypes.indices.contains(columnIndex) else {
            return false
        }
        return columnTypes[columnIndex] == .numeric
    }
    
    /// Get a user-friendly description of the column type
    func getColumnTypeDescription(columnIndex: Int) -> String {
        guard columnTypes.indices.contains(columnIndex) else {
            return "Unknown"
        }
        
        switch columnTypes[columnIndex] {
        case .numeric:
            return "Numeric"
        case .categorical:
            return "Text"
        case .date:
            return "Date"
        case .unknown:
            return "Mixed/Unknown"
        }
    }
    
    // MARK: - Private Methods
    
    /// Detect the type of a specific column by analyzing its values
    private func detectColumnType(data: [[String]], columnIndex: Int) -> ColumnType {
        guard data.count > 1 else { return .unknown }
        
        var numericCount = 0
        var dateCount = 0
        var totalValidValues = 0
        
        // Skip header row and analyze data rows
        for rowIndex in 1..<data.count {
            guard data[rowIndex].indices.contains(columnIndex) else {
                continue
            }
            
            let value = data[rowIndex][columnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty values
            guard !value.isEmpty else {
                continue
            }
            
            totalValidValues += 1
            
            // Check if numeric
            if Double(value) != nil {
                numericCount += 1
            }
            
            // Check if date (basic check for common date patterns)
            if isLikelyDate(value) {
                dateCount += 1
            }
        }
        
        guard totalValidValues > 0 else {
            return .unknown
        }
        
        // Determine type based on percentage of matching values
        let numericPercentage = Double(numericCount) / Double(totalValidValues)
        let datePercentage = Double(dateCount) / Double(totalValidValues)
        
        // If 80% or more values are numeric, consider it numeric
        if numericPercentage >= 0.8 {
            return .numeric
        }
        
        // If 80% or more values look like dates, consider it date
        if datePercentage >= 0.8 {
            return .date
        }
        
        // If mostly text values, it's categorical
        if numericPercentage < 0.2 {
            return .categorical
        }
        
        // Mixed types
        return .unknown
    }
    
    /// Basic check if a string looks like a date
    private func isLikelyDate(_ value: String) -> Bool {
        // Common date patterns
        let datePatterns = [
            "\\d{4}-\\d{2}-\\d{2}",           // 2024-01-15
            "\\d{2}/\\d{2}/\\d{4}",           // 01/15/2024
            "\\d{2}-\\d{2}-\\d{4}",           // 01-15-2024
            "\\d{4}/\\d{2}/\\d{2}",           // 2024/01/15
        ]
        
        for pattern in datePatterns {
            if value.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Supporting Types

enum ChartType: String, CaseIterable, Identifiable {
    case bar = "Bar Chart"
    case line = "Line Chart"
    case point = "Scatter Plot"
    case area = "Area Chart"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .bar: return "chart.bar.fill"
        case .line: return "chart.line.uptrend.xyaxis"
        case .point: return "chart.dots.scatter"
        case .area: return "chart.line.uptrend.xyaxis.fill"
        }
    }
    
    var description: String {
        switch self {
        case .bar:
            return "Compare values across categories"
        case .line:
            return "Show trends over time or sequence"
        case .point:
            return "Display relationship between two variables"
        case .area:
            return "Emphasize magnitude of change over time"
        }
    }
}

enum ColumnType: Equatable {
    case numeric
    case categorical
    case date
    case unknown
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let x: String
    let y: Double
    let rowIndex: Int
    
    init(x: String, y: Double, rowIndex: Int) {
        self.x = x
        self.y = y
        self.rowIndex = rowIndex
    }
}
