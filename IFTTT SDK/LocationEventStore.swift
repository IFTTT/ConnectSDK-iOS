//
//  LocationEventStore.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import Foundation

/// A data structure to store location events
struct LocationEventStore {
    
    /// Describes the state that an event can be in
    enum EventState: String {
        /// The event was recorded by the SDK.
        case recorded
        
        /// The event was attempted to be uploaded.
        case uploadStart
        
        /// The event was successfully uploaded
        case uploadSuccess
        
        /// The event failed in uploading
        case uploadError
    }
    
    /// Represents a recorded event in the store.
    struct RecordedEvent {
        private struct Key {
            static let State = "state"
            static let Date = "date"
        }
        
        /// The state of the event
        let state: EventState
        
        /// The date at which the event ocurred at
        let date: Date
        
        /// Creates an instance of `RecordedEvent`
        ///
        /// - Parameters:
        ///     - state: The state of the event
        ///     - date: The date at which the event ocurred at
        init(
            state: EventState,
            date: Date
        ) {
            self.state = state
            self.date = date
        }
        
        /// Creates an optional instance of `RecordEvent`.
        ///
        /// - Parameters:
        ///     - dictionary: The dictionary to use in creating the instance.
        init?(dictionary: [String: Any]) {
            guard let stateRawValue = dictionary[Key.State] as? String,
                  let dateRawValue = dictionary[Key.Date] as? TimeInterval,
                  let state = EventState(rawValue: stateRawValue) else {
                      return nil
                  }
            self.state = state
            self.date = Date(timeIntervalSinceReferenceDate: dateRawValue)
        }
        
        /// Generates a dictionary from `self`.
        var dictionary: [String: Any] {
            return [
                Key.State: state.rawValue,
                Key.Date: date.timeIntervalSinceReferenceDate
            ]
        }
    }
    
    private static let EventMapKey = "com.ifttt.locationEventReporter.map"

    private var eventMap: [String: RecordedEvent]? {
        get {
            guard let dictionary = UserDefaults.standard.dictionary(forKey: LocationEventStore.EventMapKey) else { return nil }
            return dictionary.compactMapValues { value -> RecordedEvent? in
                guard let dictionary = value as? [String: Any] else { return nil }
                return .init(dictionary: dictionary)
            }
        }
        set {
            let mappedDictionary = newValue?.compactMapValues { $0.dictionary }
            UserDefaults.standard.set(mappedDictionary, forKey: LocationEventStore.EventMapKey)
        }
    }
    
    /// Creates an instance of `LocationEventStore`
    init() {
        initializeEventMapIfNecessary()
    }
     
    subscript(key: String) -> RecordedEvent? {
        return eventMap?[key]
    }
    
    /// Tracks a recorded event.
    ///
    /// - Parameters:
    ///     - event: The event to record.
    ///     - date: The date the event ocurred at.
    mutating func trackRecordedEvent(_ event: RegionEvent, at date: Date) {
        updateRecordedEvent(
            event,
            state: .recorded,
            date: date
        )
    }
    
    /// Tracks an event which has begun uploading.
    ///
    /// - Parameters:
    ///     - event: The event to track.
    ///     - date: The date the event began uploading at.
    mutating func trackEventUploadStart(_ event: RegionEvent, at date: Date) {
        updateRecordedEvent(
            event,
            state: .uploadStart,
            date: date
        )
    }
    
    /// Tracks an event which has been successfully uploaded.
    ///
    /// - Parameters:
    ///     - event: The event to track.
    ///     - date: The date the event was successfully uploaded at.
    mutating func trackEventSuccessfulUpload(_ event: RegionEvent, at date: Date) {
        initializeEventMapIfNecessary()
        if eventMap?[event.recordId.uuidString] != nil {
            var _eventMap = eventMap
            _eventMap?[event.recordId.uuidString] = nil
            self.eventMap = _eventMap
        }
    }
    
    /// Tracks an event which has failed in uploading. If the event failed due to the sanity threshold being crossed, it will not be tracked anymore.
    ///
    /// - Parameters:
    ///     - event: The event to track.
    ///     - error: The error which caused the upload to fail.
    ///     - date: The date the event failed to upload at.
    mutating func trackEventFailedUpload(_ event: RegionEvent, error: EventUploadError, at date: Date) {
        initializeEventMapIfNecessary()
        var _eventMap = eventMap
        switch error {
        case .crossedSanityThreshold:
            _eventMap?[event.recordId.uuidString] = nil
        case .networkError:
            _eventMap?[event.recordId.uuidString] = .init(state: .uploadError, date: date)
        }
        self.eventMap = _eventMap
    }
    
    /// Computes the delay for a tracked event against the parameter date.
    ///
    /// - Parameters:
    ///     - event: The event to compute the delay for.
    ///     - delay: The timestamp to compute the delay against.
    func delay(for event: RegionEvent, against date: Date) -> TimeInterval {
        var delay: TimeInterval = -1
        if let record = eventMap?[event.recordId.uuidString] {
            delay = date.timeIntervalSince(record.date)
        }
        return delay
    }
    
    /// Resets the state of the event store
    mutating func reset() {
        eventMap = nil
    }
    
    private mutating func initializeEventMapIfNecessary() {
        if eventMap == nil {
            eventMap = .init()
        }
    }
    
    private mutating func updateRecordedEvent(
        _ event: RegionEvent,
        state: EventState,
        date: Date
    ) {
        initializeEventMapIfNecessary()
        var _eventMap = eventMap
        _eventMap?[event.recordId.uuidString] = .init(state: state, date: date)
        self.eventMap = _eventMap
    }
}
