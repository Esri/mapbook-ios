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

protocol PortalSessionManagerDelegate: class {
    func portalSessionManager(manager: PortalSessionManager, didChangeStatus status: PortalSessionManager.Status)
}

class PortalSessionManager {
    
    // MARK:- Portal
    
    var portal: AGSPortal? {
        switch status {
        case .loaded(let portal):
            return portal
        default:
            return nil
        }
    }
    
    // MARK:- Status
    
    enum Status {
        case none, loading, loaded(AGSPortal), failed(Error)
    }
    
    var status: Status = .none {
        didSet {
            
            switch status {
            case .loaded(let portal):
                UserDefaults.standard.set(portal.url, forKey: Self.portalSessionURLKey)
            default:
                UserDefaults.standard.set(nil, forKey: Self.portalSessionURLKey)
            }
            
            delegate?.portalSessionManager(manager: self, didChangeStatus: status)
        }
    }
    
    var isSignedIn: Bool {
        switch status {
        case .loaded(_):
            return true
        default:
            return false
        }
    }
    
    // MARK:- Restore Session
    
    private static let portalSessionURLKey = "\(Bundle.main.bundleIdentifier!).portalSessionManager.urlKey"
    
    private func restorePortalIfPossible() {
        
        guard case Status.none = status else { return }
        
        guard let url = UserDefaults.standard.url(forKey: Self.portalSessionURLKey) else {
            self.revokeAndDisableAutoSyncToKeychain { }
            return
        }
        
        status = .loading

        enableAutoSyncToKeychain()
        
        let newPortal = AGSPortal(url: url, loginRequired: true)
        
        // We'll temporarily disable prompting the user to sign in in case the cached credentials are not suitable to sign us in.
        // I.e. if the cached credentials aren't good enough to find ourselves signed in to the portal/ArcGIS Online, then just
        // accept it and don't prompt us to sign in, resulting in a Portal being accessed anonymously.
        // We revert from that behaviour as soon as the portal loads below.
        let originalPortalRC = newPortal.requestConfiguration
        let sourceRC = originalPortalRC ?? AGSRequestConfiguration.global()
        let silentAuthRC = sourceRC.copy() as? AGSRequestConfiguration
        
        silentAuthRC?.shouldIssueAuthenticationChallenge = { _ in return false }
        
        newPortal.requestConfiguration = silentAuthRC
        
        newPortal.load() { [weak self] error in
            
            guard let self = self else { return }

            // Before we do anything else, go back to handling auth challenges as before.
            newPortal.requestConfiguration = originalPortalRC

            if let error = error {
                self.revokeAndDisableAutoSyncToKeychain {
                    DispatchQueue.main.async {
                        self.status = .failed(error)
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    self.status = .loaded(newPortal)
                }
            }
        }
    }
    
    // MARK:- Sign In
    
    func signIn(to portal: AGSPortal, completion: @escaping (Status) -> Void) {
        
        if case Status.loading = status { return }
        
        status = .loading
        
        enableAutoSyncToKeychain()
        
        portal.load { [weak self] (error) in
            guard let self = self else { return }
            
            if let error = error {
                self.status = .failed(error)
            }
            else {
                self.status = .loaded(portal)
            }
            
            completion(self.status)
        }
    }
    
    // MARK:- Sign Out
    
    func signOut() {
        revokeAndDisableAutoSyncToKeychain { [weak self] in
            guard let self = self else { return }
            self.status = .none
        }
    }
    
    // MARK:- Credential
    
    private static let autoSyncToKeychainID = "\(Bundle.main.bundleIdentifier!).autoSyncToKeychain"
    
    private func enableAutoSyncToKeychain() {
        AGSAuthenticationManager.shared()
            .credentialCache
            .enableAutoSyncToKeychain(withIdentifier: Self.autoSyncToKeychainID, accessGroup: nil, acrossDevices: false)
    }
    
    private func revokeAndDisableAutoSyncToKeychain(_ completion: @escaping ()->Void) {
        AGSAuthenticationManager.shared()
            .credentialCache
            .removeAndRevokeAllCredentials { (_) in
                AGSAuthenticationManager.shared().credentialCache.disableAutoSyncToKeychain()
                completion()
            }
    }
    
    // MARK:- Init
    
    init() {
        enableAutoSyncToKeychain()
        restorePortalIfPossible()
    }
    
    // MARK:- Delegate
    
    weak var delegate: PortalSessionManagerDelegate?
}
