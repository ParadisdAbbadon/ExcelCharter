//
//  SheetDetailView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//

import SwiftUI
import SwiftData

struct SheetDetailView: View {
    let sheetFile: SheetFile
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allChartConfigs: [ChartConfiguration]
    
    @State private var showChartConfig = false
    
    // Filter charts for this specific sheet file
    private var chartConfigs: [ChartConfiguration] {
        allChartConfigs.filter { $0.sheetFile?.id == sheetFile.id }
    }
    
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
                
                // Charts Section
                GroupBox("Charts") {
                    if chartConfigs.isEmpty {
                        // No charts yet - show create button
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                            
                            Text("No charts created yet")
                                .font(.headline)
                            
                            Text("Create a chart to visualize your data")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                showChartConfig = true
                            } label: {
                                Label("Create Chart", systemImage: "plus.circle.fill")
                                    .font(.body)
                                    .bold()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        // Show existing charts
                        VStack(spacing: 12) {
                            ForEach(chartConfigs) { config in
                                ChartConfigRow(
                                    config: config,
                                    sheetFile: sheetFile
                                )
                            }
                            
                            // Add another chart button
                            Button {
                                showChartConfig = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Another Chart")
                                    Spacer()
                                }
                                .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(sheetFile.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChartConfig) {
            ChartConfigurationView(sheetFile: sheetFile)
        }
    }
}

// MARK: - Chart Config Row

struct ChartConfigRow: View {
    let config: ChartConfiguration
    let sheetFile: SheetFile
    
    @State private var showFullChart = false
    
    var body: some View {
        Button {
            showFullChart = true
        } label: {
            HStack(spacing: 12) {
                // Chart icon with color
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: config.chartColor).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: config.chartTypeEnum.systemImage)
                        .font(.title3)
                        .foregroundStyle(Color(hex: config.chartColor))
                }
                
                // Chart info
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .font(.body)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text(config.chartTypeEnum.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFullChart) {
            FullChartView(chartConfig: config, sheetFile: sheetFile)
        }
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SheetFile.self, ChartConfiguration.self, configurations: config)
    
    let sheetFile = SheetFile(
        title: "Sample.csv",
        data: [
            ["Name", "Age", "City"],
            ["John", "25", "New York"],
            ["Jane", "30", "Los Angeles"]
        ],
        fileExtension: "csv"
    )
    
    container.mainContext.insert(sheetFile)
    
    return NavigationStack {
        SheetDetailView(sheetFile: sheetFile)
    }
    .modelContainer(container)
}
