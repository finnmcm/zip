//
//  MainTabView.swift
//  Zip
//

import SwiftUI
import Inject

struct MainTabView: View {
    @ObserveInjection var inject
    
    var body: some View {
        TabView {
            ProductListView()
                .tabItem { 
                    Label("Shop", systemImage: "bag") 
                }
            
            CartView()
                .tabItem { 
                    Label("Cart", systemImage: "cart") 
                }
            
            ProfileView()
                .tabItem { 
                    Label("Profile", systemImage: "person") 
                }
        }
        .tint(AppColors.accent)
        .enableInjection()
    }
}


