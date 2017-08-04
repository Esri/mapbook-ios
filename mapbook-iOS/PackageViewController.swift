//
//  PackageViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/18/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
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
    
    fileprivate var selectedMap:AGSMap?
    
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        self.titleLabel.text = item.title
        self.createdLabel.text = "Created \(dateFormatter.string(from: item.created!))"
        self.sizeLabel.text = "Size \(AppContext.shared.size(of: mobileMapPackage) ?? "--")"
        self.mapsCountLabel.text = "\(mobileMapPackage.maps.count) Maps"
        self.lastDownloadedLabel.text = "Last downloaded \(AppContext.shared.downloadDate(of: mobileMapPackage) ?? "--")"
        self.descriptionLabel.text = item.snippet
        
        self.thumbnailImageView.image = item.thumbnail?.image
        
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "MapVCSegue", let controller = segue.destination as? MapViewController {
            
            controller.map = self.selectedMap
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
   
        self.selectedMap = self.mobileMapPackage?.maps[indexPath.row]
        self.performSegue(withIdentifier: "MapVCSegue", sender: self)
    }
}
