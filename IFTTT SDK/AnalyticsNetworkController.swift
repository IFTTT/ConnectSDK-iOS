//
//  AnalyticsNetworkController.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Represents data that can be uploaded to the network.
typealias AnalyticsData = [String: AnyHashable?]

/// Handles uploading analytics data to the network.
final class AnalyticsNetworkController {
    private let urlSession: URLSession

    /// Creates a `AnalyticsNetworkController`.
    convenience init() {
        self.init(urlSession: .analyticsURLSession)
    }

    /// Creates a `AnalyticsNetworkController`.
    ///
    /// - Parameter urlSession: A `URLSession` to make request on.
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    /// A handler that is used when response is recieved from a network request.
    ///
    /// - Parameter Bool: A boolean value that corresponds to whether or not the request should be retried.
    typealias CompletionHandler = (Bool) -> Void
    
    /// A handler that is used when a error is recieved from a network request.
    ///
    /// - Parameter Error: The error resulting from the network request.
    typealias ErrorHandler = (Error) -> Void

    /// Starts a task to fetch information from the network for the provided request.
    ///
    /// - Parameters:
    ///   - urlRequest: A `URLRequest` to complete the network request on.
    ///   - completionHandler: A `CompletionHandler` for providing a response of the data recieved from the request.
    ///   - errorHandler: A `ErrorHandler` for providing an error recieved from the request.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    private func start(urlRequest: URLRequest, completionHandler: @escaping CompletionHandler, errorHandler: @escaping ErrorHandler) -> URLSessionDataTask {
        let dataTask = task(urlRequest: urlRequest, completionHandler: completionHandler, errorHandler: errorHandler)
        dataTask.resume()
        return dataTask
    }

    /// Sends an array of analytics events.
    ///
    /// - Parameters:
    ///   - events: A `[AnalyticsEvent]` to send.
    ///   - completionHandler: A `CompletionHandler` for providing a response of the data recieved from the request.
    ///   - errorHandler: A `ErrorHandler` for providing an error recieved from the request.
    /// - Returns: The `URLSessionDataTask` for the request.
    @discardableResult
    func send(_ data: [AnalyticsData], completionHandler: @escaping CompletionHandler, errorHandler: @escaping ErrorHandler) -> URLSessionDataTask {
        let request = analyticsRequest(data: data)
        return start(urlRequest: request, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /// Returns an initialized `URLSessionDataTask`.
    ///
    /// - Parameters:
    ///   - events: A `[AnalyticsEvent]` to send.
    ///   - completionHandler: A `CompletionHandler` for providing a response of the data recieved from the request.
    ///   - errorHandler: A `ErrorHandler` for providing an error recieved from the request.
    /// - Returns: The `URLSessionDataTask` for the request.
    private func task(urlRequest: URLRequest, completionHandler: @escaping CompletionHandler, errorHandler: @escaping ErrorHandler) -> URLSessionDataTask {
        let handler = { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                errorHandler(error)
                return
            }
            
            guard let httpURLResponse = response as? HTTPURLResponse else {
                completionHandler(true)
                return
            }

            // For 2xx response codes no retry is needed
            // For 3xx, 4xx, 5xx response codes, a retry is needed
            let isValidResponse = (200..<300).contains(httpURLResponse.statusCode)
            completionHandler(!isValidResponse)
        }
        return urlSession.dataTask(with: urlRequest, completionHandler: handler)
    }

    /// Returns an request that's used to submit analytics data.
    ///
    /// - Parameters:
    ///     - data: An array of `AnalyticsData` to create the request with
    /// - Returns: An initialized POST `URLRequest` that's used to send analytics data.
    private func analyticsRequest(data: [AnalyticsData]) -> URLRequest {
        var request = URLRequest(url: API.submitAnalytics)
        let eventData = ["events": data]
        request.httpBody = try? JSONSerialization.data(withJSONObject: eventData, options: JSONSerialization.WritingOptions())
        request.httpMethod = "POST"
        request.addVersionTracking()
        return request
    }
}

extension URLSession {
    /// The `URLSession` used to submit analytics data.
    static let analyticsURLSession: URLSession =  {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = [
            "Content-Type" : "application/json"
        ]
        return URLSession(configuration: configuration)
    }()
}
