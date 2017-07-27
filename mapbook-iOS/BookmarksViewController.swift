//
//  BookmarksViewController.swift
//  mapbook-iOS
//
//  Created by Gagandeep Singh on 7/19/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

}

extension BookmarksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.map?.bookmarks.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell"), let bookmark = self.map?.bookmarks[indexPath.row] as? AGSBookmark else {
            
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
