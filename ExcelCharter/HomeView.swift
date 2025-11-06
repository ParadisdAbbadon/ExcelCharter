//
//  ContentView.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    private class FileReference { }
    
    let sheetfiles = [
            SheetFile(id: ObjectIdentifier(FileReference()), title: "Sheet 1"),
            SheetFile(id: ObjectIdentifier(FileReference()), title: "Sheet 2"),
            SheetFile(id: ObjectIdentifier(FileReference()), title: "Sheet 3")
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
        }
        .navigationTitle("Home")
        .listStyle(.plain)
    }
}
// MARK: - Preview
#Preview {
    HomeView()
}
