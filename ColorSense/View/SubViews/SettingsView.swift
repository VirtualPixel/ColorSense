//
//  SettingsView.swift
//  ColorSense
//
//  Created by Justin Wells on 1/3/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var isShowingPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                if !entitlementManager.hasPro {
                    Section {
                        HStack {
                            Spacer()
                            
                            Image(systemName: "star")
                                .bold()
                            
                            Text("Upgrade to Pro")
                                .font(.headline)
                            
                            Spacer()
                        }
                        .frame(height: 60)
                        .foregroundStyle(.white)
                        
                    }
                    .listRowSeparator(.hidden)
                    .background(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .onTapGesture {
                        isShowingPaywall = true
                    }
                }
                
                Section {
                    HStack {
                        Text("Contact Us")
                        Spacer()
                        Image(systemName: "envelope.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .buttonStyle(BorderedButtonStyle())
        }
        .sheet(isPresented: $isShowingPaywall) {
            #if !os(watchOS)
            PaywallView()
            #endif
        }
    }
}

#Preview {
    let entitlementManager = EntitlementManager()
    SettingsView()
        .environmentObject(entitlementManager)
}
