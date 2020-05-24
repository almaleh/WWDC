//
//  ASCIIResult.swift
//  WWDC
//
//  Created by Besher Al Maleh on 2020-05-20.
//  Copyright © 2020 Guilherme Rambo. All rights reserved.
//

import Foundation

struct ASCIIResults: Codable {
    
    struct Result: Codable {
        let title: String
        let description: String
        let year: Int
        let number: Int
        let rank: Int
        let excerpt: String
    }
    
    let query: String
    let results: [Result]
    
}

// Used for NSCache
class ASCIICachedResults {
    let results: ASCIIResults
    
    init(results: ASCIIResults) {
        self.results = results
    }
}
