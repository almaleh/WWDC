//
//  ASCIISearchManager.swift
//  WWDC
//
//  Created by Besher Al Maleh on 2020-05-20.
//  Copyright © 2020 Guilherme Rambo. All rights reserved.
//

import AppKit

enum ASCIIResultError: Error {
    case connectionError, invalidQuery
    case invalidData(message: String?)
    case invalidResponse(statusCode: Int?)
    case other(message: String)
}

final class ASCIISearchManager {
    
    static let shared = ASCIISearchManager()
    private let cache = NSCache<NSString, ASCIICachedResults>()
    private let cacheQueue = DispatchQueue(label: "io.wwdc.ascii.cache")
    private let baseURL = "https://asciiwwdc.com/search?q="
    
    private init() {}
    
    func search(for query: String, completion: @escaping (Result<ASCIIResults, ASCIIResultError>) -> Void) {
        
        cacheQueue.sync {
            if let cachedResults = cache.object(forKey: NSString(string: query)) {
                completion(.success(cachedResults.results))
                return
            }
        }
        
        // TODO: dispatchItem
        
        let endpoint = baseURL + "\(query)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidQuery))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                let nsError = error as NSError
                
                if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorNotConnectedToInternet {
                    completion(.failure(.connectionError))
                } else {
                    completion(.failure(.other(message: error.localizedDescription)))
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse(statusCode: nil)))
                return
            }
            
            guard response.statusCode == 200 else {
                completion(.failure(.invalidResponse(statusCode: response.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidData(message: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let results = try decoder.decode(ASCIIResults.self, from: data)
                completion(.success(results))
                self.cacheQueue.async {
                    self.cache.setObject(ASCIICachedResults(results: results), forKey: NSString(string: query))
                }
            } catch {
                completion(.failure(.invalidData(message: error.localizedDescription)))
            }
        }
        
        task.resume()
    }
}
