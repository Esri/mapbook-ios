//
//  SearchViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/19/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

@objc protocol SearchViewControllerDelegate:class {
    
    @objc optional func searchViewController(_ searchViewController:SearchViewController, didFindGeocodeResults geocodeResults:[AGSGeocodeResult])
}

class SearchViewController: UIViewController {

    @IBOutlet private var tableView:UITableView!
    
    weak var locatorTask:AGSLocatorTask?
    weak var delegate:SearchViewControllerDelegate?
    
    fileprivate var suggestResults:[AGSSuggestResult] = []
    
    private var suggestCancelable:AGSCancelable?
    private var geocodeCancelable:AGSCancelable?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.delegate?.searchViewController?(self, didFindGeocodeResults: [])
    }

    fileprivate func suggestions(for text:String) {
        
        guard let locatorTask = self.locatorTask else {
            return
        }
        
        //cancel previous request
        self.suggestCancelable?.cancel()
        
        self.suggestCancelable = locatorTask.suggest(withSearchText: text) { [weak self] (suggestResults, error) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            guard let suggestResults = suggestResults else {
                print("No suggestions")
                return
            }
            
            //TODO: see if we need to clear the graphics in graphics overlay
            
            self?.suggestResults = suggestResults
            self?.tableView.reloadData()
        }
    }
    
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
            
            guard let geocodeResults = geocodeResults else {
                print("No location found")
                return
            }
            
            self.delegate?.searchViewController?(self, didFindGeocodeResults: geocodeResults)
            
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
}
