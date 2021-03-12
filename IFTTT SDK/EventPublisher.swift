//
//  EventPublisher.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation

/// Defines an generic threadsafe publisher-subscriber construct allowing multiple subscribers to be
/// notified of events from the publisher.
final class EventPublisher<Type> {
    /// A typealias to refer to the closure that's executed on each subscriber.
    typealias SubscriberClosure = (Type) -> Void
    
    /// A typealias to refer to a subscriber.
    private typealias Subscriber = (TimeInterval, SubscriberClosure)
    
    /// The `DispatchQueue` used to access the subscriberMap on.
    private let subscriberMapDispatchQueue: DispatchQueue
    
    /// The `DispatchQueue` used to publish events on
    private let publisherDispatchQueue: DispatchQueue
    
    // Don't access this Dictionary directly outside of `addSubscriber(...)` or `removeSubscriber(...)`. Maps aren't threadsafe and therefore we can't use the subscripting directly.
    private var subscriberMap = [UUID: Subscriber]()
    
    /// Creates an instance of `EventPublisher`.
    ///
    /// - Parameters:
    ///     - queue: The queue to use in notifying subscribers of any published events.
    init(subscriberMapDispatchQueue: DispatchQueue = DispatchQueue(label: "com.ifttt.subscriber_map.lock"),
         publisherDispatchQueue: DispatchQueue = DispatchQueue(label: "com.ifttt.publisher", attributes: .concurrent)) {
        self.subscriberMapDispatchQueue = subscriberMapDispatchQueue
        self.publisherDispatchQueue = publisherDispatchQueue
    }
    
    /// Publishes an event to subscribers. Subscribers get notified of events in descending order of time they were added.
    ///
    /// - Parameter:
    ///     - object: The event that is to be delivered to subscribers.
    func onNext(_ object: Type) {
        subscriberMapDispatchQueue.sync { [weak self] in
            /// Sort the subscribers by time they were added. This means that the oldest subscriber gets notified of an event first.
            self?.subscriberMap.values.sorted { $0.0 < $1.0 }
                .map { $1 }
                .forEach { closure in
                    self?.publisherDispatchQueue.async {
                        closure(object)
                    }
                }
        }
    }
    
    /// Adds a subscriber to be notified of events.
    ///
    /// - Parameters:
    ///     - subscriber: A closure that gets called when there's a new published event.
    /// - Returns: A `UUID` token that can be used to remove a subscriber using `removeSubscriber`.
    @discardableResult
    func addSubscriber(_ subscriber: @escaping SubscriberClosure) -> UUID {
        return subscriberMapDispatchQueue.sync { [weak self] in
            let id = UUID()
            self?.subscriberMap[id] = (Date().timeIntervalSince1970, subscriber)
            return id
        }
    }
    
    /// Removes a subscriber from the subscriber map.
    ///
    /// - Parameters:
    ///     - identifier: The token corresponding to the subscriber that is to be removed.
    func removeSubscriber(_ identifier: UUID) {
        subscriberMapDispatchQueue.sync { [weak self] in
            self?.subscriberMap[identifier] = nil
        }
    }
}
