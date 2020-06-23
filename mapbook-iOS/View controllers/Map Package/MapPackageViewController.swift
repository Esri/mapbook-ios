//// Copyright 2020 Gagandeep Singh
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

import ArcGIS

class MapPackageViewController: UITableViewController {
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static var byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        return formatter
    }()
    
    @IBOutlet weak var packageThumbnailImageView: UIImageView!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var byteCountLabel: UILabel!
    @IBOutlet weak var mapCountLabel: UILabel!
    @IBOutlet weak var lastDownloadedLabel: UILabel!
    @IBOutlet weak var mapDescriptionlabel: UILabel!
    @IBOutlet weak var mapsCollectionView: UICollectionView!
    
    var mapPackage: AGSMobileMapPackage!
        
    override func viewDidLoad() {
        
        tableView.rowHeight = UITableView.automaticDimension

        mapPackage?.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.configureView(with: error)
            }
            else {
                self.configureView(with: self.mapPackage)
                self.loadMapsThumbnails(maps: self.mapPackage.maps)
            }
        }
    }
    
    private func configureView(with package: AGSMobileMapPackage) {
        
        guard let item = package.item else { return }
        
        title = item.title
        
        if let created = item.created {
            createdAtLabel.text = Self.dateFormatter.string(from: created)
        }
        else {
            createdAtLabel.text = .missing
        }
        
        if let size = package.size {
            byteCountLabel.text = Self.byteFormatter.string(fromByteCount: size)
        }
        else {
            byteCountLabel.text = .missing
        }
        
        mapCountLabel.text = "\(package.maps.count)"
        
        if let downloadDate = package.downloadDate {
            lastDownloadedLabel.text = Self.dateFormatter.string(from: downloadDate)
        }
        else {
            lastDownloadedLabel.text = .missing
        }
        
        mapDescriptionlabel.text = item.snippet
        mapDescriptionlabel.sizeToFit()
        
        if let thumbnail = item.thumbnail {
            thumbnail.load { [weak self] (error) in
                guard let self = self else { return }
                self.packageThumbnailImageView.image = thumbnail.image
            }
        }
        
    }
    
    private func loadMapsThumbnails(maps: [AGSMap]) {
        let thumbnails = maps.compactMap { $0.item?.thumbnail }
        AGSLoadObjects(thumbnails) { [weak self] (_) in
            guard let self = self else { return }
            self.mapsCollectionView.reloadData()
        }
    }
    
    private func configureView(with failure: Error) {
        title = "Map Package"
        createdAtLabel.text = .missing
        byteCountLabel.text = .missing
        mapCountLabel.text = .missing
        lastDownloadedLabel.text = .missing
        mapDescriptionlabel.text = .missing
        packageThumbnailImageView.isHidden = true
        flash(error: failure)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showMap",
            let mapViewController = segue.destination as? MapViewController,
            let collectionView = sender as? UICollectionView,
            let indexPaths = collectionView.indexPathsForSelectedItems {
            if !indexPaths.isEmpty {
                let indexPath = indexPaths[0]
                let map = mapPackage.maps[indexPath.row]
                mapViewController.map = map
                mapViewController.locatorTask = mapPackage.locatorTask
            }
        }
    }
}

extension MapPackageViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        }
        else {
            return 300.0
        }
    }
}

class MapCollectionCell: UICollectionViewCell {
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var mapTitleLabel: UILabel!
    @IBOutlet weak var mapDescriptionLabel: UILabel!
    @IBOutlet weak var mapThumbnailImageView: UIImageView!
    
    func updateUI(with map: AGSMap) {
        
        if let created = map.item?.created {
            createdDateLabel.text = Self.dateFormatter.string(from: created)
        }
        else {
            createdDateLabel.text = .missing
        }
        
        mapTitleLabel.text = map.item?.title
        mapDescriptionLabel.text = map.item?.snippet
        mapThumbnailImageView.image = map.item?.thumbnail?.image
    }
    
    private var _selected: Bool = false
    
    override var isSelected: Bool {
        set {
            _selected = newValue
            if _selected {
                layer.borderColor = UIColor.primary.cgColor
            }
            else {
                layer.borderColor = UIColor.clear.cgColor
            }
        }
        get {
            _selected
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 8
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.clear.cgColor
    }
}

extension MapPackageViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mapPackage.maps.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MapCollectionCell",
                                                      for: indexPath) as! MapCollectionCell
        
        let map = mapPackage.maps[indexPath.row]
        cell.updateUI(with: map)
        
        return cell
    }
}

extension MapPackageViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showMap", sender: collectionView)
    }
}

private extension String {
    static let missing = "-"
}
