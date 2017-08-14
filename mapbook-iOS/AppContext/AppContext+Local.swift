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

extension AppContext {
    
    private func fetchLocalPackageURLs() -> [URL] {
        
        var localPackageURLs:[URL] = []
        
        if self.appMode == .notSet {
            return localPackageURLs
        }
        
        //documents directory url
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var directoryURL:URL
        
        if self.appMode == .device {
            directoryURL = documentsDirectoryURL
        }
        else {
            directoryURL = documentsDirectoryURL.appendingPathComponent(DownloadedPackagesDirectoryName, isDirectory: true)
        }
        
        if let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
            
            localPackageURLs = urls.filter({ return $0.pathExtension == "mmpk" })
            
        }
        
        return localPackageURLs
    }
    
    func fetchLocalPackages() {
        
        let localPackageURLs = self.fetchLocalPackageURLs()
        
        self.localPackages = []
        
        //create AGSMobileMapPackage for each url
        for url in localPackageURLs {
            let package = AGSMobileMapPackage(fileURL: url)
            self.localPackages.append(package)
        }
    }
    
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
    
    func deleteAllLocalPackages() {
        
        if self.appMode == .portal {
            guard let downloadDirectoryURL = self.downloadDirectoryURL() else {
                return
            }
            
            do {
                try FileManager.default.removeItem(at: downloadDirectoryURL)
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
