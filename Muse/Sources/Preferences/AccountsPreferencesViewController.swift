//
//  AccountPreferencesViewController.swift
//  Muse
//
//  Created by Marco Albera on 31/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Foundation
import MASPreferences

class AccountsPreferencesViewController: NSViewController, MASPreferencesViewController {

    override var nibName: String? {
        return "AccountsPreferencesView"
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var accountImageView: NSImageView!
    
    @IBOutlet weak var accountNameView: NSTextField!
    
    @IBOutlet weak var accountEmailView: NSTextField!
    
    // MARK: MASPreferencesViewController
    
    var viewIdentifier: String = "AccountsPreferences"
    
    var toolbarItemLabel: String? = "Accounts"
    
    var toolbarItemImage: NSImage? = NSImage(named: NSImage.Name.userAccounts)
    
    // MARK: Account preferences
    
    var spotifyAccount: Account?
    
    override func viewDidLoad() {        
        loadSpotifyAccount()
    }
    
    func loadSpotifyAccount() {
        SpotifyHelper.account { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.spotifyAccount = $0
            
            if let account = strongSelf.spotifyAccount {
                self?.accountImageView.image       = account.image
                self?.accountNameView.stringValue  = account.username
                self?.accountEmailView.stringValue = account.email
            }
        }
    }
    
}
