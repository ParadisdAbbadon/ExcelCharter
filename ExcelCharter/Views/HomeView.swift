//
//  ContentView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    ///@State variables
    @State private var showNewFileView = false
    
    ///Array of test files
    let sheetfiles = [
            SheetFile(id: UUID(), title: "Sheet 1"),
            SheetFile(id: UUID(), title: "Sheet 2"),
            SheetFile(id: UUID(), title: "Sheet 3")
        ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack{
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
        HStack{
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
            .tint(.gray)
            
        
            Button("Add File") {
                showNewFileView = true
            }
            .buttonStyle(.borderedProminent)
            .bold()
        }
        .sheet(isPresented: $showNewFileView) {
            NewFileView()
        }
    }
}
// MARK: - Preview
#Preview {
    HomeView()
}
