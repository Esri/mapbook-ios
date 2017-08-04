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

class PackageViewController: UIViewController {

    @IBOutlet private var thumbnailImageView:UIImageView!
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var createdLabel:UILabel!
    @IBOutlet private var sizeLabel:UILabel!
    @IBOutlet private var mapsCountLabel:UILabel!
    @IBOutlet private var lastDownloadedLabel:UILabel!
    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var collectionView:UICollectionView!
    
    var mobileMapPackage:AGSMobileMapPackage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.mobileMapPackage == nil {
            SVProgressHUD.showError(withStatus: "Mobile map package is nil", maskType: .gradient)
            return
        }
        
        self.loadMapPackage()
        
        self.thumbnailImageView.layer.borderWidth = 1
        self.thumbnailImageView.layer.borderColor = UIColor.primaryBlue().cgColor
    }

    private func loadMapPackage() {
        
        //load mobile map package to access content
        self.mobileMapPackage?.load { [weak self] (error) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            self?.updateUI()
            self?.collectionView.reloadData()
        }
    }
    
    private func updateUI() {
        
        guard let mobileMapPackage = self.mobileMapPackage, mobileMapPackage.loadStatus == .loaded else {
            
            SVProgressHUD.showError(withStatus: "Either mobile map package is nil or not loaded", maskType: .gradient)
            return
        }
        
        guard let item = mobileMapPackage.item else {

            SVProgressHUD.showError(withStatus: "Item not found on mobile map package", maskType: .gradient)
            return
        }
        
        self.titleLabel.text = item.title
        self.createdLabel.text = "Created \(AppContext.shared.createdDate(of: item) ?? "--")"
        self.sizeLabel.text = "Size \(AppContext.shared.size(of: mobileMapPackage) ?? "--")"
        self.mapsCountLabel.text = "\(mobileMapPackage.maps.count) Maps"
        self.lastDownloadedLabel.text = "Last downloaded \(AppContext.shared.downloadDate(of: mobileMapPackage) ?? "--")"
        self.descriptionLabel.text = item.snippet
        self.thumbnailImageView.image = item.thumbnail?.image
    }
    
    private func selectedMap() -> AGSMap? {
        
        if let selectedIndexPath = self.collectionView.indexPathsForSelectedItems?[0] {
            if let map = self.mobileMapPackage?.maps[selectedIndexPath.item] {
                return map
            }
        }
        
        return nil
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "MapVCSegue", let controller = segue.destination as? MapViewController {
            
            controller.map = self.selectedMap()
            controller.locatorTask = mobileMapPackage?.locatorTask
        }
    }
}

extension PackageViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mobileMapPackage?.maps.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MapCell", for: indexPath) as! MapCell
        
        cell.map = self.mobileMapPackage?.maps[indexPath.item]
        
        return cell
    }
}

extension PackageViewController: UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
   
        self.performSegue(withIdentifier: "MapVCSegue", sender: self)
    }
}
