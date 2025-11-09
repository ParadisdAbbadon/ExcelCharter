//
//  ContentView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    // MARK: - Properties
    ///@State variables
    @State private var showNewFileView = false //May be unnecessary
    @State private var showFileImporter = false
    
    ///Array of test files
    let sheetfiles = [
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
                
                // Process your file here
                print("Selected file: \(url.lastPathComponent)")
                // Add your file processing logic
            }
        }
// MARK: - Preview
#Preview {
    HomeView()
}
