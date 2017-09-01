//
//  Imageable+Download.swift
//  Muse
//
//  Created by Marco Albera on 24/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

// MARK: Imageable protocol

// Protocol for every object that can set and get an NSImage
protocol Imageable: class {
    
    // The image open var
    // Every view that can set and get and set an image
    // has this variable, thus conforms to ImageDownload
    var image: NSImage? { get set }
}

extension NSImage {
    
    static func download(from url: URL,
                         fallback: NSImage,
                         callback: @escaping (NSImage) -> ()) {
        let session = URLSession.shared
        
        let downloadTask = session.downloadTask(with: url, completionHandler: {
             url, response, error in
            
            if error == nil && url != nil {
                if let data = NSData(contentsOf: url!) {
                    if let image = NSImage(data: data as Data) {
                        DispatchQueue.main.async { callback(image) }
                    }
                }
            } else {
                // Fallback to the provided default image
                DispatchQueue.main.async { callback(fallback) }
            }
        })
        
        downloadTask.resume()
    }
    
}

extension Imageable {
    
    // Loading function implementation
    // Also receives and @escaping (run after func returns) closure
    // to update UI after download has finished
    func loadImage(from url: URL, fallback: NSImage, callback: @escaping (NSImage) -> ()) {
        let session = URLSession.shared
        
        let downloadTask = session.downloadTask(with: url, completionHandler: {
            [weak self] url, response, error in
            
            if error == nil && url != nil {
                if let data = NSData(contentsOf: url!) {
                    if let image = NSImage(data: data as Data) {
                        DispatchQueue.main.async(execute: {
                            // Self conforms to 'Imageable'
                            // so it can set an image
                            if let strongSelf = self {
                                // Set the image on the view
                                strongSelf.image = image
                                
                                // Run the provided callback
                                callback(image)
                            }
                        })
                    }
                }
            } else {
                // Fallback to the provided default image
                DispatchQueue.main.async(execute: {
                    if let strongSelf = self {
                        strongSelf.image = fallback
                        
                        callback(fallback)
                    }
                })
            }
        })
        
        downloadTask.resume()
    }
    
}

// MARK: AppKit extensions

// Append to ImageView
extension NSImageView: Imageable { }

// Append to NSButton
extension NSButton: Imageable { }
