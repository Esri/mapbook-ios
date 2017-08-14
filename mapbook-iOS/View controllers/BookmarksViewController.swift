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

@objc protocol BookmarksViewControllerDelegate:class {
    
    @objc optional func bookmarksViewController(_ bookmarksViewController:BookmarksViewController, didSelectBookmark bookmark:AGSBookmark)
}

class BookmarksViewController: UIViewController {

    @IBOutlet private var tableView:UITableView!
    
    weak var map:AGSMap?
    weak var delegate:BookmarksViewControllerDelegate?

}

extension BookmarksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.map?.bookmarks.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell"),
            let bookmark = self.map?.bookmarks[indexPath.row] as? AGSBookmark else {
            
            return UITableViewCell()
        }
        
        cell.textLabel?.text = bookmark.name
        
        return cell
    }
}

extension BookmarksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let bookmark = self.map?.bookmarks[indexPath.row] as? AGSBookmark else {
            return
        }
        
        self.delegate?.bookmarksViewController?(self, didSelectBookmark: bookmark)
    }
}
