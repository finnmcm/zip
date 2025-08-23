import SwiftUI

struct BuildingSearchView: View {
    @StateObject private var buildingService = BuildingService.shared
    @State private var searchText = ""
    @Binding var selectedBuilding: String
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return buildingService.search(searchText)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: AppMetrics.spacingSmall) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(AppColors.accent)
                        .font(.system(size: 20))
                        .frame(width: 24)
                    
                    HStack(spacing: AppMetrics.spacingSmall) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textSecondary)
                            .font(.system(size: 16))
                        
                        TextField("Search buildings...", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                                selectedBuilding = ""
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
                
                // Results or Empty States
                if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: AppMetrics.spacingLarge) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("No buildings found")
                            .font(.headline)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("Try adjusting your search terms")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppMetrics.spacingLarge)
                    }
                    Spacer()
                } else if selectedBuilding != searchText && !searchText.isEmpty{
                    ScrollView {
                        LazyVStack(spacing: AppMetrics.spacingSmall) {
                            ForEach(Array(searchResults.enumerated()), id: \.element) { _, building in
                                Button(action: {
                                    selectedBuilding = building
                                    searchText = building
                                    // Hide keyboard
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                                   to: nil, from: nil, for: nil)
                                }) {
                                    HStack {
                                        Image(systemName: "building.2")
                                            .font(.system(size: 16))
                                            .foregroundStyle(AppColors.textSecondary)
                                            .frame(width: 24)
                                        
                                        Text(building)
                                            .font(.body)
                                            .foregroundStyle(AppColors.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                    }
                                  /*  .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: AppMetrics.cornerRadius)
                                            .fill(selectedBuilding == building ? AppColors.accent.opacity(0.1) : AppColors.secondaryBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppMetrics.cornerRadius)
                                            .stroke(
                                                selectedBuilding == building ? AppColors.accent : AppColors.secondaryBackground,
                                                lineWidth: selectedBuilding == building ? 2 : 0
                                            )
                                    )*/
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppMetrics.spacingLarge)
                        .padding(.top, AppMetrics.spacingLarge)
                    }
                    .frame(maxHeight: 200)
                }
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Ensure buildings are loaded when view appears
            if buildingService.buildings.isEmpty {
                buildingService.loadBuildings()
            }
        }
    }
}
/*
#Preview {
    NavigationView {
        BuildingSearchView()
    }
}*/