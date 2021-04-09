# v2.0.4

- Certification for the 100.11.0 release of the ArcGIS Runtime SDK for iOS.
- Removes now-unused app delegate method.
- Introduces `ArcGIS` and `ArcGISToolkit` as Swift Package Manager dependencies.

# v2.0.3

- The 100.10.0 release of the ArcGIS Runtime for iOS is now distributed as a binary framework.  This necessitated the following changes in the Mapbook Xcode project file:
    - The `ArcGIS.framework` framework has been replaced with `ArcGIS.xcframework`.
    - The Build Phase which ran the `strip-frameworks.sh` shell script is no longer necessary.
- Certification for the 100.10.0 release of the ArcGIS Runtime SDK for iOS.
- Increments app deployment targets to iOS 13.0, drops support for iOS 12.0.
- Updates the ArcGIS Toolkit submodule to v100.10.0

# v2.0.2

- Hides update button for portal mobile map package if package is current.
- Certification for the 100.9.0 release of the ArcGIS Runtime SDK for iOS.

# v2.0.1

- Adds doc table of contents to root README.md and docs/index.md
- Renames docs/index.md to [docs/README.md](/docs/README.md)

# v2.0.0

* Brand new UI & UX
* Re-writes underlying app architecture
* Introduces support for Universal Layout (iPhone & iPad), a new Apple requirement
* Introduces Toolkit dependency, Bookmarks
* Reworks Locator Search
* Introduces preliminary accessibility measure for label dynamic text resizing
* Introduces support for Dark Mode

# v1.1.5

* Certification for the 100.8.0 release of the ArcGIS Runtime SDK for iOS.

# v1.1.4

* Fixes featureLayer deprecation.
* Updates minimum deployment target to match that supported by ArcGIS iOS Runtime SDK.
* Turns off metal validation -> fixes iOS 12 device crash.
* New bundle ID.

# v1.1.3

* Certification for the 100.7.0 release of the ArcGIS Runtime SDK for iOS.

# v1.1.2

* Adds [app documentation](/docs/README.md) from the ArcGIS for Developers site.

# v1.1.1

* Support for iOS 13
