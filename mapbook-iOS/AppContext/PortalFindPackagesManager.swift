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

class PortalFindPackagesManager {
    
    private weak var portal: AGSPortal?
    
    init(_ portal: AGSPortal) {
        self.portal = portal
    }
    
    struct AlreadyFinding: LocalizedError {
        let localizedDescription: String = "You are already finding portal items."
    }
    
    struct UnknownError: LocalizedError {
        let localizedDescription: String = "An unknown error occured."
    }
    
    private var cancelableFind: AGSCancelable?
    
    private var finding: Bool = false

    func findPortalItems(keyword: String?, n: Int, completion: @escaping (Result<[AGSPortalItem]?, Error>) -> Void) throws {
                
        guard let portal = portal else { throw UnknownError() }

        guard !finding else { throw AlreadyFinding() }
        
        finding = true
        
        nextQueryParameters = nil

        cancelableFind?.cancel()

        let parameters = AGSPortalQueryParameters(forItemsOf: .mobileMapPackage, withSearch: keyword)
        parameters.limit = max(n, 1)

        cancelableFind = portal.findItems(with: parameters) { [weak self] (results, error) in

            guard let self = self else { return }
            
            defer {
                self.finding = false
            }
            
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            self.nextQueryParameters = results?.nextQueryParameters

            completion(.success(results?.results as? [AGSPortalItem]))
        }
    }
    
    private var nextQueryParameters: AGSPortalQueryParameters?
    
    var canFindMorePortalItems: Bool {
        nextQueryParameters != nil
    }
    
    func findMorePortalItems(_ completion: @escaping (Result<[AGSPortalItem]?, Error>) -> Void) throws {
                        
        guard let portal = portal else { throw UnknownError() }

        guard !finding else { throw AlreadyFinding() }
        
        guard let next = nextQueryParameters else {
            completion(.success([AGSPortalItem]()))
            return
        }
        
        finding = true
        
        cancelableFind?.cancel()
        
        cancelableFind = portal.findItems(with: next) { [weak self] (results, error) in

            guard let self = self else { return }
            
            defer {
                self.finding = false
            }
            
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            self.nextQueryParameters = results?.nextQueryParameters

            completion(.success(results?.results as? [AGSPortalItem]))
        }
    }
    
    deinit {
        cancelableFind?.cancel()
    }
}
