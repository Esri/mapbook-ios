# Mapbook iOS
This repo is home to the mobile mapbook app, an example application using the [ArcGIS Runtime SDK for iOS](https://developers.arcgis.com/ios/). Replace the paper maps you use for field work with offline maps.

<!-- MDTOC maxdepth:6 firsth1:0 numbering:0 flatten:0 bullets:1 updateOnSave:1 -->

- [Features](#features)   
- [Best Practices](#best-practices)   
- [Detailed Documentation](#detailed-documentation)   
- [Get Started](#get-started)   
   - [Fork the repo](#fork-the-repo)   
   - [Clone the repo](#clone-the-repo)   
      - [Command line Git](#command-line-git)   
   - [Configuring a Remote for a Fork](#configuring-a-remote-for-a-fork)   
   - [Configure the app](#configure-the-app)   
      - [1. Register an Application](#1-register-an-application)   
      - [2. Configuring the project](#2-configuring-the-project)   
      - [3. License the app (Optional)](#3-license-the-app-optional)   
- [Learn More](#learn-more)   
- [Requirements](#requirements)   
- [Contributing](#contributing)   
- [MDTOC](#mdtoc)   
- [Licensing](#licensing)   

<!-- /MDTOC -->
---

## Features
- Mobile map packages
- Feature layers
- Identify
- Table of Contents
- Show a legend
- Use a map view callout
- Geocode addresses
- Suggestion search
- Bookmarks
- Sign in to your portal

## Best Practices
The project also demonstrates some patterns for building real-world apps around the ArcGIS Runtime SDK.

* Defining a modular, decoupled UI that operates alongside a map view
* Asynchronous service and UI coding patterns
* Internal application communication patterns
* FileManager used with ArcGIS

## Detailed Documentation
Read the [docs](./docs/README.md) for a detailed explanation of the application, including its architecture and how it leverages the ArcGIS platform, as well as how you can begin using the app right away.

## Get Started
Make sure you've installed Xcode and the ArcGIS Runtime SDK for iOS and that they meet these [requirements](#requirements).

### Fork the repo
**Fork** the [Mapbook App](https://github.com/Esri/mapbook-ios/fork) repo.

### Clone the repo
Once you have forked the repo, you can make a clone.

> Make sure to use the "recursive" option to ensure you get the **ArcGIS Runtime Toolkit** submodule
>
>`git clone --recursive [URL to forked Git repo]`
>
> If you've already cloned the repo without the submodule, you can load the submodule using
>
>`git submodule update --init`

#### Command line Git
1. [Clone the Mapbook App](https://help.github.com/articles/fork-a-repo#step-2-clone-your-fork)
1. ```cd``` into the ```mapbook-ios``` folder
1. Make your changes and create a [pull request](https://help.github.com/articles/creating-a-pull-request)

### Configuring a Remote for a Fork
If you make changes in the fork and would like to [sync](https://help.github.com/articles/syncing-a-fork/) those changes with the upstream repository, you must first [configure the remote](https://help.github.com/articles/configuring-a-remote-for-a-fork/). This will be required when you have created local branches and would like to make a [pull request](https://help.github.com/articles/creating-a-pull-request) to your upstream branch.

1. In the Terminal (for Mac users) or command prompt (fow Windows and Linus users) type ```git remote -v``` to list the current configured remote repo for your fork.
1. ```git remote add upstream https://github.com/Esri/mapbook-ios.git``` to specify new remote upstream repository that will be synced with the fork. You can type ```git remote -v``` to verify the new upstream.

If there are changes made in the original repository, you can sync the fork to keep it updated with upstream repository.

1. In the terminal, change the current working directory to your local project
1. Type ```git fetch upstream``` to fetch the commits from the upstream repository
1. ```git checkout master``` to checkout your fork's local master branch.
1. ```git merge upstream/master``` to sync your local `master` branch with `upstream/master`. **Note**: Your local changes will be retained and your fork's master branch will be in sync with the upstream repository.

### Configure the app
Before running the app, it must be configured with application credentials. Follow the steps below to obtain application credentials used for browsing and downloading Portal content.

1. Register an ArcGIS Portal Application.
1. Configure the Mapbook App project to reference that application.
1. License the app to remove the Developer Mode watermark.

#### 1. Register an Application
For OAuth configuration, create a new Application in your ArcGIS Portal to obtain a `Client ID` and configure a `Redirect URL`. The **Client ID** configures the ArcGIS Runtime to show your users, during the log in process, that the application was built by you and can be trusted. The **Redirect URL** configures the OAuth process to then return to your app once authentication is complete.

1. Log in to [https://developers.arcgis.com](https://developers.arcgis.com) with either your ArcGIS Organizational Account or an ArcGIS Developer Account.
1. Visit your [dashboard](https://developers.arcgis.com/dashboard) and [create a new application](https://developers.arcgis.com/applications/new).
1. In the Authentication tab, note the **Client ID**
1. In the Authentication tab **add a redirect URI** to the **Current Redirect URIs** section. By default the Xcode project is configured to authentication callbacks using:
> **mapbook://auth**

#### 2. Configuring the project

**Configure Redirect URL**

1. Open the project in Xcode and browse to the `mapbook-iOS` target's `Info` panel and expand the `AGSConfiguration` dictionary _(see steps 1-4 in the screenshot below)_.
![Configure the App URL Scheme](/docs/images/configure-xcode-url-scheme.png)
1. Set the `AppURLScheme` value to match the **Redirect URL** scheme configured in "Register an Application" above. The scheme is the app name that comes before `://` in the redirect URI.
> **mapbook**://auth

1. Expand the **URL Types** section and modify the existing entry.
    - The **Identifier** doesn't matter, but should be unique.
    > ex: **com.esri.mapbook**
    - The **URL Scheme** should match the **Redirect URL** scheme configured in "Register an Application" above. The scheme is the app name that comes before `://` in the redirect URI.
    > **mapbook**://auth

  ![Configure the App URL Scheme](/docs/images/configure-app-settings.png)

**Configure Client ID**

1. In the Navigator pane under the project, find the file named `AppSettings.swift`.
1. Within `AppSettings.swift` set the value of the static variable `clientID` to the application's **Client ID** noted in the step 'Register an Application'.

#### 3. License the app (Optional)

This step is optional during development, but _required_ for deployment.

1. Access your [dashboard](https://developers.arcgis.com/dashboard) and get your Runtime Lite license key.
1. Open the project in Xcode and navigate to `AppSettings.swift`, the same file used to configure your applications client id.
1. Set the value of the static variable `licenseKey` to the value from step 1.

## Learn More
Learn more about the App Architecture and usage [here](/docs/index.md).

## Requirements
* [Xcode 12 and Swift 5](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)
* [ArcGIS Runtime SDK for iOS](https://developers.arcgis.com/ios/), version 100.10.
* [ArcGIS Runtime Toolkit for iOS](https://github.com/Esri/arcgis-runtime-toolkit-ios), version 100.10.
* Device or Simulator running iOS 13.0 or later.

**Note:** Starting from the 100.8 release, the ArcGIS Runtime SDK for iOS uses Apple's Metal framework to display maps and scenes. However, Xcode does not support Metal based rendering in any version of iOS simulator on macOS Mojave. If you are developing map or scene based apps in these environments, you will need test and debug them on a physical device instead of the simulator.

**Note:** The 100.10 release of the ArcGIS Runtime SDK for iOS replaces the installed "fat framework" `ArcGIS.framework` with a new binary framework `ArcGIS.xcframework`.  It also changes the location of the installed framework file and removes the need for the `strip-frameworks.sh` Build Phase.  These changes have been incorporated in the lastest release of *Mapbook iOS*.

## Contributing
Anyone and everyone is welcome to [contribute](CONTRIBUTING.md). We do accept pull requests.

1. Get involved
1. Report issues
1. Contribute code
1. Improve documentation

## MDTOC
Generation of this and other documents' table of contents in this repository was performed using the [MDTOC package for Atom](https://atom.io/packages/atom-mdtoc).

## Licensing
Copyright 2017 Esri

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

A copy of the license is available in the repository's [LICENSE](LICENSE) file.

For information about licensing your deployed app, see [License your app](https://developers.arcgis.com/ios/license-and-deployment/).
