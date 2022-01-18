//
//  ApiResponse.swift
//  MapTeam
//
//  Created by etudiant on 18/01/2022.
//

import Foundation

struct ApiResponse: Codable{
    let nom: String
    let code: String
    //let codePostaux: [String]?
    let codeDepartement: String
    let codeRegion: String
    let population: Int
    }
