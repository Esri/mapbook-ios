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

class MapViewController: UIViewController {

    @IBOutlet fileprivate var mapView:AGSMapView!
    @IBOutlet private var ellipsisButton:UIBarButtonItem!
    
    weak var map:AGSMap?
    weak var locatorTask:AGSLocatorTask?
    
    private var isOverlayVisible = true
    fileprivate var searchGraphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //set map from package on map view
        self.mapView.map = self.map
        
        //assign touch delegate for identify
        self.mapView.touchDelegate = self
        
        //graphics overlay to show geocoding results
        self.mapView.graphicsOverlays.add(self.searchGraphicsOverlay)
        
        //set title of the map as the title for the view controller
        self.title = self.map?.item?.title        
    }
    
    /*
     Clear selection on each feature layer.
    */
    fileprivate func clearSelection() {
        
        if let operationalLayers = self.map?.operationalLayers as? [AGSLayer] {
            _ = operationalLayers.map {
                if let featureLayer = $0 as? AGSFeatureLayer {
                    featureLayer.clearSelection()
                }
            }
        }
    }
    
    //MARK: - Symbols
    
    /*
     Picture Marker Symbol for geocde result.
    */
    fileprivate func geocodeResultSymbol() -> AGSSymbol {
        
        let image = #imageLiteral(resourceName: "RedMarker")
        let pictureMarkerSymbol = AGSPictureMarkerSymbol(image: image)
        pictureMarkerSymbol.offsetY = image.size.height/2
        
        return pictureMarkerSymbol
    }
    
    //MARK: - Show/hide overlay
    
    @IBAction func ellipsisButtonAction(_ sender: UIBarButtonItem) {
        
        let action = UIAlertController(title: nil, message: "Explore the map.", preferredStyle: .actionSheet)
        
        let legend = UIAlertAction(title: "Legend", style: .default) { (_) in
            self.performSegue(withIdentifier: "showLegend", sender: nil)
        }
        legend.trySetting(image: UIImage(systemName: "list.bullet"))
        
        let search = UIAlertAction(title: "Search", style: .default) { (_) in
            self.performSegue(withIdentifier: "showSearch", sender: nil)
        }
        search.trySetting(image: UIImage(systemName: "magnifyingglass"))
        
        let bookmarks = UIAlertAction(title: "Bookmarks", style: .default) { (_) in
            self.performSegue(withIdentifier: "showBookmarks", sender: nil)
        }
        bookmarks.trySetting(image: UIImage(systemName: "book"))
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        action.addAction(legend)
        action.addAction(search)
        action.addAction(bookmarks)
        action.addAction(cancel)
        
        action.modalPresentationStyle = .popover
        action.popoverPresentationController?.permittedArrowDirections = [.up]
        action.popoverPresentationController?.barButtonItem = ellipsisButton
        
        present(action, animated: true, completion: nil)
    }

    //MARK: - Navigation
    
    //provide needed data (map or locatorTask) to the child view 
    //controllers in the tab bar controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showLegend",
            let legend = (segue.destination as? UINavigationController)?.topViewController as? LegendViewController {
            legend.map = map
        }
        
        else if segue.identifier == "showSearch",
            let search = (segue.destination as? UINavigationController)?.topViewController as? SearchViewController {
            search.locatorTask = locatorTask
            search.delegate = self
        }
        
        else if segue.identifier == "showBookmarks",
            let bookmarks = (segue.destination as? UINavigationController)?.topViewController as? BookmarksViewController {
            bookmarks.map = map
            bookmarks.delegate = self
        }
    }
}

extension MapViewController:AGSGeoViewTouchDelegate {
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
     
        //clear existing graphics
        self.searchGraphicsOverlay.graphics.removeAllObjects()
        
        //identify
        self.mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResultsPerLayer: 10) { [weak self] (identifyLayerResults, error) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            guard let results = identifyLayerResults else {
                SVProgressHUD.showError(withStatus: "No features at the tapped location", maskType: .gradient)
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
        
        if popups.count > 0 {
            
            let popupsVC = AGSPopupsViewController(popups: popups, containerStyle: AGSPopupsViewControllerContainerStyle.navigationController)
            popupsVC.delegate = self
            popupsVC.modalPresentationStyle = .popover
            popupsVC.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            popupsVC.popoverPresentationController?.sourceView = self.mapView
            popupsVC.popoverPresentationController?.sourceRect = CGRect(origin: screenPoint, size: CGSize.zero)
            self.present(popupsVC, animated: true, completion: nil)
            popupsVC.popoverPresentationController?.delegate = self
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        //hide popover on rotation if visible
        if let _ = self.presentedViewController {
            self.clearSelection()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension MapViewController: BookmarksViewControllerDelegate {
    
    /*
     Update map view's viewpoint based on the selected bookmark
    */
    func bookmarksViewController(_ bookmarksViewController: BookmarksViewController, didSelectBookmark bookmark: AGSBookmark) {
        
        guard let viewpoint = bookmark.viewpoint else {
            return
        }
        
        self.mapView.setViewpoint(viewpoint, completion: nil)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            bookmarksViewController.dismiss(animated: true, completion: nil)
        }
    }
}

extension MapViewController: SearchViewControllerDelegate {
    
    /*
     Add geocode results as graphics on the graphics overlay.
    */
    func searchViewController(_ searchViewController: SearchViewController, didFindGeocodeResults geocodeResults: [AGSGeocodeResult]) {
        
        //clear existing graphics
        self.searchGraphicsOverlay.graphics.removeAllObjects()
        
        guard geocodeResults.count > 0 else {
            SVProgressHUD.showError(withStatus: "No results found", maskType: .gradient)
            return
        }
        
        let geocodeResult = geocodeResults[0]
        
        let graphic = AGSGraphic(geometry: geocodeResult.displayLocation,
                                 symbol: self.geocodeResultSymbol(),
                                 attributes: geocodeResult.attributes)
        
        self.searchGraphicsOverlay.graphics.add(graphic)
        
        //zoom to the extent
        if let extent = geocodeResult.extent {
            self.mapView.setViewpointGeometry(extent, completion: nil)
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            searchViewController.dismiss(animated: true, completion: nil)
        }
    }
}

extension MapViewController:AGSPopupsViewControllerDelegate {
    
    /*
     Update selection on map view to currently viewing popup.
    */
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didChangeToCurrentPopup popup: AGSPopup) {
        
        //clear previous selection
        self.clearSelection()
        
        //select feature on the layer
        guard let feature = popup.geoElement as? AGSFeature else {
            return
        }
        
        (feature.featureTable?.layer as? AGSFeatureLayer)?.select(feature)
    }
}

extension MapViewController:UIPopoverPresentationControllerDelegate {
    
    /*
     Modal presentation as popover even for iPhone
    */
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
        self.clearSelection()
    }
}

extension UIAlertAction {
    
    @discardableResult
    func trySetting(image: UIImage?) -> Bool {
        
        guard var image = image else { return false }

        let pointer = AutoreleasingUnsafeMutablePointer<AnyObject?>(&image)
        
        do {
            try validateValue(pointer, forKey: "image")
            setValue(image, forKey: "image")
        }
        catch {
            return false
        }
        
        return true
    }
}
