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

class LegendViewController: UITableViewController {

    @IBOutlet private var footerView: UIView!
    
    weak var map:AGSMap?
    
    fileprivate var content:[AGSObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layers = map?.operationalLayers as? [AGSLayer] {
            self.populateLegends(with: layers)
        }
    }

    /*
     Populate legend infos recursively, for sublayers.
    */
    private func populateLegends(with layers:[AGSLayer]) {
        
        for layer in layers {
            
            if layer.subLayerContents.count > 0 {
                self.populateLegends(with: layer.subLayerContents as! [AGSLayer])
            }
            else {
                //else if no sublayers fetch legend info
                self.content.insert(layer, at: 0)
                layer.fetchLegendInfos { [weak self, constLayer = layer] (legendInfos, error) -> Void in
                    
                    guard let self = self else { return }
                    
                    guard error == nil else {
                        flash(error: error!)
                        return
                    }
                    
                    if let legendInfos = legendInfos, let index = self.content.firstIndex(of: constLayer) {
                        self.content.insert(contentsOf: legendInfos as [AGSObject], at: index + 1)
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        if content.count == 0 {
            //show footer view with "No legends" label
            self.footerView.isHidden = false
        }
    }
    
    @IBAction func userRequestedDismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

extension LegendViewController /* UITableViewDataSource */ {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let anyObject = self.content[indexPath.row]
        if let operationalLayer = anyObject as? AGSLayer,
            let cell = tableView.dequeueReusableCell(withIdentifier: "LayerCell") as? LayerCell {
            
            cell.operationalLayer = operationalLayer
            
            return cell
        }
        else if let legendInfo = anyObject as? AGSLegendInfo,
            let cell = tableView.dequeueReusableCell(withIdentifier: "LegendInfoCell") as? LegendInfoCell {
            
            cell.legendInfo = legendInfo
            
            return cell
        }
        
        return UITableViewCell()
    }
}

extension LegendViewController /* UITableViewDelegate */ {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let anyObject = self.content[indexPath.row]
        
        if anyObject is AGSLayer {
            return 44
        }
        else {
            return 32
        }
    }
}
