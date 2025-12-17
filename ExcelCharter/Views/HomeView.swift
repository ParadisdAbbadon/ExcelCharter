//
//  HomeView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SheetFile.dateImported, order: .reverse) private var sheetFiles: [SheetFile]
    
    @State private var viewModel = FileImportViewModel()
    @State private var showFileImporter = false
    @State private var searchText = ""
    @State private var isSearching = false
    
    // MARK: - Computed Properties
    
    /// Filtered files based on search text
    private var filteredFiles: [SheetFile] {
        guard !searchText.isEmpty else {
            return sheetFiles
        }
        
        let lowercasedSearch = searchText.lowercased()
        
        return sheetFiles.filter { file in
            // Search by file name
            if file.title.lowercased().contains(lowercasedSearch) {
                return true
            }
            
            // Search by file extension
            if file.fileExtension.lowercased().contains(lowercasedSearch) {
                return true
            }
            
            // Search within data content (column headers)
            if let data = file.data, let headers = data.first {
                if headers.contains(where: { $0.lowercased().contains(lowercasedSearch) }) {
                    return true
                }
            }
            
            return false
        }
    }
    
    /// Check if we have search results
    private var hasNoSearchResults: Bool {
        !searchText.isEmpty && filteredFiles.isEmpty
    }
    
    var body: some View {
        // MARK: - Body
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar (shown when searching)
                if isSearching {
                    SearchBar(
                        text: $searchText,
                        isSearching: $isSearching,
                        placeholder: "Search files..."
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // File list
                List {
                    ForEach(filteredFiles) { sheetfile in
                        NavigationLink {
                            SheetDetailView(sheetFile: sheetfile)
                        } label: {
                            FileRowView(
                                sheetFile: sheetfile,
                                searchText: searchText
                            )
                        }
                    }
                    .onDelete(perform: deleteFiles)
                }
                .listStyle(.plain)
                .overlay {
                    // Empty states
                    if sheetFiles.isEmpty {
                        ContentUnavailableView {
                            Label("No Files", systemImage: "doc.fill")
                        } description: {
                            Text("Import a CSV or Excel file to get started")
                        }
                    } else if hasNoSearchResults {
                        ContentUnavailableView {
                            Label("No Results", systemImage: "magnifyingglass")
                        } description: {
                            Text("No files match '\(searchText)'")
                        } actions: {
                            Button("Clear Search") {
                                withAnimation {
                                    searchText = ""
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .safeAreaInset(edge: .bottom) {
                bottomToolbar
            }
            .animation(.easeInOut(duration: 0.25), value: isSearching)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            // Search button
            Button {
                withAnimation {
                    isSearching.toggle()
                    if !isSearching {
                        searchText = ""
                    }
                }
            } label: {
                Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderedProminent)
            .tint(isSearching ? .red : .gray)
            .shadow(radius: 5)
            
            // Add file button
            Button {
                showFileImporter = true
            } label: {
                Label("Add File", systemImage: "plus")
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .shadow(radius: 5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Methods
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                print("Couldn't access file")
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            viewModel.importFile(from: url)
            
        case .failure(let error):
            print("File import error: \(error.localizedDescription)")
        }
    }
    
    private func deleteFiles(at offsets: IndexSet) {
        // Map offsets from filtered list to actual files
        let filesToDelete = offsets.map { filteredFiles[$0] }
        
        for sheetFile in filesToDelete {
            viewModel.removeFile(sheetFile)
        }
    }
}

// MARK: - Search Bar Component

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    let placeholder: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .submitLabel(.search)
                
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Button("Cancel") {
                withAnimation {
                    text = ""
                    isSearching = false
                    isFocused = false
                }
            }
            .foregroundStyle(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - File Row View

struct FileRowView: View {
    let sheetFile: SheetFile
    let searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title with optional highlight
            if searchText.isEmpty {
                Text(sheetFile.title)
                    .font(.headline)
            } else {
                HighlightedText(
                    text: sheetFile.title,
                    highlight: searchText
                )
                .font(.headline)
            }
            
            HStack {
                // File type badge
                Text(sheetFile.fileExtension.uppercased())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(fileTypeBadgeColor.opacity(0.15))
                    .foregroundStyle(fileTypeBadgeColor)
                    .clipShape(Capsule())
                
                // Column count if available
                if let data = sheetFile.data, let firstRow = data.first {
                    Label("\(firstRow.count) cols", systemImage: "tablecells")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Row count if available
                if let data = sheetFile.data {
                    Label("\(max(0, data.count - 1)) rows", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Date
                Text(sheetFile.dateImported, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Show matching column headers if searching
            if !searchText.isEmpty, let matchingHeaders = matchingColumnHeaders {
                HStack(spacing: 4) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.caption2)
                    Text("Columns: \(matchingHeaders)")
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Properties
    
    private var fileTypeBadgeColor: Color {
        switch sheetFile.fileExtension.lowercased() {
        case "csv":
            return .green
        case "xlsx", "xls":
            return .blue
        default:
            return .gray
        }
    }
    
    private var matchingColumnHeaders: String? {
        guard !searchText.isEmpty,
              let data = sheetFile.data,
              let headers = data.first else {
            return nil
        }
        
        let lowercasedSearch = searchText.lowercased()
        let matching = headers.filter { $0.lowercased().contains(lowercasedSearch) }
        
        guard !matching.isEmpty,
              !sheetFile.title.lowercased().contains(lowercasedSearch) else {
            return nil
        }
        
        return matching.joined(separator: ", ")
    }
}

// MARK: - Highlighted Text Component

struct HighlightedText: View {
    let text: String
    let highlight: String
    
    var body: some View {
        if highlight.isEmpty {
            Text(text)
        } else {
            Text(attributedString)
        }
    }
    
    private var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        
        let lowercasedText = text.lowercased()
        let lowercasedHighlight = highlight.lowercased()
        
        var searchStartIndex = lowercasedText.startIndex
        
        while let range = lowercasedText.range(of: lowercasedHighlight, range: searchStartIndex..<lowercasedText.endIndex) {
            // Convert String range to AttributedString range
            let startDistance = lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound)
            let endDistance = lowercasedText.distance(from: lowercasedText.startIndex, to: range.upperBound)
            
            let attrStart = attributedString.index(attributedString.startIndex, offsetByCharacters: startDistance)
            let attrEnd = attributedString.index(attributedString.startIndex, offsetByCharacters: endDistance)
            
            attributedString[attrStart..<attrEnd].backgroundColor = .yellow.opacity(0.3)
            attributedString[attrStart..<attrEnd].foregroundColor = .primary
            
            searchStartIndex = range.upperBound
        }
        
        return attributedString
    }
}

// MARK: - Preview

#Preview("With Files") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SheetFile.self, ChartConfiguration.self, configurations: config)
    
    // Add sample files
    let sampleFiles = [
        SheetFile(
            title: "Sales_Report_2024.csv",
            data: [
                ["Month", "Revenue", "Expenses", "Profit"],
                ["January", "10000", "5000", "5000"],
                ["February", "12000", "5500", "6500"]
            ],
            fileExtension: "csv"
        ),
        SheetFile(
            title: "Employee_Data.xlsx",
            data: [
                ["Name", "Department", "Salary"],
                ["John Doe", "Engineering", "75000"],
                ["Jane Smith", "Marketing", "65000"]
            ],
            fileExtension: "xlsx"
        ),
        SheetFile(
            title: "Inventory_Q4.csv",
            data: [
                ["Product", "Quantity", "Price"],
                ["Widget A", "100", "25.99"],
                ["Widget B", "50", "49.99"]
            ],
            fileExtension: "csv"
        )
    ]
    
    for file in sampleFiles {
        container.mainContext.insert(file)
    }
    
    return HomeView()
        .modelContainer(container)
}

#Preview("Empty State") {
    HomeView()
        .modelContainer(for: SheetFile.self, inMemory: true)
}
