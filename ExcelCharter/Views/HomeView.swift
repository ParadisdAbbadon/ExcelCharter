//
//  ContentView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreXLSX

struct HomeView: View {
    // MARK: - Properties
    ///@State variables
    @State private var showNewFileView = false //May be unnecessary
    @State private var showFileImporter = false
    
    ///Array of test files
    @State private var sheetfiles = [
        SheetFile(id: UUID(), title: "Sheet 1"),
        SheetFile(id: UUID(), title: "Sheet 2"),
        SheetFile(id: UUID(), title: "Sheet 3")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                ForEach(sheetfiles) { sheetfile in
                    NavigationLink {
                        //Destination View
                        Text("Temporary")
                    } label: {
                        Text(sheetfile.title)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("Home")
            .listStyle(.plain)
        }
        HStack {
            ///Search and Add buttons
            Button(action: {
                //logic
                print("search button tapped")
            })
            {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .frame(width: 20, height: 22)
            }
            .buttonStyle(.borderedProminent)
            .shadow(radius: 5)
            .tint(.gray)
            
            
            Button("Add File") {
                //showNewFileView = true
                showFileImporter = true
            }
            .buttonStyle(.borderedProminent)
            .shadow(radius: 5)
            .bold()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                handleFileImport(urls: urls)
            case .failure(let error):
                print("File import error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleFileImport(urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Couldn't access file")
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        let fileName = url.lastPathComponent
        print("Selected file: \(fileName)")
        
        // Check file extension
        let fileExtension = url.pathExtension.lowercased()
        
        if fileExtension == "csv" {
            processCSV(url: url, fileName: fileName)
        } else if fileExtension == "xlsx" || fileExtension == "xls" {
            processExcel(url: url, fileName: fileName)
        } else {
            print("Unsupported file type: \(fileExtension)")
        }
    }
    
    private func processCSV(url: URL, fileName: String) {
        do {
            let csvString = try String(contentsOf: url, encoding: .utf8)
            let rows = csvString.components(separatedBy: .newlines)
            
            print("CSV has \(rows.count) rows")
            
            // Add to your sheet files array
            let newSheet = SheetFile(id: UUID(), title: fileName)
            sheetfiles.append(newSheet)
            
            // Process the CSV data as needed
            // For example, get the first few rows:
            for (index, row) in rows.prefix(5).enumerated() {
                print("Row \(index): \(row)")
            }
            
        } catch {
            print("Error reading CSV: \(error)")
        }
    }
    
    private func processExcel(url: URL, fileName: String) {
        do {
            // Copy the file to a temporary location first
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            // Remove existing temp file if it exists
            try? FileManager.default.removeItem(at: tempURL)
            
            // Copy the file from source to temp location
            try FileManager.default.copyItem(at: url, to: tempURL)
            
            // Open the Excel file from temp location
            guard let file = XLSXFile(filepath: tempURL.path) else {
                print("Failed to open Excel file")
                return
            }
            
            // Get all worksheet paths
            let worksheetPaths = try file.parseWorksheetPaths()
            print("Found \(worksheetPaths.count) worksheets")
            
            // Process each worksheet
            for path in worksheetPaths {
                let worksheet = try file.parseWorksheet(at: path)
                
                print("\nWorksheet path: \(path)")
                
                // Get the shared strings (for text cells)
                let sharedStrings = try file.parseSharedStrings()
                
                // Process rows
                if let rows = worksheet.data?.rows {
                    print("Has \(rows.count) rows")
                    
                    // Print first few rows as example
                    for (rowIndex, row) in rows.prefix(5).enumerated() {
                        var rowValues: [String] = []
                        
                        for cell in row.cells {
                            // Handle optional sharedStrings
                            let cellValue: String
                            if let sharedStrings = sharedStrings {
                                cellValue = cell.stringValue(sharedStrings) ?? ""
                            } else {
                                cellValue = cell.value ?? ""
                            }
                            rowValues.append(cellValue)
                        }
                        
                        print("Row \(rowIndex): \(rowValues.joined(separator: ", "))")
                    }
                }
            }
            
            // Add to your sheet files array
            let newSheet = SheetFile(id: UUID(), title: fileName)
            sheetfiles.append(newSheet)
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Error reading Excel file: \(error)")
        }
    }
}
// MARK: - Preview
#Preview {
    HomeView()
}
