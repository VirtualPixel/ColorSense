//
//  SettingsView.swift
//  ColorSense
//
//  Created by Justin Wells on 1/3/24.
//

import SwiftUI
import RevenueCatUI

struct SettingsView: View {
    @State private var isShowingPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
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
                
                Section {
                    HStack {
                        Text("Contact Us")
                        Spacer()
                        Image(systemName: "envelope.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            //.listStyle(.plain)
            .buttonStyle(BorderedButtonStyle())
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    SettingsView()
}
