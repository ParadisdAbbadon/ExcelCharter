//
//  SheetFile.swift
//  ExcelCharter
//
//  Created by Paradis d'Abbadon on 05.11.25.
//
//  Model detailing how .csv file
//  data will be handled when imported
//

import Foundation

struct SheetFile: Identifiable {
    let id: UUID
    var title: String
    var url: URL?
    var data: [[String]]? 
}
