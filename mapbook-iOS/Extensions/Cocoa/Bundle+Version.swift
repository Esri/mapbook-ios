//
// Copyright 2018 Esri.
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

import ArcGIS

extension Bundle {
    
    private static let agsBundle = AGSBundle()
    
    /// An end-user printable string representation of the ArcGIS Bundle version shipped with the app.
    ///
    /// For example, "2000"
    
    static var sdkBundleVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    
    /// An end-user printable string representation of the ArcGIS Runtime SDK version shipped with the app.
    ///
    /// For example, "100.0.0"
    
    static var sdkVersion: String {
        return (agsBundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    
    /// Builds an end-user printable string representation of the ArcGIS Bundle shipped with the app.
    ///
    /// For example, "ArcGIS Runtime SDK 100.0.0 (2000)"
    
    static var ArcGISSDKVersionString: String {
        return "ArcGIS Runtime SDK \(sdkVersion) (\(sdkBundleVersion))"
    }
}

extension Bundle {
    
    /// An end-user printable string representation of the app display name.
    ///
    /// For example, "Mapbook"
    
    static var appDisplayName: String {
        return (main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "?"
    }
    
    /// An end-user printable string representation of the app version number.
    ///
    /// For example, "1.1"
    
    static var appVersion: String {
        return (main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
    }
    
    /// An end-user printable string representation of the app bundle number.
    ///
    /// For example, "1"
    
    static var appBundleVersion: String {
        return (main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
    }
    
    /// Builds an end-user printable string representation of the app name and version.
    ///
    /// For example, "Mapbook 1.1 (1)"
    
    static var AppNameVersionString: String {
        return "\(appDisplayName) \(appVersion) (\(appBundleVersion))"
    }
}

protocol BundleAware { }

extension BundleAware {
    
    var appNameVersionString: String {
        Bundle.AppNameVersionString
    }
    
    var arcGISSDKVersionString: String {
        Bundle.ArcGISSDKVersionString
    }
}
