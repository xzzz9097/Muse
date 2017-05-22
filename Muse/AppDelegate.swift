//
//  AppDelegate.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

@available(OSX 10.12.2, *)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: Properties
    
    let menuItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    var windowToggledHandler: () -> () = { }

    // MARK: Outlets
    
    @IBOutlet weak var menuBarMenu: NSMenu!
    
    // MARK: Actions
    
    @IBAction func toggleWindowMenuItemClicked(_ sender: Any) {
        // Show window
        windowToggledHandler()
    }
    
    @IBAction func quitMenuItemClicked(_ sender: Any) {
        // Quit the application
        NSApplication.shared().terminate(self)
    }
    
    // MARK: Data saving
    
    var applicationSupportURL: URL? {
        guard let path = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory,
            .userDomainMask,
            true
        ).first else { return nil }
        
        return NSURL(fileURLWithPath: path).appendingPathComponent("Muse")
    }
    
    /**
     Checks if application support folder is present.
     http://www.cocoabuilder.com/archive/cocoa/281310-creating-an-application-support-folder.html
     */
    func hasApplicationSupportFolder() -> Bool {
        guard let url = applicationSupportURL else { return false }
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path,
                                                    isDirectory: &isDirectory)
        
        return exists && isDirectory.boolValue
    }
    
    // MARK: Functions
    
    func attachMenuItem() {
        // Set the menu for the item
        menuItem.menu = menuBarMenu
        
        // Set the icon
        menuItem.image = .menuBarIcon
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Enable TouchBar overlay
        NSApplication.shared().isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        // Create the menu item
        attachMenuItem()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

