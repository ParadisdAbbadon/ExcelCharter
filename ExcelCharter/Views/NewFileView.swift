//
//  NewFileView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//
//  Will display small popup window prompting user to
//  name imported file. Also accesses Filesystem to
//  locate .csv files to import.
//

import SwiftUI
import UniformTypeIdentifiers

struct NewFileView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var newFileName: String = ""
    @State private var showFileImporter = false
    @FocusState private var newFileFieldIsFocused: Bool
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("File Name", text: $newFileName)
                    .focused($newFileFieldIsFocused)
                    .onSubmit {
                        saveFile()
                    }
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                HStack {
                    ///This HStack is temporary.
                    Text("File will be saved as: ")
                        .padding([.trailing], 130)
                    
                    Text("\(newFileName).csv")
                        .foregroundColor(newFileFieldIsFocused ? .blue : .gray)
                }
                
                Spacer()
                
                HStack {
                    ///Button to open file importer
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Choose File to Import", systemImage: "tray.and.arrow.down")
                    }
                }
            }
            .navigationTitle("Add New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFile()
                    }
                    .disabled(newFileName.isEmpty)
                }
            }
        }
        .onAppear {
            newFileFieldIsFocused = true
        }
    }
        
    // MARK: - Helper Methods
    private func saveFile() {
        guard !newFileName.isEmpty else { return }
        // Add save logic here
        print("Saving file: \(newFileName)")
        dismiss()
    }
}

#Preview {
    NewFileView()
}
