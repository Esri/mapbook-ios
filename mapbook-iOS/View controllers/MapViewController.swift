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
    @IBOutlet fileprivate var overlayTrailingConstraint:NSLayoutConstraint!
    @IBOutlet fileprivate var overlayView:UIVisualEffectView!
    @IBOutlet private var toggleBarButtonItem:UIBarButtonItem!
    
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
        
        //constraint bottom anchor of the overlay view to the top anchor
        //of the attribution label, so it resizes when the label grows
        self.overlayView.bottomAnchor.constraint(equalTo: self.mapView.attributionTopAnchor, constant: -50).isActive = true
        
        //stylize overlay view
        self.overlayView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        self.overlayView.layer.borderWidth = 2
        
        //increase selection width for feature layers
        if let operationalLayers = self.map?.operationalLayers as? [AGSLayer] {
            _ = operationalLayers.map ({
                if let featureLayer = $0 as? AGSFeatureLayer {
                    featureLayer.selectionWidth = 5
                }
            })
        }
        
        //hide side panel by default
        self.toggleOverlay(on: false, animated: false)
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
    
    /*
     Show or hide overlay view.
    */
    func toggleOverlay(on: Bool, animated: Bool) {
        
        if self.isOverlayVisible == on {
            return
        }
        
        //update bar button item image based on state
        self.toggleBarButtonItem?.image = !isOverlayVisible ? #imageLiteral(resourceName: "BurgerMenuSelected") : #imageLiteral(resourceName: "BurgerMenu")
        
        //use the width to compute the offset
        let width = self.overlayView.frame.width
        self.overlayTrailingConstraint.constant = on ? 10 : -(width + 10)
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: { [weak self] in
                
                self?.view.layoutIfNeeded()
                
            }, completion: { [weak self] (finished) in
                
                self?.isOverlayVisible = on
            })
        }
        else {
            self.view.layoutIfNeeded()
            self.isOverlayVisible = on
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func overlayAction(_ sender: UIBarButtonItem) {
        
        self.toggleOverlay(on: !isOverlayVisible, animated: true)
    }

    //MARK: - Navigation
    
    //provide needed data (map or locatorTask) to the child view 
    //controllers in the tab bar controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "TabBarEmbedSegue", let controller = segue.destination as? UITabBarController {
            
            if let legendViewController = controller.viewControllers?[0] as? LegendViewController {
                legendViewController.map = self.map
            }
            if let searchViewController = controller.viewControllers?[1] as? SearchViewController {
                searchViewController.locatorTask = self.locatorTask
                searchViewController.delegate = self
            }
            if let bookmarksViewController = controller.viewControllers?[2] as? BookmarksViewController {
                bookmarksViewController.map = map
                bookmarksViewController.delegate = self
            }
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
}

extension MapViewController:BookmarksViewControllerDelegate {
    
    /*
     Update map view's viewpoint based on the selected bookmark
    */
    func bookmarksViewController(_ bookmarksViewController: BookmarksViewController, didSelectBookmark bookmark: AGSBookmark) {
        
        guard let viewpoint = bookmark.viewpoint else {
            return
        }
        
        self.mapView.setViewpoint(viewpoint, completion: nil)
    }
}

extension MapViewController:SearchViewControllerDelegate {
    
    /*
     Add geocode results as graphics on the graphics overlay.
    */
    func searchViewController(_ searchViewController: SearchViewController, didFindGeocodeResults geocodeResults: [AGSGeocodeResult]) {
        
        //clear existing graphics
        self.searchGraphicsOverlay.graphics.removeAllObjects()
        
        for geocodeResult in geocodeResults {
            
            let graphic = AGSGraphic(geometry: geocodeResult.displayLocation, symbol: self.geocodeResultSymbol(), attributes: geocodeResult.attributes)
            self.searchGraphicsOverlay.graphics.add(graphic)
            
            //zoom to the extent
            if let extent = geocodeResult.extent {
                self.mapView.setViewpointGeometry(extent, completion: nil)
            }
            
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
        
        feature.featureTable?.featureLayer?.select(feature)
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
