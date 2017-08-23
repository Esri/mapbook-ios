# Offline Mapbook

## App Developer Patterns
Now that the mobile map package has been created and published, it can be downloaded by the app using an authenticated connection.

## Identity
The Mapbook App leverages the ArcGIS [identity](https://developers.arcgis.com/authentication/) model to provide access to resources via the the [named user](https://developers.arcgis.com/authentication/#named-user-login) login pattern. During the routing workflow, the app prompts you for your organization’s ArcGIS Online credentials used to obtain a token later consumed by the Portal and routing service. The ArcGIS Runtime SDKs provide a simple to use API for dealing with ArcGIS logins.

The process of accessing token secured services with a challenge handler is illustrated in the following diagram.

![](/docs/images/identity.png)

1. A request is made to a secured resource.
2. The portal responds with an unauthorized access error.
3. A challenge handler associated with the identity manager is asked to provide a credential for the portal.
4. A UI displays and the user is prompted to enter a user name and password.
5. If the user is successfully authenticated, a credential (token) is incuded in requests to the secured service.
6. The identity manager stores the credential for this portal and all requests for secured content includes the token in the request.

The `AGSOAuthConfiguration` class takes care of steps 1-6 in the diagram above. For an application to use this pattern, follow these [guides](https://developers.arcgis.com/authentication/signing-in-arcgis-online-users/) to register your app.
``` Swift
let oauthConfig = AGSOAuthConfiguration(portalURL: portal.url, clientID: clientId, redirectURL: oAuthRedirectURL)
AGSAuthenticationManager.shared().oAuthConfigurations.add(oauthConfig)
```

Any time a secured service issues an authentication challenge, the `AGSOAuthConfiguration` and the app's `UIApplicationDelegate` work together to broker the authentication transaction. The `oAuthRedirectURL` above tells iOS how to call back to the Maps App to confirm authentication with the Runtime SDK.

iOS knows to call the `UIApplicationDelegate` with this URL, and we pass that directly to an ArcGIS Runtime SDK helper function to retrieve a token:

``` Swift
// UIApplicationDelegate function called when "maps-app-ios://auth" is opened.
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    // Pass the OAuth callback through to the ArcGIS Runtime helper function
    AGSApplicationDelegate.shared().application(app, open: url, options: options)

    // Let iOS know we handled the URL OK
    return true
}
```

To tell iOS to call back like this, the Maps App configures a `URL Type` in the `Info.plist` file.

![OAuth URL Type](/docs/images/configure-url-type.png)

Note the value for URL Schemes. Combined with the text `auth` to make `mapbook-ios://auth`, this is the [redirect URI](https://developers.arcgis.com/authentication/browser-based-user-logins/#configuring-a-redirect-uri) that you configured when you registered your app [here](https://developers.arcgis.com/). For more details on the user authorization flow, see the [Authorize REST API](http://resources.arcgis.com/en/help/arcgis-rest-api/#/Authorize/02r300000214000000/).

For more details on configuring the Maps App for OAuth, see [the main README.md](/README.md#2-configuring-the-project)

### Identify
Identify lets you recognize features on the map view. To know when the user interacts with the map view you need to adopt the `AGSGeoViewTouchDelegate` protocol. The methods on the protocol inform about single tap, long tap, force tap etc. To identify features, the tapped location is used with the idenitfy method on map view.

```swift

    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {

        //identify
        self.mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResultsPerLayer: 10) { [weak self] (identifyLayerResults, error) in

            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }

            guard let results = identifyLayerResults else {
                SVProgressHUD.showError(withStatus: "No features at the tapped location", maskType: .gradient)
                return
            }

            //Show results
        }
    }
```
The API provides the ability to identify multiple layer types, with results being stored in `subLayerContent`. Developers should note that if they choose to identify other layer types, like `AGSArcGISMapImageLayer` for example, they would need to add that implementation themselves.

### Displaying Identify Results

Results of the identify action are displayed using [`PopUp`](https://developers.arcgis.com/ios/latest/swift/guide/essential-vocabulary.htm#GUID-3FD39DD2-FFEF-4010-9B90-09BF1E230E8F). The geo element identified are used to iniatialize popups. And these popups are shown using `AGSPopupsViewController`.

```swift
var popups:[AGSPopup] = []

for result in results {
    for geoElement in result.geoElements {
        let popup = AGSPopup(geoElement: geoElement)
        popups.append(popup)
    }
}

//show using popups view controller
let popupsVC = AGSPopupsViewController(popups: popups, containerStyle: AGSPopupsViewControllerContainerStyle.navigationController)
popupsVC.delegate = self
self.present(popupsVC, animated: true, completion: nil)
```
![Identify Results](/docs/images/identify-results.png)

### TOC & Legend

Layer visibility can be toggled in the table of contents (TOC). In addition to the layer name, a list of legends is also shown for each layer. Legends for each operational layer or its sublayer or sub sublayer or so on are fetched and populated into a table view controller. The table view has two kinds of cell. One for the layer, to display layer name and provide ability to toggle on/off. The other for the legends for that layer, displaying its swatch and name.

```swift
/*
 Populate legend infos recursively, for sublayers.
*/
private func populateLegends(with layers:[AGSLayer]) {

    for layer in layers {

        if layer.subLayerContents.count > 0 {
            self.populateLegends(with: layer.subLayerContents as! [AGSLayer])
        }
        else {
            //else if no sublayers fetch legend info
            self.content.append(layer)
            layer.fetchLegendInfos { [weak self, constLayer = layer] (legendInfos, error) -> Void in

                guard error == nil else {
                    //show error
                    return
                }

                if let legendInfos = legendInfos, let index = self?.content.index(of: constLayer) {
                    self?.content.insert(contentsOf: legendInfos as [AGSObject], at: index + 1)
                    self?.tableView.reloadData()
                }
            }
        }
    }
}

```
![TOC & Legend](/docs/images/legend.png)

### Bookmarks

A `Bookmark` identifies a particular geographic location and time on an ArcGISMap.  In the mapbook app, the list of bookmarks saved in the map are shown in the table view. You can select one to update the map view's viewpoint with the bookmarked viewpoint.

```swift
func setBookmark(_ bookmark:AGSBookmark) {
	guard let viewpoint = bookmark.viewpoint else {
	   return
	}    
	self.mapView.setViewpoint(viewpoint, completion: nil)
}
```
![Bookmarks](/docs/images/bookmarks.png)

### Suggestions & Search

Typing the first few letters of an address into the search bar (e.g. “Str”) shows a number of suggestions. This is using a simple call on the `AGSLocatorTask`.

```swift
func suggestions(for text:String) {

    guard let locatorTask = self.locatorTask else {
        return
    }

    //cancel previous request
    self.suggestCancelable?.cancel()

    self.suggestCancelable = locatorTask.suggest(withSearchText: text) { [weak self] (suggestResults, error) in

        guard error == nil else {
            if let error = error as NSError?, error.code != NSUserCancelledError {
                //Show error
            }
            return
        }

        guard let suggestResults = suggestResults else {
            print("No suggestions")
            return
        }

        //Show results...
    }
}
```

Once a suggestion in the list has been selected by the user, the suggested address is geocoded using the geocode method of the `AGSLocatorTask`.

```swift
func geocode(for suggestResult:AGSSuggestResult) {

    guard let locatorTask = self.locatorTask else {
        return
    }

    self.geocodeCancelable?.cancel()

    self.geocodeCancelable = locatorTask.geocode(with: suggestResult) { (geocodeResults, error) in

        guard error == nil else {
            if let error = error as NSError?, error.code != NSUserCancelledError {
                //Show error
            }
            return
        }

        guard let geocodeResults = geocodeResults else {
            print("No location found")
            return
        }

        //Show results...
    }
}
```
![Suggestions & Search](/docs/images/suggestion.png)

### Check For Mobile Map Package Updates

When in `Portal` mode, every time you start the app or do a `Pull to Refresh` in the `My Maps` view, the app checks for updates for already downloaded packages. If a newer version of the mobile map pacakge is available, the refresh button is enabled.

![Check for Updates](/docs/images/check-for-updates.png)

A portal item for each downloaded package is created and loaded. Then the modified date of the portal item is compared with the download date of the local package. Thats how it know if an update is available.

```swift
func checkForUpdates(completion: (() -> Void)?) {

    //if portal is nil. Should not be the case
    if self.portal == nil {
        completion?()
        return
    }

    //clear updatable item IDs array
    self.updatableItemIDs = []

    //use dispatch group to track multiple async completion calls
    let dispatchGroup = DispatchGroup()

    //for each package
    for package in self.localPackages {

        dispatchGroup.enter()

        //create portal item
        guard let portalItem = self.createPortalItem(forPackage: package) else {
            dispatchGroup.leave()
            continue
        }

        //load portal item
        portalItem.load { [weak self] (error) in

            dispatchGroup.leave()

            guard error == nil else {
                return
            }

            //check if updated
            if let downloadedDate = self?.downloadDate(of: package),
                let modifiedDate = portalItem.modified,
                modifiedDate > downloadedDate {

                //add to the list
                self?.updatableItemIDs.append(portalItem.itemID)
            }
        }
    }

    dispatchGroup.notify(queue: .main) {
        //call completion once all async calls are completed
        completion?()
    }
}
```
