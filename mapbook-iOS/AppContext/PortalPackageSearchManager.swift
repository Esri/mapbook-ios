//// Copyright 2020 Gagandeep Singh
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ArcGIS

class PortalPackageSearchManager {
    
    private weak var portal: AGSPortal?
    
    init(_ portal: AGSPortal) {
        self.portal = portal
    }
    
    // MARK:- Errors
    
    struct AlreadyFinding: LocalizedError {
        let localizedDescription: String = "You are already finding portal items."
    }
    
    struct UnknownError: LocalizedError {
        let localizedDescription: String = "An unknown error occured."
    }
    
    // MARK:- Find Setup
    
    private var cancelableFind: AGSCancelable?
    
    private var finding: Bool = false
    
    struct FindParameters {
        var batchSize: Int
        var type: AGSPortalItemType
        var keyword: String?
    }

    // MARK:- Find Portal Items
    
    func findPortalItems(params: FindParameters, completion: @escaping (Result<[AGSPortalItem]?, Error>) -> Void) throws {
                
        guard portal != nil else { throw UnknownError() }

        guard !finding else { throw AlreadyFinding() }
        
        nextQueryParameters = nil

        let parameters = AGSPortalQueryParameters(forItemsOf: params.type, withSearch: params.keyword)
        parameters.limit = max(params.batchSize, 1)
        
        try performFind(with: parameters, completion: completion)
    }
    
    // MARK:- Find More Portal Items
    
    private var nextQueryParameters: AGSPortalQueryParameters?
    
    var canFindMorePortalItems: Bool {
        nextQueryParameters != nil
    }
    
    func findMorePortalItems(_ completion: @escaping (Result<[AGSPortalItem]?, Error>) -> Void) throws {
                  
        guard portal != nil else { throw UnknownError() }
        
        guard !finding else { throw AlreadyFinding() }
        
        guard let next = nextQueryParameters else {
            completion(.success([AGSPortalItem]()))
            return
        }
        
        try performFind(with: next, completion: completion)
    }
    
    // MARK:- Private, Peform Find
    
    private func performFind(with params: AGSPortalQueryParameters, completion: @escaping (Result<[AGSPortalItem]?, Error>) -> Void) throws {
        
        guard let portal = portal else { throw UnknownError() }

        finding = true
        
        cancelableFind?.cancel()
        
        cancelableFind = portal.findItems(with: params) { [weak self] (results, error) in

            guard let self = self else { return }
            
            defer {
                self.finding = false
            }
            
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            self.nextQueryParameters = results?.nextQueryParameters
            
            guard let results = results?.results as? [AGSPortalItem] else {
                completion(.success(nil))
                return
            }
            
            AGSLoadObjects(results) { (_) in
                completion(.success(results))
            }
        }
    }
    
    deinit {
        cancelableFind?.cancel()
    }
}
