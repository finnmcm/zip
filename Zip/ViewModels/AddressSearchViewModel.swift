import MapKit
import Combine
import CoreLocation

class AddressSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var isWithinDeliveryRadius = false
    @Published var isSearching = false
    @Published var recentSearches: [String] = []
    
    private let searchCompleter = MKLocalSearchCompleter()
    private let deliveryLocation: CLLocationCoordinate2D
    private let deliveryRadiusMiles = 1.0
    private var cancellables = Set<AnyCancellable>()
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()
    
    init(deliveryLocation: CLLocationCoordinate2D) {
        self.deliveryLocation = deliveryLocation
        super.init()
        
        setupLocationManager()
        setupSearchCompleter()
        setupSearchTextObserver()
        loadRecentSearches()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        
        // Configure to only show addresses, not points of interest or queries
        searchCompleter.resultTypes = [.address]
        
        // Set region bias around delivery location with tighter radius for better local results
        let region = MKCoordinateRegion(
            center: deliveryLocation,
            latitudinalMeters: 5000, // ~3 miles radius for more focused search
            longitudinalMeters: 5000
        )
        searchCompleter.region = region
    }
    
    private func setupSearchTextObserver() {
        $searchText
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self else { return }
                
                if searchText.isEmpty {
                    self.searchResults = []
                    self.isSearching = false
                } else {
                    self.isSearching = true
                    self.searchCompleter.queryFragment = searchText
                }
            }
            .store(in: &cancellables)
    }
    
    func selectAddress(_ completion: MKLocalSearchCompletion) {
        // Use MKLocalSearch for precise geocoding (Apple Maps method)
        let searchRequest = MKLocalSearch.Request(completion: completion)
        searchRequest.resultTypes = [.address]
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Search error: \(error)")
                // Fallback to CLGeocoder if MKLocalSearch fails
                self.geocodeAddressString(completion.title + " " + completion.subtitle)
                return
            }
            
            guard let mapItem = response?.mapItems.first,
                  let location = mapItem.placemark.location else { return }
            
            DispatchQueue.main.async {
                self.selectedLocation = location.coordinate
                self.checkDeliveryRadius(location: location)
                
                // Format address like Apple Maps
                let formattedAddress = self.formatAddress(
                    title: completion.title,
                    subtitle: completion.subtitle,
                    mapItem: mapItem
                )
                self.searchText = formattedAddress
                self.searchResults = []
                self.isSearching = false
                
                // Save to recent searches
                self.saveRecentSearch(formattedAddress)
            }
        }
    }
    
    private func formatAddress(title: String, subtitle: String, mapItem: MKMapItem) -> String {
        // Format address similar to Apple Maps
        if let name = mapItem.name, !title.contains(name) {
            return "\(name), \(title)"
        } else if !subtitle.isEmpty {
            return "\(title), \(subtitle)"
        }
        return title
    }
    
    private func geocodeAddressString(_ address: String) {
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first,
                  let location = placemark.location else { return }
            
            DispatchQueue.main.async {
                self.selectedLocation = location.coordinate
                self.checkDeliveryRadius(location: location)
            }
        }
    }
    
    private func checkDeliveryRadius(location: CLLocation) {
        let deliveryLocationCL = CLLocation(
            latitude: deliveryLocation.latitude,
            longitude: deliveryLocation.longitude
        )
        let distanceInMeters = location.distance(from: deliveryLocationCL)
        let distanceInMiles = distanceInMeters / 1609.34
        
        isWithinDeliveryRadius = distanceInMiles <= deliveryRadiusMiles
    }
    
    // Recent searches functionality
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "RecentAddresses") ?? []
    }
    
    private func saveRecentSearch(_ address: String) {
        var searches = recentSearches
        searches.removeAll { $0 == address }
        searches.insert(address, at: 0)
        if searches.count > 5 {
            searches = Array(searches.prefix(5))
        }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "RecentAddresses")
    }
    
    func selectRecentSearch(_ address: String) {
        searchText = address
        geocodeAddressString(address)
    }
    
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "RecentAddresses")
    }
    
    // Update search region when user location changes
    func updateSearchRegion(with userLocation: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: userLocation,
            latitudinalMeters: 3000, // ~2 miles radius for very focused local search
            longitudinalMeters: 3000
        )
        searchCompleter.region = region
    }
}

extension AddressSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            // Sort results by relevance score since MKLocalSearchCompletion doesn't have coordinates
            // The search completer already provides results in a reasonable order
            // We'll let the user's location bias the search region instead
            self.searchResults = completer.results
            self.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
        DispatchQueue.main.async {
            self.isSearching = false
        }
    }
}

extension AddressSearchViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        // Update search region to focus on user's current location
        updateSearchRegion(with: userLocation.coordinate)
        
        // Stop updating location after we get a good fix
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
        // Fall back to delivery location if user location fails
        updateSearchRegion(with: deliveryLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // Fall back to delivery location
            updateSearchRegion(with: deliveryLocation)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}