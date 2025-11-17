//
//  ContentView.swift
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
    
    var body: some View {
        // MARK: - Body
        NavigationStack {
            List {
                ForEach(sheetFiles) { sheetfile in
                    NavigationLink {
                        SheetDetailView(sheetFile: sheetfile)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sheetfile.title)
                                .font(.title2)
                            
                            HStack {
                                Text(sheetfile.fileExtension.uppercased())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text(sheetfile.dateImported, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteFiles)
            }
            .navigationTitle("Home")
            .listStyle(.plain)
            .overlay {
                if sheetFiles.isEmpty {
                    ContentUnavailableView {
                        Label("No Files", systemImage: "doc.fill")
                    } description: {
                        Text("Import a CSV or Excel file to get started")
                    }
                }
            }
        }
        
        HStack {
            Button(action: {
                print("search button tapped")
            }) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .frame(width: 20, height: 22)
            }
            .buttonStyle(.borderedProminent)
            .shadow(radius: 5)
            .tint(.gray)
            
            Button("Add File") {
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
            handleFileImport(result: result)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
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
        for index in offsets {
            let sheetFile = sheetFiles[index]
            viewModel.removeFile(sheetFile)
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .modelContainer(for: SheetFile.self, inMemory: true)
}
