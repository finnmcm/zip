import Foundation

// Simple building service that loads from JSON
class BuildingService: ObservableObject {
    @Published var buildings: [String] = []
    
    static let shared = BuildingService()
    
    private init() {
        loadBuildings()
    }
    
    func loadBuildings() {
        guard let url = Bundle.main.url(forResource: "buildings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let buildingNames = try? JSONDecoder().decode([String].self, from: data) else {
            print("Failed to load buildings.json")
            return
        }
        
        self.buildings = buildingNames.sorted() // Sort alphabetically
        print("Loaded \(buildings.count) buildings")
    }
    
    // Search function
    func search(_ query: String) -> [String] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        let results = buildings.filter { building in
            building.lowercased().contains(lowercasedQuery)
        }
        print("Search for '\(query)' returned \(results.count) results")
        return results
    }
}