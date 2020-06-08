//
// Copyright 2017 Esri.
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
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts Dept
// 380 New York Street
// Redlands, California, USA 92373
//
// email: contracts@esri.com
//

import UIKit
import ArcGIS

protocol SearchViewControllerDelegate: class {
    func searchViewController(_ searchViewController:LocatorSearchSuggestionController, didFindGeocodeResults geocodeResults:[AGSGeocodeResult])
}

class LocatorSearchSuggestionController: UITableViewController {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func fromStoryboard() -> Self {
        UIStoryboard(name: "Search", bundle: nil)
            .instantiateViewController(withIdentifier: "SearchResultsViewController") as! Self
    }
        
    var locatorTask: AGSLocatorTask!
    
    weak var delegate: SearchViewControllerDelegate?
    
    // MARK:- Suggestions
    
    fileprivate var suggestResults = [AGSSuggestResult]()

    private var suggestCancelable: AGSCancelable?

    /**
     Get suggestions for text. The method cancels any previous request.
     And on successful completion the results are shown in the table
     view.
    */
    fileprivate func suggestions(for text:String) {
        
        guard locatorTask != nil else {
            preconditionFailure("LocatorTask must not be nil.")
        }
        
        //cancel previous request
        suggestCancelable?.cancel()
        
        let params: AGSSuggestParameters = {
            let suggestParameters = AGSSuggestParameters()
            suggestParameters.maxResults = AppSettings.locatorSearchSuggestionSize ?? 12
            return suggestParameters
        }()
    
        suggestCancelable = locatorTask.suggest(withSearchText: text, parameters: params) { [weak self] (suggestResults, error) in
            
            guard let self = self else { return }
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    flash(error: error)
                }
                return
            }
            
            guard let suggestResults = suggestResults else {
                print("No suggestions")
                return
            }
            
            self.suggestResults = suggestResults
            self.tableView.reloadData()
        }
    }
    
    // MARK:- Geocode
    
    private var geocodeCancelable: AGSCancelable?
    
    /**
     Geocode location for suggest result. Called when the user
     selects a suggestion. The delegate is notified of the results.
    */
    fileprivate func geocode(for suggestResult:AGSSuggestResult) {
        
        guard locatorTask != nil else {
            preconditionFailure("LocatorTask must not be nil.")
        }
        
        geocodeCancelable?.cancel()
        geocodeCancelable = locatorTask.geocode(with: suggestResult) { [weak self] (geocodeResults, error) in
            guard let self = self else { return }
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    flash(error: error)
                }
                return
            }
            
            self.delegate?.searchViewController(self, didFindGeocodeResults: geocodeResults ?? [])
        }
    }
}

extension LocatorSearchSuggestionController /* UITableViewDataSource */ {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestResultCell", for: indexPath)
        let suggestResult = suggestResults[indexPath.row]
        cell.textLabel?.text = suggestResult.label
        return cell
    }
}

extension LocatorSearchSuggestionController /* UITableViewDelegate */ {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let suggestResult = suggestResults[indexPath.row]
        geocode(for: suggestResult)
    }
}

extension LocatorSearchSuggestionController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text {
            suggestions(for: text)
        }
    }
}
