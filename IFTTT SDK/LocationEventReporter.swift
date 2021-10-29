//
//  LocationEventReporter.swift
//  IFTTTConnectSDK
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import Foundation

/// Handles reporting location events
final class LocationEventReporter {
    
    /// The data structure to use in storing location events
    private var eventStore: LocationEventStore
    
    /// The closure to invoke whenever there's a location event to be reported
    var closure: LocationEventsClosure?
    
    /// Creates an instance of `LocationEventReporter`.
    ///
    /// - Parameters:
    ///     - eventStore: The `LocationEventStore` to use in storing location events.
    init(eventStore: LocationEventStore) {
        self.eventStore = eventStore
    }
    
    /// Records a region event that has ocurred.
    ///
    /// - Parameters:
    ///     - region: The `RegionEvent` that ocurred.
    ///     - date: The timestamp at which the region event ocurred at. Defaults to `Date()`.
    func recordRegionEvent(
        _ region: RegionEvent,
        at date: Date = .init()
    ) {
        eventStore.trackRecordedEvent(region, at: date)
        closure?([.reported(region: region)])
    }
    
    /// Records region events that have started to get uploaded.
    ///
    /// - Parameters:
    ///     - regions: The `[RegionEvent]` that have begun uploading.
    ///     - date: The timestamp at which the upload started at. Defaults to `Date()`.
    func regionEventsStartUpload(
        _ regions: [RegionEvent],
        at date: Date = .init()
    ) {
        process(
            regions,
            state: .uploadStart,
            date: date,
            error: nil
        )
    }
    
    /// Records region events that have been successfully uploaded.
    ///
    /// - Parameters:
    ///     - regions: The `[RegionEvent]` that have been successfully uploaded.
    ///     - date: The timestamp at which the events were successfully uploaded at. Defaults to `Date()`.
    func regionEventsSuccessfulUpload(
        _ regions: [RegionEvent],
        at date: Date = .init()
    ) {
        process(
            regions,
            state: .uploadSuccess,
            date: date,
            error: nil
        )
    }
    
    /// Records region events that failed in uploading.
    ///
    /// - Parameters:
    ///     - regions: The `[RegionEvent]` that failed in uploading.
    ///     - date: The timestamp at which the events failed in uploading. Defaults to `Date()`.
    ///     - error: The `EventUploadError` that caused the events to fail in uploading.
    func regionEventsErrorUpload(
        _ regions: [RegionEvent],
        at date: Date = .init(),
        error: EventUploadError
    ) {
        process(
            regions,
            state: .uploadError,
            date: date,
            error: error
        )
    }
    
    /// Resets the state of the `LocationEventReporter`
    func reset() {
        eventStore.reset()
    }
    
    private func process(
        _ regions: [RegionEvent],
        state: LocationEventStore.EventState,
        date: Date, error: EventUploadError?
    ) {
        var locationEvents: [LocationEvent]
        switch state {
        case .recorded:
            locationEvents = regions.map { region -> LocationEvent in
                eventStore.trackRecordedEvent(region, at: date)
                return .reported(region: region)
            }
        case .uploadStart:
            locationEvents = regions.map { region -> LocationEvent in
                let delay = eventStore.delay(for: region, against: date)
                eventStore.trackEventUploadStart(region, at: date)
                return LocationEvent.uploadAttempted(region: region, delay: delay)
            }
        case .uploadSuccess:
            locationEvents = regions.map { region -> LocationEvent in
                let delay = eventStore.delay(for: region, against: date)
                eventStore.trackEventSuccessfulUpload(region, at: date)
                return LocationEvent.uploadSuccessful(region: region, delay: delay)
            }
        case .uploadError:
            guard let error = error else {
                fatalError("Expecting error to not be nil for this case here")
            }
            locationEvents = regions.map { region -> LocationEvent in
                let delay = eventStore.delay(for: region, against: date)
                eventStore.trackEventFailedUpload(region, error: error, at: date)
                return LocationEvent.uploadFailed(region: region, error: error, delay: delay)
            }
        }
        closure?(locationEvents)
    }
}
