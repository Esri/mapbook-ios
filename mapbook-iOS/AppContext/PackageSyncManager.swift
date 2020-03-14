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

extension URL {
    
    static var root: URL {
        let _root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let root = _root else { preconditionFailure("User root document directory should never be nil.") }
        return root
    }
    
    static var temporary: URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mapbook", isDirectory: true)
            .appendingPathComponent("downloading", isDirectory: true)
    }
    
    static var downloaded: URL {
        root.appendingPathComponent("downloaded", isDirectory: true)
    }
}

extension FileManager {
    
    func touchTemporaryDirectory() throws -> URL {
        try createDirectory(at: URL.temporary)
    }
    
    func touchDownloadedDirectory() throws -> URL {
        try createDirectory(at: URL.downloaded)
    }
    
    private func createDirectory(at url: URL) throws -> URL {
        
        var isDirectory:ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return url
            }
        }
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        
        return url
    }
    
    func hasDownloaded(item: AGSPortalItem) throws -> Bool {
        let mmpkName = try PortalAwareMobileMapPackage.mmpkDirectoryName(for: item)
        let url = URL.downloaded.appendingPathComponent(mmpkName)
        return FileManager.default.fileExists(atPath: url.path)
        
    }
}

protocol PackageSyncManagerDelegate: class {
    
    func packageSyncManager(_ manager: PackageSyncManager, failed error: Error, item: AGSPortalItem)
    func packageSyncManager(_ manager: PackageSyncManager, downloaded item: AGSPortalItem, to path: URL)
}

class PackageSyncManager {
    
    private weak var portal: AGSPortal?
    
    init(portal: AGSPortal) {
        self.portal = portal
    }
    
    // MARK:- Download
    
    func isCurrentlyDownloading(item id: String) -> Bool {
        downloadQueue.operations.contains(where: { ($0 as! AGSRequestOperation).sessionID == id })
    }
    
    func download(item: AGSPortalItem) throws {
        
        guard let portal = portal else { throw UnknownError() }
        
        guard item.type == .mobileMapPackage else { throw PortalAwareMobileMapPackage.InvalidType() }
        
        guard !isCurrentlyDownloading(item: item.itemID) else {
            throw ItemAlreadyDownloading()
        }
        
        let temporaryURL: URL
        let downloadedURL: URL
        let operation: AGSRequestOperation
        
        let mmpkName = try PortalAwareMobileMapPackage.mmpkDirectoryName(for: item)
        
        do {
            temporaryURL = try FileManager.default
                                        .touchTemporaryDirectory()
                                        .appendingPathComponent(mmpkName)
            
            downloadedURL = try FileManager.default
                                        .touchDownloadedDirectory()
                                        .appendingPathComponent(mmpkName)
            
            operation = try AGSRequestOperation(portal: portal, item: item)
        }
        catch {
            delegate?.packageSyncManager(self, failed: MissingDirectory(), item: item)
            return
        }
        
        operation.outputFileURL = temporaryURL
        operation.registerListener(self) { [weak self] (result, error) in
            
            guard let self = self else { return }
            
            guard error == nil else {
                try? FileManager.default.removeItem(at: temporaryURL)
                self.delegate?.packageSyncManager(self, failed: error!, item: item)
                return
            }
            
            do {
                try FileManager.default.moveItem(at: temporaryURL, to: downloadedURL)
            }
            catch {
                self.delegate?.packageSyncManager(self, failed: error, item: item)
                return
            }
            
            self.delegate?.packageSyncManager(self, downloaded: item, to: downloadedURL)
        }
        
        downloadQueue.addOperation(operation)
    }
    
    // MARK:- Update
    
    private struct MMPKCoupled {
        let package: PortalAwareMobileMapPackage
        let item: AGSPortalItem
    }
    
    func checkForUpdates(packages: [PortalAwareMobileMapPackage], completion: @escaping () -> Void) throws {
        
        guard let portal = portal else { throw UnknownError() }
        
        let coupled = packages.compactMap { (package) -> MMPKCoupled? in
            guard let itemID = package.itemID else {
                package.canUpdate = false
                return nil
            }
            let item = AGSPortalItem(portal: portal, itemID: itemID)
            return MMPKCoupled(package: package, item: item)
        }
        
        guard coupled.count > 0 else { completion(); return }
        
        AGSLoadObjects(coupled.map({ $0.item })) { (_) in
            for couple in coupled {
                if let downloaded = couple.package.downloadDate, let modified = couple.item.modified {
                    couple.package.canUpdate = modified > downloaded
                }
                else {
                    couple.package.canUpdate = false
                }
            }
            completion()
        }
    }
    
    func update(package: PortalAwareMobileMapPackage) throws {
        
        guard let portal = portal else { throw UnknownError() }
        
        guard let itemID = package.itemID else { throw MissingPortalCounterpart() }
        
        let portalItem = AGSPortalItem(portal: portal, itemID: itemID)
        
        try download(item: portalItem)
    }
    
    // MARK:- Operation Queue
    
    private var downloadQueue = AGSOperationQueue()
    
    // MARK:- Local

    func fetchLocalPackages() throws -> [PortalAwareMobileMapPackage] {
        
        
        #warning("Delete")
        return [PortalAwareMobileMapPackage]()
    }
    
    // MARK:- Delegate
    
    weak var delegate: PackageSyncManagerDelegate?
        
    // MARK: Errors
    
    struct ItemAlreadyDownloading: LocalizedError {
        let localizedDescription: String = "Item download already in progress."
    }
    
    struct MissingDirectory: LocalizedError {
        let localizedDescription: String = "Could not find or create local device directory."
    }
    
    struct MissingPortalCounterpart: LocalizedError {
        let localizedDescription: String = "Local package missing portal counterpart."
    }
    
    struct UnknownError: LocalizedError {
        let localizedDescription: String = "An unknown error occured."
    }
    
    // MARK:- Deinit
    
    deinit {
        downloadQueue.operations.forEach { $0.cancel() }
    }
}

extension AGSRequestOperation {
    
    convenience init(portal: AGSPortal, item: AGSItem) throws {
        
        guard let url = portal.url else {
            throw MissingURLError()
        }
        
        let dataURLString = String(format: "%@/sharing/rest/content/items/%@/data", url.absoluteString, item.itemID)
        
        guard let dataURL = URL(string: dataURLString) else {
            throw InvalidURLError()
        }
                
        self.init(remoteResource: portal, url: dataURL, queryParameters: nil, method: .get)
        
        self.sessionID = item.itemID
    }
    
    // MARK:- Errors
    
    struct MissingURLError: LocalizedError {
        let localizedDescription: String = "URL not found"
    }
    
    struct InvalidURLError: LocalizedError {
        let localizedDescription: String = "Invalid URL"
    }
}

class PortalAwareMobileMapPackage: AGSMobileMapPackage {
    
    var canUpdate: Bool = false
    
    var itemID: String? {
        guard fileURL.pathExtension == "mmpk" else { return nil }
        return fileURL.deletingPathExtension().lastPathComponent
    }
    
    static func mmpkDirectoryName(for item: AGSPortalItem) throws -> String {
        guard item.type == .mobileMapPackage else {
            throw InvalidType()
        }
        return "\(item.itemID).mmpk"
    }
    
    // MARK:- Errors
    
    struct InvalidType: LocalizedError {
        let localizedDescription: String = "Invalid portal item type."
    }
}
