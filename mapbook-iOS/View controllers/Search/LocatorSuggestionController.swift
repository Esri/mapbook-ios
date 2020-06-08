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

protocol LocatorSuggestionControllerDelegate: class {
    func locatorSuggestionController(_ controller:LocatorSuggestionController, didFind result:AGSGeocodeResult)
    func locatorSuggestionControllerFoundNoResults(_ controller:LocatorSuggestionController)
}

class LocatorSuggestionController: UITableViewController {
    
    // MARK:- Init
    
    // MARK: Storyboard
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // Leverage this method if you want to design the look of the result suggestion cell.
    static func fromStoryboard(with locator: AGSLocatorTask) -> Self {
        let controller = UIStoryboard(name: "LocatorSearch", bundle: nil)
            .instantiateViewController(withIdentifier: "LocatorSuggestionController") as! Self
        controller.locatorTask = locator
        return controller
    }
    
    // MARK: Programmatically
    
    init(locator: AGSLocatorTask) {
        locatorTask = locator
        super.init(style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cellReuseIdentifier)
    }
        
    weak var locatorTask: AGSLocatorTask?
    
    weak var delegate: LocatorSuggestionControllerDelegate?
    
    // MARK:- Suggestions
    
    fileprivate var suggestResults = [AGSSuggestResult]()

    private var suggestCancelable: AGSCancelable?

    /**
     Get suggestions for text. The method cancels any previous request.
     And on successful completion the results are shown in the table
     view.
    */
    fileprivate func suggestions(for text:String) {
        
        guard let locatorTask = locatorTask else {
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
        
        guard let locatorTask = locatorTask else {
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
            
            if let result = geocodeResults?.first {
                self.delegate?.locatorSuggestionController(self, didFind: result)
            }
            else {
                self.delegate?.locatorSuggestionControllerFoundNoResults(self)
            }
        }
    }
}

extension LocatorSuggestionController /* UITableViewDataSource */ {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cellReuseIdentifier, for: indexPath)
        let suggestResult = suggestResults[indexPath.row]
        cell.textLabel?.text = suggestResult.label
        return cell
    }
}

extension LocatorSuggestionController /* UITableViewDelegate */ {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let suggestResult = suggestResults[indexPath.row]
        geocode(for: suggestResult)
    }
}

extension LocatorSuggestionController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text {
            suggestions(for: text)
        }
        else {
            suggestCancelable?.cancel()
        }
    }
}

extension String {
    static let cellReuseIdentifier = "SearchSuggestionCell"
}
