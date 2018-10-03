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

/*
 Part of the AppContext that deals with local packages stored on the device
*/
extension AppContext {
    
    /*
     The method gets the URL for all the packages on the device. It looks in the documents 
     directory root folder for .Device mode. And download folder inside documents directory
     for .Portal mode. Returns an empty array for .NotSet. The method should never be called
     in .NotSet mode, per current design.
    */
    private func fetchLocalPackageURLs() -> [URL] {
        
        var localPackageURLs:[URL] = []
        
        //documents directory url
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var directoryURL:URL
        
        //determine directory to look for, based on app mode
        if self.appMode == .device {
            directoryURL = documentsDirectoryURL
        }
        else {
            directoryURL = documentsDirectoryURL.appendingPathComponent(DirectoryType.downloaded.directoryName, isDirectory: true)
        }
        
        //get contents of the directory
        if let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
            
            //filter for packages (.mmpk)
            localPackageURLs = urls.filter({ return $0.pathExtension == "mmpk" })
        }
        
        return localPackageURLs
    }
    
    /*
     The method takes the package URLs from 'fetchLocalPackageURLs() -> [URL]', instantiates
     an AGSMobileMapPackage object for each URL and returns the list of these objects. This
     is a public method to be called by consuming classes.
    */
    func fetchLocalPackages() {
        
        //fetch local package URLs
        let localPackageURLs = self.fetchLocalPackageURLs()
        
        self.localPackages = []
        
        //create AGSMobileMapPackage for each url
        for url in localPackageURLs {
            let package = AGSMobileMapPackage(fileURL: url)
            self.localPackages.append(package)
        }
    }
    
    /*
     Delete local package at an index. This will delete the package file from the device
    */
    func deleteLocalPackage(at index:Int) {
        
        do {
            try FileManager.default.removeItem(at: self.localPackages[index].fileURL)
        }
        catch let error {
            SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            return
        }
        
        self.localPackages.remove(at: index)
    }
    
    /*
     Delete all local packages from the device. Deletes the download folder in case of
     .Portal mode and deletes each item from documents directory root folder in case of
     .Device mode.
    */
    func deleteAllLocalPackages() {
        
        if self.appMode == .portal {
            guard let downloadedDirectoryURL = self.downloadDirectoryURL(directoryType: .downloaded) else {
                return
            }
            
            do {
                try FileManager.default.removeItem(at: downloadedDirectoryURL)
            }
            catch let error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                return
            }
            
            self.localPackages.removeAll()
        }
        else {
            for i in (0..<self.localPackages.count).reversed() {
                self.deleteLocalPackage(at: i)
            }
        }
    }
}
