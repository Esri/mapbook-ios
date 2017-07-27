//
//  LegendViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/19/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class LegendViewController: UIViewController {

    @IBOutlet private var tableView:UITableView!
    
    weak var map:AGSMap?
    
    fileprivate var content = [AGSObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layers = map?.operationalLayers as? [AGSLayer] {
            self.populateLegends(with: layers)
        }
    }

    private func populateLegends(with layers:[AGSLayer]) {
        
        for layer in layers {
            
            if layer.subLayerContents.count > 0 {
                self.populateLegends(with: layer.subLayerContents as! [AGSLayer])
            }
            else {
                //else if no sublayers fetch legend info
                self.content.append(layer)
                layer.fetchLegendInfos { [weak self] (legendInfos, error) -> Void in
                    
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    
                    if let legendInfos = legendInfos {
                        if let index = self?.content.index(of: layer) {
                            self?.content.insert(contentsOf: legendInfos as [AGSObject], at: index + 1)
                            self?.tableView.reloadData()
                        }
                    }
                    
                }
            }
        }
    }
}

extension LegendViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let temp = self.content[indexPath.row]
        if let operationalLayer = temp as? AGSLayer, let cell = tableView.dequeueReusableCell(withIdentifier: "LayerCell") as? LayerCell {
            
            cell.operationalLayer = operationalLayer
            
            return cell
        }
        else if let legendInfo = temp as? AGSLegendInfo, let cell = tableView.dequeueReusableCell(withIdentifier: "LegendInfoCell") as? LegendInfoCell {
            
            cell.legendInfo = legendInfo
            
            return cell
        }
        
        return UITableViewCell()
    }
}

extension LegendViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let temp = self.content[indexPath.row]
        
        if temp is AGSLayer {
            return 44
        }
        else {
            return 32
        }
    }
}
