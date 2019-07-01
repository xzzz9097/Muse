//
//  GeneralPreferencesViewController.swift
//  Muse
//
//  Created by Marco Albera on 30/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Cocoa
import MASPreferences

class GeneralPreferencesViewController: NSViewController, MASPreferencesViewController {
    
    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "GeneralPreferencesView")
    }
    
    // MARK: MASPreferencesViewController
    
    var viewIdentifier: String = "GeneralPreferences"
    
    var toolbarItemLabel: String? = "General"
    
    var toolbarItemImage: NSImage? = NSImage(named: NSImage.Name.preferencesGeneral)
    
    // MARK: General preferences
    
    var showControlStripItem: Bool {
        set {
            Preference<Bool>(.controlStripItem).set(newValue)
        }
        
        get {
            return Preference<Bool>(.controlStripItem).value
        }
    }
    
    var showHUDForControlStripAction: Bool {
        set {
            Preference<Bool>(.controlStripHUD).set(newValue)
        }
        
        get {
            return Preference<Bool>(.controlStripHUD).value
        }
    }
    
    var showSongTitle: Bool {
        set {
            Preference<Bool>(.menuBarTitle).set(newValue)
        }
        
        get {
            return Preference<Bool>(.menuBarTitle).value
        }
    }
    
}
