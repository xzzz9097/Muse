//
//  SpotifyItems.swift
//  SpotifyKit
//
//  Created by Marco Albera on 16/09/2017.
//

import Foundation

/**
 Item type for Spotify search query
 */
public enum SpotifyItemType: String, CodingKey {
    case track, album, artist, playlist, user
    
    enum SearchKey: String, CodingKey {
        case tracks, albums, artists, playlists, users
    }
    
    var searchKey: SearchKey {
        switch self {
        case .track:
            return .tracks
        case .album:
            return .albums
        case .artist:
            return .artists
        case .playlist:
            return .playlists
        case .user:
            return .users
        }
    }
}

struct SpotifyImage: Decodable {
    var url: String
}

// MARK: Items data types

public protocol SpotifyItem: Decodable {
    var id:   String { get }
    var uri:  String { get }
    var name: String { get }
    
    static var type: SpotifyItemType { get }
}

public protocol SpotifyTrackCollection {
    var collectionTracks: [SpotifyTrack]? { get }
}

public protocol SpotifySearchItem: SpotifyItem { }

public protocol SpotifyLibraryItem: SpotifyItem { }

public struct SpotifyUser: SpotifySearchItem {
    public var id:   String
    public var uri:  String
    public var name: String { return display_name ?? id }
    
    public static let type: SpotifyItemType = .user
    
    public var email: String?
    
    var display_name: String?
    var images:       [SpotifyImage]
    
    public var artUri: String {
        return images.first?.url ?? ""
    }
}

public struct SpotifyTrack: SpotifySearchItem, SpotifyLibraryItem {
    public var id:    String
    public var uri:   String
    public var name:  String
    
    // Simplified track objects don't contain album reference
    // so it should be an optional
    public var album: SpotifyAlbum?
    
    public static let type: SpotifyItemType = .track
    
    var artists = [SpotifyArtist]()
    
    public var artist: SpotifyArtist {
        return artists.first!
    }
}

public struct SpotifyAlbum: SpotifySearchItem, SpotifyLibraryItem, SpotifyTrackCollection {
    struct Tracks: Decodable {
        var items: [SpotifyTrack]
    }
    
    struct Image: Decodable {
        var url: String
    }
    
    public var id:   String
    public var uri:  String
    public var name: String
    
    // Track list is contained only in full album objects
    var tracks: Tracks?
    
    public var collectionTracks: [SpotifyTrack]? {
        return tracks?.items
    }
    
    public static let type: SpotifyItemType = .album
    
    var images  = [Image]()
    var artists = [SpotifyArtist]()
    
    public var artist: SpotifyArtist {
        return artists.first!
    }
    
    public var artUri: String {
        return images.first!.url
    }
}

public struct SpotifyPlaylist: SpotifySearchItem, SpotifyLibraryItem, SpotifyTrackCollection {
    struct Tracks: Decodable {
        struct Item: Decodable {
            var track: SpotifyTrack
        }
        
        var items: [Item]?
    }
    
    public var id:   String
    public var uri:  String
    public var name: String
    
    var tracks: Tracks
    
    public var collectionTracks: [SpotifyTrack]? {
        return tracks.items?.map { $0.track }
    }
    
    public static let type: SpotifyItemType = .playlist
}

public struct SpotifyArtist: SpotifySearchItem {
    public var id:   String
    public var uri:  String
    public var name: String
    
    public static let type: SpotifyItemType = .artist
}

public struct SpotifyLibraryResponse<T> where T: SpotifyLibraryItem {
    struct SavedItem {
        var item: T?
    }
    
    // Playlists from user library come out directly as an array
    var unwrappedItems: [T]?
    
    // Tracks and albums from user library come wrapped inside a "saved item" object
    // that contains the saved item (keyed by type: "track" or "album")
    // and the save date
    var wrappedItems: [SavedItem]?
    
    public var items: [T] {
        if let wrap = wrappedItems {
            return wrap.flatMap { $0.item }
        }
        
        if let items = unwrappedItems {
            return items
        }
        
        return []
    }
}

extension SpotifyLibraryResponse.SavedItem: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SpotifyItemType.self)

        self.init(item: try? container.decode(T.self, forKey: T.type))
    }
}

extension SpotifyLibraryResponse: Decodable {
    enum Key: String, CodingKey {
        case items
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        switch T.type {
        case .track, .album:
            self.init(unwrappedItems: nil,
                      wrappedItems: try? container.decode([SavedItem].self,
                                                          forKey: .items))
            
        case .playlist:
            self.init(unwrappedItems: try? container.decode([T].self,
                                                            forKey: .items),
                      wrappedItems: nil)
        default:
            self.init(unwrappedItems: nil, wrappedItems: nil)
        }
    }
}

public struct SpotifyFindResponse<T> where T: SpotifySearchItem {
    public struct Results: Decodable {
        public var items: [T]
    }
    
    public var results: Results
}

extension SpotifyFindResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SpotifyItemType.SearchKey.self)
        
        var results = Results(items: [])
        
        if let fetchedResults = try? container.decode(Results.self, forKey: T.type.searchKey) {
            results = fetchedResults
        }
        
        self.init(results: results)
    }
}
