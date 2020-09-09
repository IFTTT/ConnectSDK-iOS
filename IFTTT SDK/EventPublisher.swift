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
    typealias SubscriberClosure = (Type) -> Void
    
    private typealias Subscriber = (TimeInterval, SubscriberClosure)
    
    /// The `DispatchQueue` used to publish events on.
    private let dispatchQueue: DispatchQueue
    
    // Don't access this Dictionary directly outside of `addSubscriber(...)` or `removeSubscriber(...)`. Maps aren't threadsafe and therefore we can't use the subscripting directly.
    private var subscriberMap = [UUID: Subscriber]()
    
    /// Used for ensuring that operations on the `subscriberMap` are threadsafe.
    private let lock = NSLock()

    /// Creates an instance of `EventPublisher`.
    ///
    /// - Parameters:
    ///     - queue: The queue to use in notifying subscribers of any published events.
    init(queue: DispatchQueue) {
        self.dispatchQueue = queue
    }
    
    /// Publishes an event to subscribers. Subscribers get notified of events in descending order of time they were added.
    ///
    /// - Parameter:
    ///     - object: The event that is to be delivered to subscribers.
    func onNext(_ object: Type) {
        lock.lock(); defer { lock.unlock() }
        /// Sort the subscribers by time they were added. This means that the oldest subscriber gets notified of an event first.
        let sortedSubscriberMap = subscriberMap.values.sorted { $0.0 < $1.0 }.map { $1 }
        
        sortedSubscriberMap.forEach { closure in
            dispatchQueue.async {
                closure(object)
            }
        }
    }
    
    /// Adds a subscriber to be notified of events.
    ///
    /// - Parameters:
    ///     - subscriber: A closure that gets called when there's a new published event.
    /// - Returns: A `UUID` token that can be used to remove a subscriber using `removeSubscriber`.
    func addSubscriber(_ subscriber: @escaping SubscriberClosure) -> UUID {
        lock.lock(); defer { lock.unlock() }
        let id = UUID()
        subscriberMap[id] = (Date().timeIntervalSince1970, subscriber)
        return id
    }
    
    /// Removes a subscriber from the subscriber map.
    ///
    /// - Parameters:
    ///     - identifier: The token corresponding to the subscriber that is to be removed.
    func removeSubscriber(_ identifier: UUID) {
        lock.lock(); defer { lock.unlock() }
        subscriberMap[identifier] = nil
    }
}
