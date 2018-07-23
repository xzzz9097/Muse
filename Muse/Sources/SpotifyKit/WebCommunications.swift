//
//  WebCommunications.swift
//  SpotifyKit
//
//  Created by Marco Albera on 21/09/2017.
//

import Foundation

enum HTTPRequestMethod: String {
    
    case GET, POST, PUT, DELETE
}

fileprivate enum HTTPResponseStatusCode {
    
    case OK(Int)
    case REDIRECTION(Int)
    case ERROR(Int)
    
    init?(rawValue: Int) {
        switch rawValue / 100 {
        case 2: self = .OK(rawValue)
        case 3: self = .REDIRECTION(rawValue)
        case 4: self = .ERROR(rawValue)
        default: return nil
        }
    }
}

enum HTTPRequestResult {
    
    case success(Data)
    case failure(Error?)
}

protocol URLConvertible {
    
    var url: URL? { get }
}

typealias HTTPRequestParameters = [String: Any]
typealias HTTPRequestHeaders    = [String: String]

extension Dictionary where Key == String {
    
    var httpCompatible: String {
        return String(
            self.reduce("") { "\($0)&\($1.key)=\($1.value)" }
                .replacingOccurrences(of: " ", with: "+")
                .dropFirst()
        )
    }
}

extension URL {
    
    func with(parameters: String) -> URL? {
        return URL(string: "\(self.absoluteString)?\(parameters)")
    }
    
    func with(parameters: HTTPRequestParameters) -> URL? {
        return URL(string: "\(self.absoluteString)?\(parameters.httpCompatible)")
    }
}

extension URLSession {
    
    func request(_ url:             URL?,
                 method:            HTTPRequestMethod = .GET,
                 parameters:        HTTPRequestParameters? = nil,
                 headers:           HTTPRequestHeaders? = nil,
                 completionHandler: @escaping (HTTPRequestResult) -> ()) {
        guard let url = url else { return }
        
        var request = URLRequest(url: url)
        
        // Configure the request
        request.allHTTPHeaderFields = headers
        request.httpMethod          = method.rawValue

        if let parameters = parameters?.httpCompatible {
            switch method {
            case .GET, .PUT, .DELETE:
                request.url = url.with(parameters: parameters)
            case .POST:
                request.httpBody = parameters.data(using: .utf8)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, 
            error in
            guard   let data = data,
                    let response = response as? HTTPURLResponse,
                    let status = HTTPResponseStatusCode(rawValue: response.statusCode),
                    case .OK(_) = status
            else {
                DispatchQueue.main.async { completionHandler(.failure(error)) }
                return
            }
            
            DispatchQueue.main.async { completionHandler(.success(data)) }
        }
        
        task.resume()
    }
    
    func request(_ rawUrl:          String,
                 method:            HTTPRequestMethod = .GET,
                 parameters:        HTTPRequestParameters? = nil,
                 headers:           HTTPRequestHeaders? = nil,
                 completionHandler: @escaping (HTTPRequestResult) -> ()) {
        request(URL(string: rawUrl),
                method: method,
                parameters: parameters,
                headers: headers,
                completionHandler: completionHandler)
    }
    
    func request(_ urlConvertible:  URLConvertible,
                 method:            HTTPRequestMethod = .GET,
                 parameters:        HTTPRequestParameters? = nil,
                 headers:           HTTPRequestHeaders? = nil,
                 completionHandler: @escaping (HTTPRequestResult) -> ()) {
        request(urlConvertible.url,
                method: method,
                parameters: parameters,
                headers: headers,
                completionHandler: completionHandler)
    }
    
    static func authorizationHeader(user:     String,
                                    password: String) -> (key: String, value: String)? {
        guard let data = "\(user):\(password)".data(using: .utf8) else { return nil }

        return (key:   "Authorization",
                value: "Basic \(data.base64EncodedString(options: []))")
    }
}
