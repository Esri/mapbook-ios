# Offline Mapbook

## App Modes

The app supports both connected and disconnected workflow. You can operate the app in the `Device` mode if the mobile map packages will be side-loaded on to the device. Meaning, the device does not have access to internet/intranet and the packages are added either via iTunes or using a Mobile Device Management (MDM) system. Otherwise, if the device has internet connection and there are packages available online then you can operate the app in the `Portal` mode. In this mode, you can connect to a portal online and download mobile map packages on to the device. The `Portal` mode also allows you to update downloaded packages if a new version is available online.

![App Modes](/docs/images/app-mode.png)

You can switch between the modes anytime in the app but with consequences. Switching from `Device` to `Portal` you will loose any local packages. And for a switch from `Portal` to `Device` in addition to loosing the downloaded packages, you will be logged out of your portal account. This is to enforce that the app could be in one and only one mode at a time.

## App Developer Patterns
Now that the mobile map package has been created and published, it can be downloaded by the app using an authenticated connection.

### Identity
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

## Create Your Own Mobile Map Packages

Learn how to create and share mobile map packages so that you can take your organization's maps offline and view them in this app.

Below we show you the steps for authoring and packaging a mobile map package with the help of an example.

### Data scenario
In this example, an employee of the fictitious 'Naperville Water Company' requires offline access to the following types of data while out in the field:

- An 811 map displaying locations of water mains and lines that should be marked when citizens call '811'
- An emergency response map displaying locations of water valves and their associated mains that might need to be turned off in the case of an emergency leak
- A capital improvement project (CIP) map displaying locations of newly-proposed water mains and water lines that need to either be further assessed or established

The table below summarizes the layers within each map that are visible by default:

| Layer                   | 811 Map | Emergency Response Map | CIP Map |
|:------------------------|:-------:|:----------------------:|:-------:|
| **Water Lateral Lines** | X       |                        | X       |
| **Water Mains**         | X       | X                      | X       |
| **Water System Valves** |         | X                      |         |
| **Reference Backdrop**  | X       | X                      | X       |

### Authoring the data for viewing

#### Setting symbology
It is important that each map be made to look unique and effectively convey its purpose. In order to achieve this, field attributes were chosen that were most relevant to the map's intended goal and then symbolized using a unique value renderer. In many cases, this yielded multiple classes being represented per layer. The following table identifies the attribute chosen for each layer on a per-map basis.

| Layer                   | 811 Map       | Emergency Response Map | CIP Map         |
|:------------------------|:-------------:|:----------------------:|:---------------:|
| **Water Lateral Lines** | pipe material |                        | proposal status |
| **Water Mains**         | pipe material | pipe diameter          | proposal status |
| **Water System Valves** |               | valve type             |                 |

#### Creating a reference backdrop
To keep the mobile map package (.mmpk) as small as possible, the reference layer was packaged into a .vtpk or [vector tile package](http://pro.arcgis.com/en/pro-app/help/sharing/overview/vector-tile-package.htm) and used as basemap within each map. For more information about how to create a vector tile package, see the help topic for the [Create Vector Tile Package](http://pro.arcgis.com/en/pro-app/tool-reference/data-management/create-vector-tile-package.htm) geoprocessing tool.

#### Creating locators
The Offline Mapbook app supports geocoding and search so a [locator](http://desktop.arcgis.com/en/arcmap/10.3/guide-books/geocoding/essential-geocoding-vocabulary.htm) was built for each layer in the app by using the [Create Address Locator](http://pro.arcgis.com/en/pro-app/tool-reference/geocoding/create-address-locator.htm) geoprocessing tool once per layer. Most crucial to this part of the workflow was that 'General - Single Field' was chosen for the "Address Locator Style". This style is useful for allowing searching of the contents within a single field, which was sufficient for the purpose of app.

The following layers in the app are searchable:
- Water Lateral Lines
- Water Mains
- Water System Valves
- Address Points

Once an address locator, or .loc file, is created for each layer, it was time to run the [Create Composite Address Locator](http://pro.arcgis.com/en/pro-app/tool-reference/geocoding/create-composite-address-locator.htm) geoprocessing tool. The Create Composite Locator tool allows multiple, individual .loc files to be specified as an input so that it can package the contents into a single resulting _composite_ .loc file. Worth noting is that a composite address locator does not store the address indexing information as would a standalone .loc file, but rather references the data from the input locators that are specified when it's generated. This composite locator (.loc) file was later specified when building the mobile map package.

#### Setting bookmarks
The Offline Mapbook app supports viewing of predefined, bookmarked locations. Two [bookmarks](http://pro.arcgis.com/en/pro-app/help/mapping/navigation/bookmarks.htm) were set in ArcGIS Pro for each map and are included in the mobile map package.

#### Metadata and thumbnails
Before finalizing the maps for publishing, metadata was created for each map. The Title and Summary properties for each map are accessed in ArcGIS Pro by opening the Map Properties window, double clicking the map title from the Contents pane, and clicking the Metadata tab within. Like the map title and summary, a map thumbnail can also provide context. The thumbnail image for a map can be generated in ArcGIS Pro by right clicking a map's title in the Contents pane and selecting 'Create Thumbnail' from the context menu that appears. The created thumbnail can be viewed by hovering the mouse cursor over the map from the Project pane under the 'Maps' section.

### Packaging for consumption
In order for this data to be consumed within the Mapbook app, it had to first be published as an .mmpk or ([mobile map package](http://pro.arcgis.com/en/pro-app/help/sharing/overview/mobile-map-package.htm)). An .mmpk file can either be hosted on a portal and downloaded automatically prior to running the app or, in this case, side-loaded onto the device and placed beside the app prior to running it. This subsection describes using the [Create Mobile Map Package](http://pro.arcgis.com/en/pro-app/tool-reference/data-management/create-mobile-map-package.htm) geoprocessing tool specifically for the purpose of packaging the data that was created for the Offline Mapbook app.

#### Including multiple maps
Because multiple maps were authored to be used for the Offline Mapbook app, multiple maps had to be specified when running the Create Mobile Map Package tool. The first parameter of the tool is 'Input Map' and can accommodate for the specification of multiple entries. By default, each dropdown will present a list of maps that exist within the current ArcGIS Pro project. For this mobile-map-packaging, each of the three maps was specified once.

![Multiple Maps](assets/MulitpleMaps_MMPK.png)

#### Including the locator
Although a mobile map package supports multiple input locators, we simplified this process by creating a single, composite locator which references the four source locators being used. Given that this is the case, only the composite locator needed to be specified within the tool. Alternatively, the extra step of creating the composite locator and instead specifying the individual locators as inputs to the tool will work as well.

### Sharing the mobile map package
Once the .mmpk file has been created, ArcGIS provides two possible mechanisms for making a mobile map package available within a Portal for ArcGIS or on ArcGIS Online.

#### Using the ArcGIS Pro 'Share Package' tool
The first method for getting a locally-saved mobile map package to a Portal for ArcGIS or on ArcGIS Online is to 'push' it using a dedicated geoprocessing tool. This tool, called the [Share Package](http://pro.arcgis.com/en/pro-app/tool-reference/data-management/share-package.htm) tool takes an input .mmpk file (as well as a host of other types of package files created using ArcGIS) and uploads it to the desired destination. In lieu of the tool requesting credentials, these are instead retrieved from ArcGIS Pro itself. Since the credentials passed in to the current session of Pro dictate the destination Portal to which the package will be shared, it's helpful to be aware of with which credentials you're logged in before running the tool!

#### Uploading directly from the 'My Content' page
The second method for getting a locally-saved mobile map package to a Portal for ArcGIS or on ArcGIS Online is to 'pull' it using the [Add Item](http://doc.arcgis.com/en/arcgis-online/share-maps/add-items.htm) tool. This can be found from the 'My Content' page and is as simple as browsing for the local file, providing a title and some tags, and clicking 'ADD ITEM'.
