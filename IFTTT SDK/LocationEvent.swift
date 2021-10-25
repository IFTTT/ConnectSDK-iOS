//
//  LocationEvent.swift
//  IFTTTConnectSDK
//
//  Created by Siddharth Sathyam on 10/25/21.
//

import Foundation

public typealias LocationEventsClosure = ([LocationEvent]) -> Void

/// Describes the kinds of region events that can be reported.
public enum RegionEventKind: String {
    /// The user entered the region.
    case entry = "entry"
    
    /// The user exited the region.
    case exit = "exit"
}

/// Describes the reasons why an event was not uploaded.
public enum EventUploadError: Error {
    
    /// The total number of events to be uploaded exceeds a sanity threshold.
    case crossedSanityThreshold
    
    /// A network error ocurred in uploading the event.
    case networkError
}

/// Describes all of the possible events in the Location monitoring flow.
public enum LocationEvent: Equatable {
    
    /// The location event was recorded by the SDK.
    ///
    /// - Parameters:
    ///     - `region`: The details of the region that was recorded.
    case reported(region: RegionEvent)
    
    /// The SDK attempted to upload a region event.
    ///
    /// - Parameters:
    ///     - `region`: The details of the region that was attempted to be uploaded.
    ///     - `delay`: The time in seconds between reporting the event and an attempted upload.
    case uploadAttempted(region: RegionEvent, delay: TimeInterval)
    
    /// The SDK successfully uploaded the region event.
    ///
    /// - Parameters:
    ///     - `region`: The details of the region that was successfully uploaded.
    ///     - `delay`:
    case uploadSuccessful(region: RegionEvent, delay: TimeInterval)
    
    /// The SDK failed in uploaded the region event.
    ///
    /// - Parameters:
    ///     - `region`: The details of the region that was successfully uploaded.
    ///     - `error`: The `EventUploadError` that occurred.
    ///     - `delay`: The time in seconds between attempting the event upload and error in completing the upload.
    case uploadFailed(region: RegionEvent, error: EventUploadError, delay: TimeInterval)
}
