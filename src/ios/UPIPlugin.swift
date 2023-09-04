//
//  UPIPlugin.swift
//  MyJio
//  Copyright © 2021 Jio Platforms Limited. All rights reserved.
//

import UIKit

class UPIPlugin: NSObject {    
    let appName: String = "MyJio"
    
    func pspIntenetIsNotAJioApp(appIdentifier: String) -> Bool {
        if appIdentifier == jioIdentifierForDeepLinkDelegate {
            return true
        }
        if appIdentifier == jioEnterpriseIdentifierForDeepLinkDelegate {
            return true
        }
        return false
    }
    
    func fetchSupportedApps() -> [Any] {
        // if--> core data check VPAID
        let pspIcon: UIImage = UIImage.init(named: "ic_jiologo")!
        let pspIconImageString: String = pspIcon.convertImageToBase64()
        var myArray = [[String: String]]()
        
        // MyJio app dictionary
        if let userVPA = MJioUPIMicroservicesManager.getUserVPADetails(), !userVPA.isEmpty {
            let myJioAppListDictionary = ["packageName": Bundle.main.bundleIdentifier ?? "com.jio.myjio", "appName": self.appName, "image": pspIconImageString, "vpaid": userVPA.lowercased()] as [String: String]
            myArray.append(myJioAppListDictionary)
        }
        
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
    
    func getFilteredUPIIntentApps() -> [[String: Any]]? {
        if let intentAppContentArray = MJioSharedManager.sharedInstance.applicationTextData["UPIIntentAppsArray"] as? [[String: Any]], !intentAppContentArray.isEmpty {
            let versionCheckObject = MJioVersionAndServiceTypeCheckModel()
            let filterTypeArray = [MJioFileFilterType.serviceBased, MJioFileFilterType.versionBase, MJioFileFilterType.tabBarWhiteListBase]
            return versionCheckObject.applyFilterForFileContent(contentArray: intentAppContentArray, filterArray: filterTypeArray)
        }
        return nil
    }
    
    func acceptPayment(urlString: String) {
        let urlComponentArray = urlString.components(separatedBy: "|")
        let appIdentifier = urlComponentArray[0]
        let upiPaymentString = urlComponentArray[1]
        print(upiPaymentString as Any)
        
        if pspIntenetIsNotAJioApp(appIdentifier: appIdentifier) {
            if let intentAppContentArray = UPIPlugin.getFilteredUPIIntentApps(), !intentAppContentArray.isEmpty {
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
                    UIApplication.shared.open(applicationURL, options: [:]) { (success) in
                        if success {
                            self.webViewCallBackDelegate?.handleCallBackEventForUPILaunch?(eventName: JavaScriptWebCallBack.launchPSPAppForUPIPayment, values: [])
                        }
                    }
                }
            }
        } else {
            self.webViewCallBackDelegate?.handleCallBackEventForUPILaunch?(eventName: JavaScriptWebCallBack.launchPSPAppForUPIPayment, values: [upiPaymentString])
        }
    }
}
