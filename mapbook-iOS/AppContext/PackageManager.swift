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
    
    func downloadedURL(for item: AGSPortalItem) throws -> URL {
        let mmpkName = try PortalAwareMobileMapPackage.mmpkDirectoryName(for: item)
        return try FileManager.default.touchDownloadedDirectory().appendingPathComponent(mmpkName)
    }
    
    func temporaryURL(for item: AGSPortalItem) throws -> URL {
        let mmpkName = try PortalAwareMobileMapPackage.mmpkDirectoryName(for: item)
        return try FileManager.default.touchTemporaryDirectory().appendingPathComponent(mmpkName)
    }
    
    fileprivate func hasDownloaded(item: AGSPortalItem) throws -> Bool {
        let mmpkName = try PortalAwareMobileMapPackage.mmpkDirectoryName(for: item)
        let url = URL.downloaded.appendingPathComponent(mmpkName)
        return FileManager.default.fileExists(atPath: url.path)
    }
}

protocol PackageManagerDelegate: class {
    
    func packageManager(_ manager: PackageManager, enqueued item: AGSPortalItem)
    func packageManager(_ manager: PackageManager, failed error: Error, item: AGSPortalItem)
    func packageManager(_ manager: PackageManager, downloaded item: AGSPortalItem, to path: URL)
}

class PackageManager {
    
    weak var portal: AGSPortal?
    
    // MARK:- Download
    
    func isCurrentlyDownloading(item id: String) -> Bool {
        downloadQueue.operations.contains(where: { ($0 as! PortalItemRequestOperation).item.itemID == id })
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
                
        do {
            temporaryURL = try FileManager.default.temporaryURL(for: item)
            downloadedURL = try FileManager.default.downloadedURL(for: item)
            operation = try PortalItemRequestOperation(portal: portal, item: item)
        }
        catch {
            delegate?.packageManager(self, failed: MissingDirectory(), item: item)
            return
        }
        
        operation.outputFileURL = temporaryURL
        operation.registerListener(self) { [weak self] (result, error) in
            
            guard let self = self else { return }
            
            guard error == nil else {
                try? FileManager.default.removeItem(at: temporaryURL)
                DispatchQueue.main.async {
                    self.delegate?.packageManager(self, failed: error!, item: item)
                }
                return
            }
            
            do {
                _ = try FileManager.default.replaceItemAt(downloadedURL, withItemAt: temporaryURL)
            }
            catch {
                DispatchQueue.main.async {
                    self.delegate?.packageManager(self, failed: error, item: item)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.delegate?.packageManager(self, downloaded: item, to: downloadedURL)
            }
        }
        
        downloadQueue.addOperation(operation)
        delegate?.packageManager(self, enqueued: item)
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
    
    func update(package: PortalAwareMobileMapPackage, completion: @escaping(Error?) -> Void) {
        
        guard let portal = portal else { completion(UnknownError()); return }
        
        guard let itemID = package.itemID else { completion(MissingPortalCounterpart()); return }
        
        let portalItem = AGSPortalItem(portal: portal, itemID: itemID)
        
        portalItem.load { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            do {
                try self.download(item: portalItem)
                completion(nil)
            }
            catch {
                completion(error)
            }
        }
    }
    
    // MARK:- Operation Queue
    
    private var downloadQueue: AGSOperationQueue = {
        let queue = AGSOperationQueue()
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    func fetchDownloadingPackages() -> [AGSPortalItem] {
        downloadQueue.operations.map { ($0 as! PortalItemRequestOperation).item }
    }
    
    // MARK:- Local

    func hasDownloaded(item: AGSPortalItem) throws -> Bool {
        try FileManager.default.hasDownloaded(item: item)
    }
    
    func fetchDownloadedPackages(_ completion: @escaping (Result<[PortalAwareMobileMapPackage], Error>) -> Void) throws {
        
        let packages = try FileManager.default.contentsOfDirectory(at: URL.downloaded,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsSubdirectoryDescendants)
            .filter { $0.pathExtension == PortalAwareMobileMapPackage.mmpk }
            .map { PortalAwareMobileMapPackage(fileURL: $0) }
        
        guard packages.count > 0 else {
            completion(.success([PortalAwareMobileMapPackage]()))
            return
        }
        
        AGSLoadObjects(packages) { (completed) in
            
            guard completed else {
                completion(.failure(CouldntLoadPackage()))
                return
            }
            
            completion(.success(packages))
        }
    }
    
    func removeDownloaded(package: AGSMobileMapPackage) throws {
        try FileManager.default.removeItem(at: package.fileURL)
    }
    
    // MARK:- Delegate
    
    weak var delegate: PackageManagerDelegate?
        
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
    
    struct CouldntLoadPackage: LocalizedError {
        let localizedDescription: String = "Couldn't load download package."
    }
    
    struct UnknownError: LocalizedError {
        let localizedDescription: String = "An unknown error occured."
    }
    
    // MARK:- Deinit
    
    deinit {
        downloadQueue.operations.forEach { $0.cancel() }
    }
}

class PortalItemRequestOperation: AGSRequestOperation {
    
    private(set) var item: AGSPortalItem
    
    init(portal: AGSPortal, item: AGSPortalItem) throws {
        
        guard let url = portal.url else {
            throw MissingURLError()
        }
        
        let dataURLString = String(format: "%@/sharing/rest/content/items/%@/data", url.absoluteString, item.itemID)
        
        guard let dataURL = URL(string: dataURLString) else {
            throw InvalidURLError()
        }
                
        self.item = item
        
        super.init(remoteResource: portal, url: dataURL, queryParameters: nil, method: .get)
        
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
        return "\(item.itemID).\(mmpk)"
    }
    
    static var mmpk = "mmpk"
    
    // MARK:- Errors
    
    struct InvalidType: LocalizedError {
        let localizedDescription: String = "Invalid portal item type."
    }
}
