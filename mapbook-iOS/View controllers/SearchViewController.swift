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

@objc protocol SearchViewControllerDelegate:class {
    
    @objc optional func searchViewController(_ searchViewController:SearchViewController, didFindGeocodeResults geocodeResults:[AGSGeocodeResult])
}

class SearchViewController: UIViewController {

    @IBOutlet private var tableView:UITableView!
    @IBOutlet fileprivate var searchBar:UISearchBar!
    
    weak var locatorTask:AGSLocatorTask?
    weak var delegate:SearchViewControllerDelegate?
    
    fileprivate var suggestResults:[AGSSuggestResult] = []
    
    private var suggestCancelable:AGSCancelable?
    private var geocodeCancelable:AGSCancelable?

    /*
     Get suggestions for text. The method cancels any previous request.
     And on successful completion the results are shown in the table
     view.
    */
    fileprivate func suggestions(for text:String) {
        
        guard let locatorTask = self.locatorTask else {
            return
        }
        
        //cancel previous request
        self.suggestCancelable?.cancel()
        
        self.suggestCancelable = locatorTask.suggest(withSearchText: text) { [weak self] (suggestResults, error) in
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                return
            }
            
            guard let suggestResults = suggestResults else {
                print("No suggestions")
                return
            }
            
            self?.suggestResults = suggestResults
            self?.tableView.reloadData()
        }
    }
    
    /*
     Geocode location for suggest result. Called when the user
     selects a suggestion. The delegate is notified of the results.
    */
    fileprivate func geocode(for suggestResult:AGSSuggestResult) {
        
        guard let locatorTask = self.locatorTask else {
            return
        }
        
        self.geocodeCancelable?.cancel()
        
        self.geocodeCancelable = locatorTask.geocode(with: suggestResult) { (geocodeResults, error) in
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                return
            }
            
            self.delegate?.searchViewController?(self, didFindGeocodeResults: geocodeResults ?? [])
        }
    }
    
    /*
     Geocode location for input text. Called when the user
     hits search in the search bar
     */
    fileprivate func geocode(for text:String) {
        guard let locatorTask = self.locatorTask else {
            return
        }
        
        self.geocodeCancelable?.cancel()
        
        self.geocodeCancelable = locatorTask.geocode(withSearchText: text) { (geocodeResults, error) in
            
            guard error == nil else {
                if let error = error as NSError?, error.code != NSUserCancelledError {
                    SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                }
                return
            }
            
            self.delegate?.searchViewController?(self, didFindGeocodeResults: geocodeResults ?? [])
        }
    }
}

extension SearchViewController:UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.suggestResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestResultCell") else {
            return UITableViewCell()
        }
        
        let suggestResult = self.suggestResults[indexPath.row]
        cell.textLabel?.text = suggestResult.label
        
        return cell
    }
}

extension SearchViewController:UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let suggestResult = self.suggestResults[indexPath.row]
        self.geocode(for: suggestResult)
    }
}

extension SearchViewController:UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if let searchText = searchBar.text {
            self.suggestions(for: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        
        if let text = searchBar.text {
            self.geocode(for: text)
        }
    }
}

extension SearchViewController:UIScrollViewDelegate {
    
    //hide keyboard on scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if self.searchBar.isFirstResponder {
            self.searchBar.resignFirstResponder()
        }
    }
}
