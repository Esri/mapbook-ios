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
import ArcGISToolkit

class MapViewController: UIViewController {

    @IBOutlet fileprivate var mapView:AGSMapView!
    
    weak var map:AGSMap?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //set map from package on map view
        self.mapView.map = self.map
        
        //assign touch delegate for identify
        self.mapView.touchDelegate = self
                
        //set title of the map as the title for the view controller
        self.title = self.map?.item?.title        
    }
    
    /*
     Clears the map of any selection/results information
    */
    fileprivate func clearMap() {
        // 1. Hide any search result
        hideSearchResult()
        // 2. Clear any selection
        if let operationalLayers = self.map?.operationalLayers as? [AGSLayer] {
            _ = operationalLayers.map {
                if let featureLayer = $0 as? AGSFeatureLayer {
                    featureLayer.clearSelection()
                }
            }
        }
    }
    
    //MARK: - Show/hide overlay
    
    @IBOutlet private var ellipsisButton:UIBarButtonItem!
    
    @IBAction func ellipsisButtonAction(_ sender: UIBarButtonItem) {
        
        let action = UIAlertController(title: nil, message: "Explore the Map", preferredStyle: .actionSheet)
        
        let legend = UIAlertAction(title: "Legend", style: .default) { (_) in
            self.performSegue(withIdentifier: "showLegend", sender: nil)
        }
        
        let bookmarks = UIAlertAction(title: "Bookmarks", style: .default) { (_) in
            self.showBookmarks()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        action.addAction(legend)
        action.addAction(bookmarks)
        action.addAction(cancel)
        
        action.modalPresentationStyle = .popover
        action.popoverPresentationController?.permittedArrowDirections = [.up]
        action.popoverPresentationController?.barButtonItem = ellipsisButton
        
        present(action, animated: true, completion: nil)
    }
    
    //MARK:- Search
    
    weak var locatorTask: AGSLocatorTask? {
        didSet {
            updateBarButtonItems()
            updateSearchController()
        }
    }
            
    @objc func toggleShouldShowSearch(_ sender: UIBarButtonItem) {
        shouldShowSearch.toggle()
    }
    
    private var shouldShowSearch = false {
        didSet {
            updateSearchController()
        }
    }
      
    private func updateBarButtonItems() {
        if locatorTask == nil {
            navigationItem.rightBarButtonItems = [ellipsisButton]
        }
        else {
            let searchButton = UIBarButtonItem(
                image: UIImage(named: "search"),
                style: .plain,
                target: self,
                action: #selector(toggleShouldShowSearch)
            )
            navigationItem.rightBarButtonItems = [ellipsisButton, searchButton]
        }
    }
    
    private func updateSearchController() {
        if shouldShowSearch, let locatorTask = locatorTask {
            let results = LocatorSuggestionController.fromStoryboard(with: locatorTask)
            results.delegate = self
            navigationItem.searchController = {
                let controller = UISearchController(searchResultsController: results)
                controller.searchResultsUpdater = results
                controller.searchBar.placeholder = "Search the Map"
                return controller
            }()
        }
        else {
            navigationItem.searchController = nil
        }
        //refresh navigation controller layout.
        navigationController?.view.setNeedsLayout()
    }
    
    private func showSearch(result: AGSGeocodeResult) {
        shouldShowSearch.toggle()
        if let location = result.displayLocation, let extent = result.extent {
            mapView.callout.accessoryButtonType = .close
            mapView.callout.delegate = self
            mapView.callout.title = result.label
            mapView.callout.show(
                at: location,
                screenOffset: .zero,
                rotateOffsetWithMap: false,
                animated: true
            )

            mapView.setViewpointGeometry(extent, completion: nil)
        }
        else {
            hideSearchResult()
        }
    }
    
    private func hideSearchResult() {
        mapView.callout.dismiss()
    }

    //MARK: - Navigation
    
    //provide needed data (map or locatorTask) to the child view 
    //controllers in the tab bar controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showLegend",
            let legend = (segue.destination as? UINavigationController)?.topViewController as? LegendViewController {
            legend.map = map
        }
    }
    
    // MARK: - Bookmarks
    
    private func showBookmarks() {
        // Bookmarks View Controller
        let bookmarks = BookmarksViewController(geoView: mapView)
        bookmarks.delegate = self
        bookmarks.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(done)
        )
        // Embed Bookmarks View Controller into a Navigation Controller
        let navigation = UINavigationController(rootViewController: bookmarks)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.barButtonItem = ellipsisButton
        navigation.popoverPresentationController?.permittedArrowDirections = .up
        // Present Bookmarks
        present(navigation, animated: true, completion: nil)
    }
    
    @objc func done(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

extension MapViewController:AGSGeoViewTouchDelegate {
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
     
        clearMap()
        
        //identify
        mapView.identifyLayers(
            atScreenPoint: screenPoint,
            tolerance: 12,
            returnPopupsOnly: false,
            maximumResultsPerLayer: 10
        ) { [weak self] (identifyLayerResults, error) in
            
            guard error == nil else {
                flash(error: error!)
                return
            }
            
            guard let results = identifyLayerResults else {
                return
            }
            
            var popups:[AGSPopup] = []
            
            for result in results {
                for geoElement in result.geoElements {
                    let popup = AGSPopup(geoElement: geoElement)
                    popup.popupDefinition.title = result.layerContent.name
                    popups.append(popup)
                }
            }
            
            self?.showPopupsVC(for: popups, at: screenPoint)
        }
    }
    
    /*
     Show popups for identified features
    */
    private func showPopupsVC(for popups:[AGSPopup], at screenPoint:CGPoint) {
        
        guard !popups.isEmpty else { return }
        
        let popups = AGSPopupsViewController(popups: popups, containerStyle: .navigationBar)
        popups.delegate = self
        popups.modalPresentationStyle = .popover
        popups.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        popups.popoverPresentationController?.sourceRect = CGRect(origin: screenPoint, size: CGSize.zero)
        popups.popoverPresentationController?.sourceView = mapView
        popups.popoverPresentationController?.delegate = self
        
        self.present(popups, animated: true, completion: nil)
    }
}

extension MapViewController: BookmarksViewControllerDelegate {
    
    /*
     Update map view's viewpoint based on the selected bookmark
    */
    func bookmarksViewController(_ bookmarksViewController: BookmarksViewController, didSelect bookmark: AGSBookmark) {
        
        defer {
            if UIDevice.current.userInterfaceIdiom == .phone {
                bookmarksViewController.dismiss(animated: true, completion: nil)
            }
        }
        
        guard let viewpoint = bookmark.viewpoint else { return }
        
        self.mapView.setViewpoint(viewpoint, completion: nil)
    }
}

extension MapViewController: LocatorSuggestionControllerDelegate {
    
    func locatorSuggestionController(_ controller: LocatorSuggestionController, didFind result: AGSGeocodeResult) {
        showSearch(result: result)
        controller.dismiss(animated: true, completion: nil)
    }
    
    func locatorSuggestionControllerFoundNoResults(_ controller: LocatorSuggestionController) {
        hideSearchResult()
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MapViewController: AGSCalloutDelegate {
    
    func didTapAccessoryButton(for callout: AGSCallout) {
        hideSearchResult()
    }
}

extension MapViewController: AGSPopupsViewControllerDelegate {
    
    /*
     Update selection on map view to currently viewing popup.
    */
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didChangeToCurrentPopup popup: AGSPopup) {
        
        clearMap()
        
        //select feature on the layer
        guard let feature = popup.geoElement as? AGSFeature else { return }
        
        (feature.featureTable?.layer as? AGSFeatureLayer)?.select(feature)
    }
    
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        popupsViewController.dismiss(animated: true) {
            self.clearMap()
        }
    }
}

extension MapViewController: UIPopoverPresentationControllerDelegate {
    
    /*
     Modal presentation as popover even for iPhone
    */
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        clearMap()
    }
}

