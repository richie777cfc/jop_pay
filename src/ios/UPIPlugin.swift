//
//  UPIPlugin.swift
//  MyJio
//  Copyright © 2021 Jio Platforms Limited. All rights reserved.
//

import UIKit
import Foundation

@objc(UPIPlugin)
class UPIPlugin: CDVPlugin {
    let appName: String = "MyJio"
    
    @objc(supportedApps:)
    func supportedApps(_command: CDVInvokedUrlCommand) {
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: sendPSPAppListDictionary());
        commandDelegate.send(pluginResult, callbackId:_command.callbackId);
      }
    
    @objc(acceptPayment:)
    func acceptPayment(_command: CDVInvokedUrlCommand) {
        let upistr = _command.arguments[0] as? [String:Any]
        launchPSPAppOnClick(urlString: upistr?["upiString"] as? String ?? "")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Initiated");
        commandDelegate.send(pluginResult, callbackId:_command.callbackId);
      }
      
    func sendPSPAppListDictionary() -> [Any] {
        // if--> core data check VPAID
        var myArray = [[String: String]]()
        // third party app content dictionary from iOSAppText
        if let otherPSPIntentArray = getPSPIntentAppsArrayFromAppText(), !otherPSPIntentArray.isEmpty {
            myArray.append(contentsOf: otherPSPIntentArray)
        }
        return myArray
    }
    
    func getPSPIntentAppsArrayFromAppText() -> [[String: String]]? {
        var otherPSPIntentArray = [[String: String]]()
        if let intentAppContentArray = getFilteredUPIIntentApps(), !intentAppContentArray.isEmpty {
            for currentIntentAppDictionary in intentAppContentArray {
                var pspAppIconImageString = ""
                if let iconAsset = currentIntentAppDictionary["IconAsset"] as? String {
                    let pspAppIcon = UIImage.init(named: iconAsset)
                    pspAppIconImageString = pspAppIcon?.convertImageToBase64() ?? ""
                }
                let payTMListDictionary = ["packageName": currentIntentAppDictionary["PackageName"] as? String ?? "", "appName": currentIntentAppDictionary["AppName"] as? String ?? "", "image": pspAppIconImageString] as [String: String]
                
                if let pspAppURLPrefix = currentIntentAppDictionary["AppURLPrefix"] as? String, !pspAppURLPrefix.isEmpty {
                    let urlComponents = URLComponents(string: pspAppURLPrefix)
                    if let urlScheme = urlComponents?.scheme {
                        if let url = URL(string: "\(urlScheme)://"), UIApplication.shared.canOpenURL(url) {
                            otherPSPIntentArray.append(payTMListDictionary)
                        }
                    }
                }
            }
        }
        return otherPSPIntentArray
    }
    func getPSPAppListConfig() -> [[String: Any]]? {
        return [[
            "PackageName": "net.one97.paytm",
            "AppName": "Paytm",
            "IconAsset": "ic_paytm",
            "AppURLPrefix": "paytmmp://upi/pay?"
        ],
        [
            "PackageName": "com.google.android.apps.nbu.paisa.user",
            "AppName": "Google Pay",
            "IconAsset": "ic_gPay",
            "AppURLPrefix": "gpay://upi/pay?"
        ],
        [
            "PackageName": "com.phonepe.app",
            "AppName": "PhonePe",
            "IconAsset": "ic_phonepe",
            "AppURLPrefix": "phonepe://upi/pay?"
        ],
        [
            "PackageName": "com.dreamplug.cred",
            "AppName": "CRED",
            "IconAsset": "ic_credapp",
            "AppURLPrefix": "credpay://upi/pay?",
            "versionNumber": "7.0.15",
            "isVisibleForVersion": 1
        ]
        ]
    }
    
    func getFilteredUPIIntentApps() -> [[String: Any]]? {
        if let intentAppContentArray = getPSPAppListConfig(), !intentAppContentArray.isEmpty {
            return intentAppContentArray
        }
        return nil
    }
    
    func launchPSPAppOnClick(urlString: [String: Any]?) {
        let appIdentifier =  (urlString?["application"] as? [String: Any])?["appId"] as? String ?? ""
        let upiPaymentString = urlString?["upiString"] as? String ?? ""
        print(upiPaymentString as Any)
        if let intentAppContentArray = getFilteredUPIIntentApps(), !intentAppContentArray.isEmpty {
                let currentAppIntentFilteredArray = intentAppContentArray.filter { ($0["PackageName"] as? String ?? "") == appIdentifier }
                if let url = URL(string: upiPaymentString) {
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let queryComponents = components?.percentEncodedQuery
                    let queryScheme = (currentAppIntentFilteredArray.first)?["AppURLPrefix"] ?? ""
                    let appendedURLString = "\(queryScheme)\(queryComponents ?? "")"
                    guard let urlString = appendedURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
                    guard let applicationURL = URL(string: urlString) else {
                        return
                    }
                    UIApplication.shared.open(applicationURL, options: [:]) { (_) in
                        
                    }
                }
        }
    }
    
    func getJsonObjectFromString(urlString: String) -> [String: Any]? {
        if let data = urlString.data(using: .utf8) {
            if let jsonData = try? JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any] {
                return jsonData
            }
        }
        return nil
    }
}

extension UIImage {
    func convertImageToBase64() -> String {
        let imageData = UIImagePNGRepresentation(self)
        let base64String = imageData?.base64EncodedString()
        return base64String ?? ""
    }
}
