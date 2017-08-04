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

        self.mapView.map = self.map
        
        self.mapView.touchDelegate = self
        
        self.mapView.graphicsOverlays.add(self.searchGraphicsOverlay)
        
        self.title = self.map?.item?.title
        
        self.overlayView.bottomAnchor.constraint(equalTo: self.mapView.attributionTopAnchor, constant: -50).isActive = true
        
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
        
        self.toggleOverlay(on: false, animated: false)
    }
    
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
    
    fileprivate func geocodeResultSymbol() -> AGSSymbol {
        
        let image = #imageLiteral(resourceName: "RedMarker")
        let pictureMarkerSymbol = AGSPictureMarkerSymbol(image: image)
        pictureMarkerSymbol.offsetY = image.size.height/2
        
        return pictureMarkerSymbol
    }
    
    //MARK: - Show/hide overlay
    
    func toggleOverlay(on: Bool, animated: Bool) {
        
        if self.isOverlayVisible == on {
            return
        }
        
        self.toggleBarButtonItem?.image = !isOverlayVisible ? #imageLiteral(resourceName: "BurgerMenuSelected") : #imageLiteral(resourceName: "BurgerMenu")
        
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
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        self.mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResultsPerLayer: 10) { (identifyLayerResults, error) in
            
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
            
            self.showPopupsVC(for: popups, at: screenPoint)
        }
    }
}

extension MapViewController:BookmarksViewControllerDelegate {
    
    func bookmarksViewController(_ bookmarksViewController: BookmarksViewController, didSelectBookmark bookmark: AGSBookmark) {
        
        guard let viewpoint = bookmark.viewpoint else {
            return
        }
        
        self.mapView.setViewpoint(viewpoint, completion: nil)
    }
}

extension MapViewController:SearchViewControllerDelegate {
    
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
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
        self.clearSelection()
    }
}
