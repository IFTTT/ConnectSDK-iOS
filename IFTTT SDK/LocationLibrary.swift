//
//  LocationLibrarh.swift
//  IFTTT SDK
//
//  Copyright © 2020 IFTTT. All rights reserved.
//

import Foundation
import CoreLocation

final class LocationLibrary: NSObject, Library, CLLocationManagerDelegate {
    var access: LibraryAccess {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }
    
    private let locationManager: CLLocationManager
    private var completion: ((LibraryAccess) -> Void)?
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        locationManager.delegate = self
    }
    
    func requestAccess(_ completion: @escaping (LibraryAccess) -> Void) {
        if access != .authorized {
            locationManager.requestAlwaysAuthorization()
        } else {
            completion(access)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        completion?(access)
    }
    
    deinit {
        locationManager.delegate = nil
    }
}
