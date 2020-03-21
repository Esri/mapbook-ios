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

class PortalItemCell: UITableViewCell {
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static var byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        return formatter
    }()

    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var createdLabel:UILabel!
    @IBOutlet private var sizeLabel:UILabel!
    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var thumbnailImageView:UIImageView!
    @IBOutlet private var downloadButton:UIButton!
    @IBOutlet private var activityIndicatorView:UIActivityIndicatorView!
    
    enum Status {
        case unknown, cloud, downloading, downloaded
    }
    
    var status: Status = .unknown {
        didSet {
            switch status {
            case .cloud:
                downloadButton.isEnabled = true
                downloadButton.isHidden = false
                activityIndicatorView.isHidden = true
                activityIndicatorView.stopAnimating()
                break
            case .downloading:
                downloadButton.isEnabled = false
                downloadButton.isHidden = true
                activityIndicatorView.isHidden = false
                activityIndicatorView.startAnimating()
                break
            case .downloaded:
                downloadButton.isEnabled = false
                downloadButton.isHidden = false
                activityIndicatorView.isHidden = true
                activityIndicatorView.stopAnimating()
                break
            default:
                downloadButton.isEnabled = false
                downloadButton.isHidden = true
                activityIndicatorView.isHidden = true
                activityIndicatorView.stopAnimating()
                break
            }
        }
    }
    
    var portalItem: AGSPortalItem? {
        didSet {
            
            //update UI
            
            self.titleLabel.text = portalItem?.title
            
            if let created = portalItem?.created {
                self.createdLabel.text = "\(Self.dateFormatter.string(from: created))"
            }
            else {
                self.createdLabel.text = ""
            }
            
            if let size = portalItem?.size {
                self.sizeLabel.text = "\(Self.byteCountFormatter.string(fromByteCount: size))"
            }
            else {
                self.sizeLabel.text = ""
            }
            
            self.descriptionLabel.text = portalItem?.snippet
            
            self.thumbnailImageView.image = portalItem?.thumbnail?.image
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = ""
        createdLabel.text = ""
        sizeLabel.text = ""
        descriptionLabel.text = ""
        thumbnailImageView.image = nil
        status = .unknown
        portalItem = nil
    }
    
    //MARK: -  Actions
    
    @IBAction private func download(_ sender:UIButton) {
        
        guard let portalItem = self.portalItem else {
            return
        }
                
        try? appContext.packageManager.download(item: portalItem)
    }
}
