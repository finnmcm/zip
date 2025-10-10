import SwiftUI
import MapKit

// Move delivery location outside the struct to avoid capturing self
private let deliveryLocation = CLLocationCoordinate2D(
    latitude: 42.0569,   // Northwestern University coordinates
    longitude: -87.6754  // Note: negative longitude for western hemisphere
)

struct AddressSelectionView: View {
    @StateObject private var viewModel = AddressSearchViewModel(deliveryLocation: deliveryLocation)
    @State private var showingOutOfRangeAlert = false
    @Binding var selectedAddress: String
    @State var leaveAtDoor = false
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    
    init(selectedAddress: Binding<String>, checkoutViewModel: CheckoutViewModel) {
        self._selectedAddress = selectedAddress
        self.checkoutViewModel = checkoutViewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Address Search Bar
            VStack(alignment: .leading, spacing: 8) {
                
                HStack(spacing: AppMetrics.spacingSmall) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(AppColors.accent)
                        .font(.system(size: 20))
                        .frame(width: 24)
                    
                    HStack(spacing: AppMetrics.spacingSmall) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textSecondary)
                            .font(.system(size: 16))
                        
                        TextField("Enter your address", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .disabled(!selectedAddress.isEmpty) // Disable editing if address is selected
                        
                        if !viewModel.searchText.isEmpty {
                            Button("Clear") {
                                viewModel.searchText = ""
                                selectedAddress = ""
                                viewModel.selectedLocation = nil
                                viewModel.searchResults = []
                            }
                            .font(.caption)
                            .foregroundStyle(AppColors.accent)
                        }
                    }
                    .padding(.horizontal, AppMetrics.spacingSmall)
                    .padding(.vertical, AppMetrics.spacingSmall)
                    .cornerRadius(AppMetrics.cornerRadiusLarge)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusSmall)
                            .stroke(AppColors.textSecondary, lineWidth: 1.2)
                    )
                }
                .padding(.horizontal, AppMetrics.spacingLarge)
                
                // Search Results
                if !viewModel.searchResults.isEmpty && selectedAddress.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.searchResults, id: \.self) { result in
                                Button(action: {
                                    selectAddress(result)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(result.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            
            // Delivery Status
            if viewModel.selectedLocation != nil {
                HStack {
                    Image(systemName: viewModel.isWithinDeliveryRadius ? 
                          "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(viewModel.isWithinDeliveryRadius ? 
                                       .green : .red)
                    
                    Text(viewModel.isWithinDeliveryRadius ? 
                         "Address is within delivery range" : 
                         "Address is outside delivery range")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .onChange(of: viewModel.isWithinDeliveryRadius) { _, newValue in
            checkoutViewModel.isOffCampusAddressWithinRadius = newValue
        }
        .onAppear {
            // Initialize the checkout view model with current state
            checkoutViewModel.isOffCampusAddressWithinRadius = viewModel.isWithinDeliveryRadius
        }
    }
    
    private func selectAddress(_ result: MKLocalSearchCompletion) {
        // Extract street and number from the address first
        let abbreviatedAddress = extractStreetAndNumber(from: result.title)
        selectedAddress = abbreviatedAddress
        
        // Update the search text to show the abbreviated address
        viewModel.searchText = abbreviatedAddress
        
        // Call selectAddress with preserveSearchText = true to prevent overriding our abbreviated address
        viewModel.selectAddress(result, preserveSearchText: true)
        
        // Clear search results since an address is now selected
        viewModel.searchResults = []
    }
    
    private func extractStreetAndNumber(from address: String) -> String {
        // Split the address into components
        let components = address.components(separatedBy: ",")
        
        // Take the first component which usually contains street number and name
        if let firstComponent = components.first?.trimmingCharacters(in: .whitespaces) {
            // Remove any extra information like apartment numbers, unit numbers, etc.
            let streetComponents = firstComponent.components(separatedBy: .whitespaces)
            
            // Look for the street number (first numeric component)
            var streetNumber = ""
            var streetName = ""
            
            for component in streetComponents {
                if component.rangeOfCharacter(from: .decimalDigits) != nil {
                    // This component contains numbers, likely the street number
                    streetNumber = component
                } else if !streetName.isEmpty {
                    // Continue building street name
                    streetName += " " + component
                } else {
                    // Start building street name
                    streetName = component
                }
            }
            
            // Combine street number and name
            if !streetNumber.isEmpty && !streetName.isEmpty {
                return "\(streetNumber) \(streetName)"
            } else if !streetNumber.isEmpty {
                return streetNumber
            } else if !streetName.isEmpty {
                return streetName
            }
        }
        
        // Fallback: return the first component if parsing fails
        return components.first?.trimmingCharacters(in: .whitespaces) ?? address
    }
}
