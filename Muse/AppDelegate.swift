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

    // MARK: Outlets
    
    @IBOutlet weak var menuBarMenu: NSMenu!
    
    // MARK: Actions
    
    @IBAction func quitMenuItemClicked(_ sender: Any) {
        // Quit the application
        NSApplication.shared().terminate(self)
    }
    
    // MARK: Functions
    
    func attachMenuItem() {
        // Set the menu for the item
        menuItem.menu = menuBarMenu
        
        // Set the icon
        menuItem.image = .menuBarIcon
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Enable touchbar if on eligible macOS release
        if #available(OSX 10.12.2, *) {
            NSApplication.shared().isAutomaticCustomizeTouchBarMenuItemEnabled = true
        }
        
        // Create the menu item
        attachMenuItem()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

