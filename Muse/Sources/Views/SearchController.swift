//
//  SearchController.swift
//  Muse
//
//  Created by Marco Albera on 20/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa
import SpotifyKit

// MARK: NSTableViewDelegate

@available(OSX 10.12.2, *)
extension ViewController {
    
    func searchTableView(_ tableView: NSTableView,
                         viewFor tableColumn: NSTableColumn?,
                         row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        
        if let cell = tableView.make(withIdentifier: identifier, owner: self) as? ResultsTableCellView {
            // First table cell field: track name
            cell.textField?.stringValue = trackSearchResults[row].name
            cell.textField?.textColor   = colors?.primary
            
            // Second table cell field: artist name
            cell.secondTextField?.stringValue = trackSearchResults[row].artist
            cell.secondTextField?.textColor   = colors?.designatedSecondary
            
            return cell
        }
        
        return nil
    }
    
    func searchTableViewDoubleClicked(tableView: NSTableView) {
        // Play the requested track using the specific player feature
        if let helper = helper as? PlayablePlayerHelper, tableView.selectedRow >= 0 {
            helper.play(trackSearchResults[tableView.selectedRow].address)
        }
        
        endSearch()
    }
}

// MARK: NSTableViewDataSource

@available(OSX 10.12.2, *)
extension ViewController {
    
    func searchNumberOfRows(in tableView: NSTableView) -> Int {
        return trackSearchResults.count
    }
}

// MARK: Search related functions

@available(OSX 10.12.2, *)
extension ViewController {
    
    /**
     Text has been received from controlTextDidChange.
     Performs Spotify search query and set results array to the fetched results
     */
    func search(_ text: String) {
        // Require at least two characters for making requests
        // Too short queries take long time and may come after new ones
        guard text.count > 2 else { return }
        
        // Capture search request time
        let trackSearchStartTime = Date.timeIntervalSinceReferenceDate
        
        if let helper = helper as? SearchablePlayerHelper {
            helper.search(title: text) { [weak self] tracks in
                // Only parse response if launch time is greater than last one
                // Otherwise is just an old response which should be discarded
                guard let strongSelf = self, trackSearchStartTime > strongSelf.trackSearchStartTime else { return }
                
                // Updated search results and start time
                strongSelf.trackSearchResults   = tracks
                strongSelf.trackSearchStartTime = trackSearchStartTime
                
                // Refresh table view
                strongSelf.resultsTableView?.reloadData(selectingFirst: true)
            }
        }
    }
    
    func startSearch() {
        guard helper is SearchablePlayerHelper else { return }
        
        // Switch results mode first
        resultsMode = .trackSearch
        
        // Reload data keeping selection
        resultsTableView?.reloadData(keepingSelection: true)
        
        // Enable editing and empty the field
        titleTextField.isEditable  = true
        titleTextField.isEnabled   = true
        titleTextField.stringValue = ""
        
        // Make first responder -> start editing
        titleTextField.becomeFirstResponder()
        
        mainViewMode = .expandedWithResults
    }
    
    func endSearch(canceled: Bool = false) {
        // Disable editing
        titleTextField.isEditable  = false
        titleTextField.isEnabled   = false

        // Ensure that the text field has the right width
        titleTextField.animator().invalidateIntrinsicContentSize()
        
        if canceled {
            // Restore text to song title
            titleTextField.stringValue = titleLabelView.stringValue
        }
        
        // Restart the autoclose timer
        launchTitleViewAutoCloseTimer()
        
        // Hide results table after small delay
        DispatchQueue.main.run(after: canceled ? 0 : 750) { [weak self] in
            self?.mainViewMode = MainViewMode.defaultMode
        }
    }
}
