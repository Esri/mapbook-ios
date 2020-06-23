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

class PortalAuthViewController: UIViewController {
        
    override func viewDidLoad() {
        
        embedViewControllerForPortalSessionState()
        
        NotificationCenter.default
            .addObserver(forName: .portalSessionStatusDidChange,
                         object: nil,
                         queue: .main,
                         using: respondToPortalSessionStatusDidChangeNotification)
    }
    
    private func respondToPortalSessionStatusDidChangeNotification(_ notification: Notification) {
        
        switch appContext.sessionManager.status {
        case .failed(let error):
            flash(error: error)
            break
        default:
            break
        }
        
        embedViewControllerForPortalSessionState()
    }
    
    private func embedViewControllerForPortalSessionState() {
        if appContext.sessionManager.isSignedIn {
            performSegue(withIdentifier: .embedMyPortalSegueID, sender: nil)
        }
        else {
            performSegue(withIdentifier: .embedPortalSignInSegueID, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard segue is PortalAuthSegue else { return }
        
        if let current = current {
            
            if segue.identifier == .embedMyPortalSegueID && current is PortalHomeViewController { return }
    
            else if segue.identifier == .embedPortalSignInSegueID && current is PortalSignInViewController { return }
            
            transitionToViewController(segue.destination)
        }
        else {
            transitionToViewController(segue.destination)
        }
        
        if let home = segue.destination as? PortalHomeViewController,
            let portal = appContext.sessionManager.portal {
            home.configureViewWith(portal: portal)
        }
    }
    
    private var current: UIViewController?
    
    private func transitionToViewController(_ to: UIViewController) {
        
        // Add destination
        
        func addAndConstrainViewControllerView(_ to: UIViewController) {
            
            to.view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(to.view)
            self.view.sendSubviewToBack(to.view)
            
            let top = to.view.topAnchor.constraint(equalTo: view.topAnchor)
            let trailing = to.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            let bottom = to.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            let leading = to.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            
            NSLayoutConstraint.activate([top, trailing, bottom, leading])
        }
        
        // This is not the first time a child view controller is embed, swap the two view controllers.
        if let from = current {
            
            // 1. Send message that view controller will be removed from parent.
            from.willMove(toParent: nil)
            
            // 2. Remove previous view controller view (automatically removes auto layout constraints).
            from.view.removeFromSuperview()
            
            // 3. Remove child view controller from parent container.
            from.removeFromParent()
        }
        
        // 4. Add view controller view as subview.
        addAndConstrainViewControllerView(to)
        
        // 5. Add child view controller to parent.
        addChild(to)
        
        // 6. Send message that view controller was added to parent and will appear.
        to.didMove(toParent: self)
        
        // 7. Point to current view controller.
        current = to
           
        // 8. Set title.
        title = current?.title
        
        // 9. Finish.
        view.layoutIfNeeded()
    }
    
    @IBAction func userRequestsDismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

private extension String {
    static let embedMyPortalSegueID = "embedPortalHome"
    static let embedPortalSignInSegueID = "embedSignInToPortal"
}

class PortalAuthSegue: UIStoryboardSegue {
    override func perform() { }
}
