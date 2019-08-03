//
//  AppDelegate.swift
//  LDLARadio
//
//  Created by Javier Fuchs on 1/6/17.
//  Copyright © 2017 Mobile Patagonia. All rights reserved.
//

import UIKit
import JFCore
import SwiftSpinner

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var userDefault: UserDefaults?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // force english
        UserDefaults.standard.setValue(["en"], forKey: "AppleLanguages")
        RestApi.instance.context = CoreDataManager.instance.taskContext
        #if DEBUG
        registerSettingsBundle()
        #endif
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        SwiftSpinner.setTitleFont(UIFont.init(name: Commons.font.name, size: Commons.font.size.S))
        
        changeAppearance()

        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    private func registerSettingsBundle() {
        var appDefaults = [String:AnyObject]()
        appDefaults["server_url"] = RestApi.Constants.Service.ldlaServer as AnyObject?
        UserDefaults.standard.register(defaults: appDefaults)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    private func changeAppearance() {
        let attributes = [NSAttributedString.Key.font: UIFont(name: Commons.font.name, size: Commons.font.size.S)!,
                          NSAttributedString.Key.foregroundColor: UIColor.gray]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .normal)
        
        let headerLabel = UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self])
        headerLabel.font = UIFont(name: Commons.font.name, size: Commons.font.size.XXL)!
        headerLabel.textColor = .lightGray
        headerLabel.shadowColor = .black
        headerLabel.shadowOffset = CGSize(width: -1, height: -1)
    }
    
    @objc func defaultsChanged() {
        userDefault = UserDefaults.standard
    }
    
}

extension UITabBar {
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 80 :
            UIScreen.main.bounds.height > 400 ? 80 : 44
        return sizeThatFits
    }
}
