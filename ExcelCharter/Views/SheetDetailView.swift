//
//  SheetDetailView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 17.11.25.
//

import SwiftUI
import SwiftData

struct SheetDetailView: View {
    let sheetFile: SheetFile
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // File Info Section
                GroupBox("File Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Name", value: sheetFile.title)
                        InfoRow(label: "Type", value: sheetFile.fileExtension.uppercased())
                        InfoRow(label: "Imported", value: sheetFile.dateImported.formatted(date: .long, time: .shortened))
                        
                        if let data = sheetFile.data {
                            InfoRow(label: "Rows", value: "\(data.count)")
                            if let firstRow = data.first {
                                InfoRow(label: "Columns", value: "\(firstRow.count)")
                            }
                        }
                    }
                }
                
                // Data Preview Section
                if let data = sheetFile.data, !data.isEmpty {
                    GroupBox("Data Preview") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(data.prefix(10).enumerated()), id: \.offset) { index, row in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Row \(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(row.joined(separator: " | "))
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(2)
                                }
                                
                                if index < min(9, data.count - 1) {
                                    Divider()
                                }
                            }
                            
                            if data.count > 10 {
                                Text("... and \(data.count - 10) more rows")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                
                // Chart Section (Placeholder for future implementation)
                GroupBox("Visualization") {
                    VStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("Chart visualization coming soon")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("You'll be able to visualize your data using Apple Charts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
        .navigationTitle(sheetFile.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

#Preview {
    NavigationStack {
        SheetDetailView(
            sheetFile: SheetFile(
                title: "Sample.csv",
                data: [
                    ["Name", "Age", "City"],
                    ["John", "25", "New York"],
                    ["Jane", "30", "Los Angeles"]
                ],
                fileExtension: "csv"
            )
        )
    }
}
