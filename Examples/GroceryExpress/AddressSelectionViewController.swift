//
//  AddressSelectionViewController.swift
//  Grocery Express
//
//  Copyright © 2021 IFTTT. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Contacts

/// Displays a map and a textfield to search for locations.
final class AddressSelectionViewController: UIViewController {
    
    /// The result of the search
    struct Result {
        let placemark: MKPlacemark
        let formattedAddress: String?
    }
    
    // MARK: - Public
    var onAddressSelect: ((Result) -> Void)?
    
    // MARK: - Private IBOutlets
    @IBOutlet private weak var mapView: MKMapView!
    
    // MARK: - Private variables
    private var resultSearchController: UISearchController? = nil
    private let locationManager = CLLocationManager()
    private var selectedItem: Result? = nil
    private var doneButton: UIBarButtonItem?
    
    static func instantiate() -> AddressSelectionViewController {
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddressSelectionViewController") as? AddressSelectionViewController else {
            fatalError("Missing view controller with identifier AddressSelectionViewController in Main storyboard.")
        }
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        let locationSearchTable = LocationSearchTableViewController()
        locationSearchTable.delegate = self
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        if let searchBar = resultSearchController?.searchBar {
            searchBar.sizeToFit()
            searchBar.placeholder = "Enter a place"
            navigationItem.titleView = searchBar
        }
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.obscuresBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        let latLongButton = UIBarButtonItem(title: "Lat/Long", style: .plain, target: self, action: #selector(latLongTapped))
        navigationItem.rightBarButtonItems = [latLongButton, doneButton]
        doneButton.isEnabled = false
        self.doneButton = doneButton
    }
    
    @objc func doneTapped() {
        guard let selectedItem = selectedItem else { return }
        onAddressSelect?(selectedItem)
    }
    
    private func showErrorAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    @objc func latLongTapped() {
        let alertController = UIAlertController(
            title: "Enter Latitude/Longitude",
            message: "",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "Latitude"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Longitude"
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            alertController.message = nil
            
            guard let latitudeTextFieldText = alertController.textFields?.first?.text,
                  let longitudeTextFieldText = alertController.textFields?[1].text else { return }
            
            guard let latitude = CLLocationDegrees(latitudeTextFieldText) else {
                self?.showErrorAlert(title: "Invalid Entry", message: "Please try again and enter a valid latitude.")
                return
            }
            
            guard let longitude = CLLocationDegrees(longitudeTextFieldText) else {
                self?.showErrorAlert(title: "Invalid Entry", message: "Please try again and enter a valid longitude.")
                return
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let placemark = MKPlacemark(coordinate: coordinate)
            self?.onAddressSelect?(.init(placemark: placemark, formattedAddress: nil))
        }
        
        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension AddressSelectionViewController: LocationSearchSelectable {
    func didSelect(_ placemark: MKPlacemark, formattedAddress: String) {
        dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }
            
            self.doneButton?.isEnabled = true
            self.selectedItem = .init(placemark: placemark, formattedAddress: formattedAddress)
            self.mapView.removeAnnotations(self.mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = placemark.coordinate
            annotation.title = placemark.name
            if let city = placemark.locality,
                let state = placemark.administrativeArea {
                    annotation.subtitle = "\(city) \(state)"
            }
            self.mapView.addAnnotation(annotation)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
        })
    }
}
 
protocol LocationSearchSelectable: AnyObject {
    func didSelect(_ placemark: MKPlacemark, formattedAddress: String)
}

class LocationSearchTableViewController : UITableViewController {
    
    var delegate: LocationSearchSelectable?
    
    private var selectedRegion: MKCoordinateRegion = .init()
    private var items: [MKMapItem] = []
    private var postalAddressFormatter = CNPostalAddressFormatter()
    private var currentSearch: MKLocalSearch? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postalAddressFormatter.style = .mailingAddress
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

extension LocationSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        currentSearch?.cancel()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = selectedRegion
        currentSearch = MKLocalSearch(request: request)
        currentSearch?.start { response, _ in
            guard let response = response else {
                return
            }
            self.items = response.mapItems
            self.tableView.reloadData()
        }
    }
}

extension LocationSearchTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if cell.detailTextLabel == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        
        let item = items[indexPath.row]
        let selectedItem = item.placemark
        cell.textLabel?.text = selectedItem.name
        
        var addressString = ""
        
        if #available(iOS 11.0, *) {
            if let postalAddress = selectedItem.postalAddress {
                addressString = postalAddressFormatter.string(from: postalAddress)
            }
        } else {
            // Fallback on earlier versions
        }
        cell.detailTextLabel?.text = addressString
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = items[indexPath.row].placemark
        
        var formattedAddress = ""
        if #available(iOS 11.0, *) {
            if let postalAddress = selectedItem.postalAddress {
                formattedAddress = postalAddressFormatter.string(from: postalAddress)
            }
        }
        delegate?.didSelect(selectedItem, formattedAddress: formattedAddress)
    }
}

extension AddressSelectionViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Manager failed with error: \(error)")
    }
}
