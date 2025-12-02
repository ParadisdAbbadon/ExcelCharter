//
//  FullChartView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 28.11.25.
//

import SwiftUI
import Charts
import SwiftData

struct FullChartView: View {
    // MARK: - Properties
    let chartConfig: ChartConfiguration
    let sheetFile: SheetFile
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = ChartViewModel()
    @State private var showShareSheet = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var renderedImage: UIImage?
    @State private var isExporting = false
    
    var body: some View {
        // MARK: - Body
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart Info Card
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chartConfig.name)
                                        .font(.headline)
                                    Text(chartConfig.chartTypeEnum.rawValue)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: chartConfig.chartTypeEnum.systemImage)
                                    .font(.title)
                                    .foregroundStyle(Color(hex: chartConfig.chartColor))
                            }
                            
                            Divider()
                            
                            InfoRow(
                                label: "X-Axis",
                                value: chartConfig.xAxisLabel ?? viewModel.columnNames[safe: chartConfig.xAxisColumn] ?? "Unknown"
                            )
                            InfoRow(
                                label: "Y-Axis",
                                value: chartConfig.yAxisLabel ?? viewModel.columnNames[safe: chartConfig.yAxisColumn] ?? "Unknown"
                            )
                            InfoRow(
                                label: "Created",
                                value: chartConfig.dateCreated.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Main Chart
                    chartView
                        .frame(height: 400)
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 2)
                        .padding(.horizontal)
                        .overlay {
                            if isExporting {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                    
                                    ProgressView("Preparing to share...")
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.horizontal)
                            }
                        }
                }
                .padding(.vertical)
            }
            .navigationTitle(sheetFile.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
                
                // Direct share button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        shareChart()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(isExporting)
                }
                
                // More options menu
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit Chart", systemImage: "pencil")
                        }
                        
                        Button {
                            shareChart()
                        } label: {
                            Label("Share & Export", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Chart", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(isExporting)
                }
            }
            .onAppear {
                initializeViewModel()
            }
            .sheet(isPresented: $showEditSheet) {
                ChartConfigurationView(sheetFile: sheetFile, existingConfig: chartConfig)
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheet(
                        items: createShareItems(image: image),
                        onDismiss: {
                            // Haptic feedback on successful share
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    )
                }
            }
            .alert("Delete Chart", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteChart()
                }
            } message: {
                Text("Are you sure you want to delete '\(chartConfig.name)'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Chart View
    
    @ViewBuilder
    private var chartView: some View {
        let chartData = viewModel.prepareChartData(from: sheetFile.data ?? [])
        let xAxisLabel = chartConfig.xAxisLabel ?? (viewModel.columnNames[safe: chartConfig.xAxisColumn] ?? "X")
        let yAxisLabel = chartConfig.yAxisLabel ?? (viewModel.columnNames[safe: chartConfig.yAxisColumn] ?? "Y")
        let chartColor = Color(hex: chartConfig.chartColor)
        
        if chartData.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.bar.xaxis",
                description: Text("No valid data points to display")
            )
        } else {
            Chart(chartData) { point in
                switch chartConfig.chartTypeEnum {
                case .bar:
                    BarMark(
                        x: .value(xAxisLabel, point.x),
                        y: .value(yAxisLabel, point.y)
                    )
                    .foregroundStyle(chartColor.gradient)
                    .annotation(position: .top) {
                        if chartData.count <= 10 {
                            Text("\(point.y, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                case .line:
                    LineMark(
                        x: .value(xAxisLabel, point.x),
                        y: .value(yAxisLabel, point.y)
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(.circle)
                    .symbolSize(80)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value(xAxisLabel, point.x),
                        y: .value(yAxisLabel, point.y)
                    )
                    .foregroundStyle(chartColor.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                    
                case .point:
                    PointMark(
                        x: .value(xAxisLabel, point.x),
                        y: .value(yAxisLabel, point.y)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(120)
                    
                case .area:
                    AreaMark(
                        x: .value(xAxisLabel, point.x),
                        y: .value(yAxisLabel, point.y)
                    )
                    .foregroundStyle(chartColor.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value(xAxisLabel, point.x),
                        y: .value(yAxisLabel, point.y)
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(chartConfig.showGridLines ? .automatic : .hidden)
            .chartYAxis(chartConfig.showGridLines ? .automatic : .hidden)
            .chartLegend(chartConfig.showLegend ? .automatic : .hidden)
            .chartXAxisLabel(xAxisLabel)
            .chartYAxisLabel(yAxisLabel)
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeViewModel() {
        guard let data = sheetFile.data else { return }
        viewModel.initialize(with: data)
        viewModel.chartType = chartConfig.chartTypeEnum
        viewModel.xAxisColumn = chartConfig.xAxisColumn
        viewModel.yAxisColumn = chartConfig.yAxisColumn
        _ = viewModel.validateSelection(data: data)
    }
    
    private func shareChart() {
        isExporting = true
        
        // Render chart with slight delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let renderer = ImageRenderer(content: chartView.frame(width: 1200, height: 800))
            renderer.scale = 3.0
            
            if let image = renderer.uiImage {
                renderedImage = image
                isExporting = false
                showShareSheet = true
                
                // Haptic feedback when rendering completes
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } else {
                isExporting = false
                // Could show an error alert here
                print("Failed to render chart image")
            }
        }
    }
    
    private func createShareItems(image: UIImage) -> [Any] {
        // Create rich share content
        let chartInfo = """
        Chart: \(chartConfig.name)
        Type: \(chartConfig.chartTypeEnum.rawValue)
        Source: \(sheetFile.title)
        Created: \(chartConfig.dateCreated.formatted(date: .abbreviated, time: .omitted))
        
        Generated by ExcelCharter
        """
        
        return [image, chartInfo]
    }
    
    private func deleteChart() {
        modelContext.delete(chartConfig)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete chart: \(error)")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onDismiss: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onDismiss?()
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SheetFile.self, ChartConfiguration.self, configurations: config)
    
    let sheetFile = SheetFile(
        title: "Sample.csv",
        data: [
            ["Month", "Sales", "Expenses"],
            ["January", "1000", "500"],
            ["February", "1500", "600"],
            ["March", "1200", "550"],
            ["April", "1800", "700"],
            ["May", "2000", "750"]
        ],
        fileExtension: "csv"
    )
    
    let chartConfig = ChartConfiguration(
        name: "Monthly Sales Chart",
        chartType: .bar,
        xAxisColumn: 0,
        yAxisColumn: 1,
        chartColor: "#007AFF"
    )
    chartConfig.sheetFile = sheetFile
    
    container.mainContext.insert(sheetFile)
    container.mainContext.insert(chartConfig)
    
    return FullChartView(chartConfig: chartConfig, sheetFile: sheetFile)
        .modelContainer(container)
}
