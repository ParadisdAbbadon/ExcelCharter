//
//  FileImportViewModel.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 28.11.25.
//

import Foundation
import CoreXLSX
import SwiftData

@Observable
class FileImportViewModel {
    var errorMessage: String?
    private var modelContext: ModelContext?
    
    // Initialize with ModelContext
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func importFile(from url: URL) {
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        if fileExtension == "csv" {
            processCSV(url: url, fileName: fileName, fileExtension: fileExtension)
        } else if fileExtension == "xlsx" || fileExtension == "xls" {
            processExcel(url: url, fileName: fileName, fileExtension: fileExtension)
        } else {
            errorMessage = "Unsupported file type: \(fileExtension)"
            print(errorMessage ?? "")
        }
    }
    
    func removeFile(_ sheetFile: SheetFile) {
        guard let context = modelContext else { return }
        context.delete(sheetFile)
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to delete file: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    // MARK: - Private Methods
    
    private func processCSV(url: URL, fileName: String, fileExtension: String) {
        do {
            let csvString = try String(contentsOf: url, encoding: .utf8)
            let rows = csvString.components(separatedBy: .newlines)
            
            print("CSV has \(rows.count) rows")
            
            // Store the CSV data
            var csvData: [[String]] = []
            for row in rows where !row.isEmpty {
                let columns = row.components(separatedBy: ",")
                csvData.append(columns)
            }
            
            // Create and save to SwiftData
            let newSheet = SheetFile(
                id: UUID(),
                title: fileName,
                data: csvData,
                fileExtension: fileExtension
            )
            
            saveToSwiftData(newSheet)
            
            // Print first few rows for debugging
            for (index, row) in rows.prefix(5).enumerated() {
                print("Row \(index): \(row)")
            }
            
            errorMessage = nil
            
        } catch {
            errorMessage = "Error reading CSV: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    private func processExcel(url: URL, fileName: String, fileExtension: String) {
        do {
            // Copy the file to a temporary location first
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            // Remove existing temp file if it exists
            try? FileManager.default.removeItem(at: tempURL)
            
            // Copy the file from source to temp location
            try FileManager.default.copyItem(at: url, to: tempURL)
            
            // Open the Excel file from temp location
            guard let file = XLSXFile(filepath: tempURL.path) else {
                errorMessage = "Failed to open Excel file"
                print(errorMessage ?? "")
                return
            }
            
            // Get all worksheet paths
            let worksheetPaths = try file.parseWorksheetPaths()
            print("Found \(worksheetPaths.count) worksheets")
            
            // Get the shared strings (for text cells)
            let sharedStrings = try file.parseSharedStrings()
            
            var excelData: [[String]] = []
            
            // Process each worksheet
            for path in worksheetPaths {
                let worksheet = try file.parseWorksheet(at: path)
                
                print("\nWorksheet path: \(path)")
                
                // Process rows
                if let rows = worksheet.data?.rows {
                    print("Has \(rows.count) rows")
                    
                    for (rowIndex, row) in rows.enumerated() {
                        var rowValues: [String] = []
                        
                        for cell in row.cells {
                            let cellValue: String
                            if let sharedStrings = sharedStrings {
                                cellValue = cell.stringValue(sharedStrings) ?? ""
                            } else {
                                cellValue = cell.value ?? ""
                            }
                            rowValues.append(cellValue)
                        }
                        
                        excelData.append(rowValues)
                        
                        // Print first few rows for debugging
                        if rowIndex < 5 {
                            print("Row \(rowIndex): \(rowValues.joined(separator: ", "))")
                        }
                    }
                }
            }
            
            // Create and save to SwiftData
            let newSheet = SheetFile(
                id: UUID(),
                title: fileName,
                data: excelData,
                fileExtension: fileExtension
            )
            
            saveToSwiftData(newSheet)
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            
            errorMessage = nil
            
        } catch {
            errorMessage = "Error reading Excel file: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    private func saveToSwiftData(_ sheetFile: SheetFile) {
        guard let context = modelContext else {
            errorMessage = "ModelContext not available"
            return
        }
        
        context.insert(sheetFile)
        
        do {
            try context.save()
            print("Successfully saved \(sheetFile.title) to SwiftData")
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
}
