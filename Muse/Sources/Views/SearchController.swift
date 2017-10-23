//
//  SearchController.swift
//  Muse
//
//  Created by Marco Albera on 20/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa
import SpotifyKit

extension NSTableView {
    
    /**
     Reloads tableView data and highlights first entry
     */
    func reloadData(selectingFirst: Bool) {
        // Refresh table view data
        self.reloadData()
        
        // Scroll to the top
        self.scrollRowToVisible(0)
        
        // Automatically select first result
        self.selectRowIndexes([0], byExtendingSelection: false)
    }
    
    /**
     Reloads tableView data while keeping selection
     */
    func reloadData(keepingSelection: Bool) {
        // Save currently selected row
        let selectedRow = self.selectedRow
        
        // Refresh tableView data
        self.reloadData()
        
        // Restore previous selection
        self.selectRowIndexes([selectedRow], byExtendingSelection: false)
    }
}
    
fileprivate extension NSTableView {
    /**
     The cell view at the requested index. Returns 0 if index is out of bounds.
     */
    func cell(at row: Int) -> ResultsTableCellView? {
        if row < 0 { return nil }
        
        return self.view(atColumn: 0, row: row, makeIfNecessary: true) as? ResultsTableCellView
    }
}

@available(OSX 10.12.2, *)
extension ViewController: NSTableViewDelegate {
    
    /**
     Table cell generation
     2 fields: result (track) name and author
     */
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        
        if let cell = tableView.make(withIdentifier: identifier, owner: self) as? ResultsTableCellView {
            // First table cell field: track name
            cell.textField?.stringValue = trackSearchResults[row].name
            
            // Second table cell field: artist name
            cell.secondTextField?.stringValue = trackSearchResults[row].artist.name
            
            // Set text colors
            [ cell.textField, cell.secondTextField ].enumerated().forEach {
                $1?.textColor = colors[$0 + 1]
            }
            
            return cell
        }
        
        return nil
    }

    /**
     Specify custom row class for table view for personalized highlight color
     */
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {        
        return CustomHighLightTableRowView(fillColor: colors[3])
    }
    
    /**
     Double click action, set as tableView.doubleAction
     */
    func tableViewDoubleClicked(tableView: NSTableView) {
        if let spotifyHelper = helper as? SpotifyHelper, tableView.selectedRow >= 0 {
            spotifyHelper.play(uri: trackSearchResults[tableView.selectedRow].uri)
        }
        
        endSearch()
    }
    
    /**
     Intercepts selection event to adapt text color to highlight.
     */
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let currentlySelectedCell = tableView.cell(at: tableView.selectedRow)
        
        // Restore original colors on previously selected cell
        [ currentlySelectedCell?.textField, currentlySelectedCell?.secondTextField ].enumerated().forEach {
            $1?.textColor = colors[$0 + 1]
        }
        
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedCell = resultsTableView?.cell(at: resultsTableView?.selectedRow ?? -1)
        
        // Invert text colors on the newly selected cell to make it readable
        [ selectedCell?.textField, selectedCell?.secondTextField ].forEach {
            $0?.textColor = colors[0]
        }
    }
}

@available(OSX 10.12.2, *)
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return trackSearchResults.count
    }
}

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
        
        spotifyManager.find(SpotifyTrack.self, text) { [weak self] tracks in
            self?.trackSearchResults = tracks
            
            // Refresh table view
            self?.resultsTableView?.reloadData(selectingFirst: true)
        }
    }
    
    func startSearch() {
        showTitleView(shouldClose: false)
        
        // Enable editing and empty the field
        titleTextField.isEditable  = true
        titleTextField.isEnabled   = true
        titleTextField.stringValue = ""
        
        // Make first responder -> start editing
        titleTextField.becomeFirstResponder()
        
        // Reload data keeping selection
        resultsTableView?.reloadData(keepingSelection: true)
        
        showResultsTableView(show: true)
    }
    
    func endSearch(canceled: Bool = false) {
        // Disable editing
        titleTextField.isEditable  = false
        titleTextField.isEnabled   = false
        
        if canceled {
            // Restore text to song title
            titleTextField.stringValue = titleLabelView.stringValue
        }
        
        // Restart the autoclose timer
        launchTitleViewAutoCloseTimer()
        
        // Hide results table after small delay
        DispatchQueue.main.run(after: canceled ? 0 : 750) { [weak self] in
            self?.showResultsTableView(show: false)
        }
    }
}
