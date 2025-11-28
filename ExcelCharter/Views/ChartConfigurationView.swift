//
//  ChartConfigurationView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 28.11.25.
//

import SwiftUI
import Charts
import SwiftData

struct ChartConfigurationView: View {
    // MARK: - Properties
    let sheetFile: SheetFile
    let existingConfig: ChartConfiguration?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = ChartViewModel()
    @State private var showChart = false
    @State private var showCustomization = false
    @State private var chartName = ""
    
    // Customization properties
    @State private var selectedColor: Color = .blue
    @State private var showLegend = true
    @State private var showGridLines = true
    @State private var customXAxisLabel = ""
    @State private var customYAxisLabel = ""
    
    init(sheetFile: SheetFile, existingConfig: ChartConfiguration? = nil) {
        self.sheetFile = sheetFile
        self.existingConfig = existingConfig
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Chart Name
                Section {
                    TextField("Chart Name", text: $chartName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your chart a descriptive name")
                }
                
                // MARK: - Chart Type Selection
                Section {
                    Picker("Chart Type", selection: $viewModel.chartType) {
                        ForEach(ChartType.allCases) { type in
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.rawValue)
                                        .font(.body)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: type.systemImage)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Chart Type")
                } footer: {
                    Text("Select how you want to visualize your data")
                }
                
                // MARK: - X-Axis Configuration
                Section {
                    Picker("Column", selection: $viewModel.xAxisColumn) {
                        ForEach(viewModel.columnNames.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.columnNames[index])
                                    .font(.body)
                                Text(viewModel.getColumnTypeDescription(columnIndex: index))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(index)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: viewModel.xAxisColumn) { _, _ in
                        validateData()
                    }
                    
                    // Preview of X-axis data
                    if !viewModel.columnNames.isEmpty && viewModel.columnNames.indices.contains(viewModel.xAxisColumn) {
                        ColumnPreviewRow(
                            title: "Preview",
                            values: viewModel.getColumnPreview(
                                data: sheetFile.data ?? [],
                                columnIndex: viewModel.xAxisColumn
                            )
                        )
                    }
                } header: {
                    HStack {
                        Text("X-Axis (Categories)")
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } footer: {
                    Text("Choose the column for horizontal axis labels")
                }
                
                // MARK: - Y-Axis Configuration
                Section {
                    Picker("Column", selection: $viewModel.yAxisColumn) {
                        ForEach(viewModel.columnNames.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.columnNames[index])
                                        .font(.body)
                                    Text(viewModel.getColumnTypeDescription(columnIndex: index))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // Show indicator if column is not numeric
                                if !viewModel.isColumnValidForYAxis(columnIndex: index) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                }
                            }
                            .tag(index)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: viewModel.yAxisColumn) { _, _ in
                        validateData()
                    }
                    
                    // Preview of Y-axis data
                    if !viewModel.columnNames.isEmpty && viewModel.columnNames.indices.contains(viewModel.yAxisColumn) {
                        ColumnPreviewRow(
                            title: "Preview",
                            values: viewModel.getColumnPreview(
                                data: sheetFile.data ?? [],
                                columnIndex: viewModel.yAxisColumn
                            )
                        )
                    }
                } header: {
                    HStack {
                        Text("Y-Axis (Values)")
                        Spacer()
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } footer: {
                    Text("Choose the column with numeric values to plot")
                }
                
                // MARK: - Customization Button
                if viewModel.isDataValid {
                    Section {
                        Button {
                            showCustomization = true
                        } label: {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                Text("Customize Appearance")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // MARK: - Validation Status
                Section {
                    if let errorMessage = viewModel.errorMessage {
                        Label {
                            Text(errorMessage)
                                .font(.callout)
                        } icon: {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    } else if viewModel.isDataValid {
                        Label {
                            Text("Configuration is valid")
                                .font(.callout)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        
                        // Show data point count
                        let dataPoints = viewModel.prepareChartData(from: sheetFile.data ?? [])
                        HStack {
                            Text("Data Points")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(dataPoints.count)")
                                .bold()
                        }
                    }
                }
                
                // MARK: - Chart Preview Section
                if viewModel.isDataValid {
                    Section {
                        ChartPreviewView(
                            viewModel: viewModel,
                            data: sheetFile.data ?? [],
                            customColor: selectedColor,
                            showLegend: showLegend,
                            showGridLines: showGridLines,
                            customXLabel: customXAxisLabel.isEmpty ? nil : customXAxisLabel,
                            customYLabel: customYAxisLabel.isEmpty ? nil : customYAxisLabel
                        )
                        .frame(height: 250)
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .navigationTitle(existingConfig == nil ? "New Chart" : "Edit Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingConfig == nil ? "Save" : "Update") {
                        saveChart()
                    }
                    .disabled(!viewModel.isDataValid || chartName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
            .onAppear {
                initializeViewModel()
            }
            .sheet(isPresented: $showCustomization) {
                ChartCustomizationView(
                    selectedColor: $selectedColor,
                    showLegend: $showLegend,
                    showGridLines: $showGridLines,
                    customXAxisLabel: $customXAxisLabel,
                    customYAxisLabel: $customYAxisLabel,
                    defaultXLabel: viewModel.columnNames.indices.contains(viewModel.xAxisColumn)
                        ? viewModel.columnNames[viewModel.xAxisColumn]
                        : "X",
                    defaultYLabel: viewModel.columnNames.indices.contains(viewModel.yAxisColumn)
                        ? viewModel.columnNames[viewModel.yAxisColumn]
                        : "Y"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeViewModel() {
        guard let data = sheetFile.data else { return }
        viewModel.initialize(with: data)
        
        // Load existing configuration if editing
        if let config = existingConfig {
            chartName = config.name
            viewModel.chartType = config.chartTypeEnum
            viewModel.xAxisColumn = config.xAxisColumn
            viewModel.yAxisColumn = config.yAxisColumn
            selectedColor = Color(hex: config.chartColor)
            showLegend = config.showLegend
            showGridLines = config.showGridLines
            customXAxisLabel = config.xAxisLabel ?? ""
            customYAxisLabel = config.yAxisLabel ?? ""
        } else {
            // Generate default name for new chart
            chartName = "\(viewModel.chartType.rawValue) - \(Date().formatted(date: .abbreviated, time: .omitted))"
        }
        
        validateData()
    }
    
    private func validateData() {
        guard let data = sheetFile.data else { return }
        _ = viewModel.validateSelection(data: data)
    }
    
    private func saveChart() {
        let config: ChartConfiguration
        
        if let existing = existingConfig {
            // Update existing configuration
            existing.name = chartName
            existing.chartType = viewModel.chartType.rawValue
            existing.xAxisColumn = viewModel.xAxisColumn
            existing.yAxisColumn = viewModel.yAxisColumn
            existing.chartColor = selectedColor.toHex()
            existing.showLegend = showLegend
            existing.showGridLines = showGridLines
            existing.xAxisLabel = customXAxisLabel.isEmpty ? nil : customXAxisLabel
            existing.yAxisLabel = customYAxisLabel.isEmpty ? nil : customYAxisLabel
        } else {
            // Create new configuration
            config = ChartConfiguration(
                name: chartName,
                chartType: viewModel.chartType,
                xAxisColumn: viewModel.xAxisColumn,
                yAxisColumn: viewModel.yAxisColumn,
                chartColor: selectedColor.toHex(),
                showLegend: showLegend,
                showGridLines: showGridLines,
                xAxisLabel: customXAxisLabel.isEmpty ? nil : customXAxisLabel,
                yAxisLabel: customYAxisLabel.isEmpty ? nil : customYAxisLabel
            )
            config.sheetFile = sheetFile
            modelContext.insert(config)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save chart configuration: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ColumnPreviewRow: View {
    let title: String
    let values: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if values.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                Text(values.joined(separator: ", "))
                    .font(.caption)
                    .lineLimit(2)
            }
        }
    }
}

struct ChartPreviewView: View {
    let viewModel: ChartViewModel
    let data: [[String]]
    var customColor: Color = .blue
    var showLegend: Bool = true
    var showGridLines: Bool = true
    var customXLabel: String? = nil
    var customYLabel: String? = nil
    
    var body: some View {
        let chartData = viewModel.prepareChartData(from: data)
        let xAxisLabel = customXLabel ?? (viewModel.columnNames.indices.contains(viewModel.xAxisColumn)
            ? viewModel.columnNames[viewModel.xAxisColumn]
            : "X")
        let yAxisLabel = customYLabel ?? (viewModel.columnNames.indices.contains(viewModel.yAxisColumn)
            ? viewModel.columnNames[viewModel.yAxisColumn]
            : "Y")
        
        VStack {
            if chartData.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.bar.xaxis",
                    description: Text("No valid data points to display")
                )
            } else {
                Chart(chartData) { point in
                    switch viewModel.chartType {
                    case .bar:
                        BarMark(
                            x: .value(xAxisLabel, point.x),
                            y: .value(yAxisLabel, point.y)
                        )
                        .foregroundStyle(customColor.gradient)
                        
                    case .line:
                        LineMark(
                            x: .value(xAxisLabel, point.x),
                            y: .value(yAxisLabel, point.y)
                        )
                        .foregroundStyle(customColor)
                        .symbol(.circle)
                        .interpolationMethod(.catmullRom)
                        
                    case .point:
                        PointMark(
                            x: .value(xAxisLabel, point.x),
                            y: .value(yAxisLabel, point.y)
                        )
                        .foregroundStyle(customColor)
                        .symbolSize(100)
                        
                    case .area:
                        AreaMark(
                            x: .value(xAxisLabel, point.x),
                            y: .value(yAxisLabel, point.y)
                        )
                        .foregroundStyle(customColor.gradient)
                    }
                }
                .chartXAxis(showGridLines ? .automatic : .hidden)
                .chartYAxis(showGridLines ? .automatic : .hidden)
                .chartLegend(showLegend ? .automatic : .hidden)
            }
        }
        .padding()
    }
}

struct ChartCustomizationView: View {
    @Binding var selectedColor: Color
    @Binding var showLegend: Bool
    @Binding var showGridLines: Bool
    @Binding var customXAxisLabel: String
    @Binding var customYAxisLabel: String
    
    let defaultXLabel: String
    let defaultYLabel: String
    
    @Environment(\.dismiss) private var dismiss
    
    let presetColors: [Color] = [
        .blue, .green, .red, .orange, .purple, .pink, .cyan, .indigo, .mint, .teal
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Color Selection
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(presetColors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if selectedColor == color {
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: 3)
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.white)
                                                    .bold()
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Chart Color")
                } footer: {
                    Text("Select a color for your chart")
                }
                
                // MARK: - Axis Labels
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("X-Axis Label", text: $customXAxisLabel)
                        Text("Default: \(defaultXLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Y-Axis Label", text: $customYAxisLabel)
                        Text("Default: \(defaultYLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Axis Labels")
                } footer: {
                    Text("Leave empty to use column names")
                }
                
                // MARK: - Display Options
                Section {
                    Toggle("Show Legend", isOn: $showLegend)
                    Toggle("Show Grid Lines", isOn: $showGridLines)
                } header: {
                    Text("Display Options")
                }
            }
            .navigationTitle("Customize Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 255)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    ChartConfigurationView(
        sheetFile: SheetFile(
            title: "Sample.csv",
            data: [
                ["Month", "Sales", "Expenses"],
                ["January", "1000", "500"],
                ["February", "1500", "600"],
                ["March", "1200", "550"],
                ["April", "1800", "700"]
            ],
            fileExtension: "csv"
        )
    )
    .modelContainer(for: [SheetFile.self, ChartConfiguration.self], inMemory: true)
}
