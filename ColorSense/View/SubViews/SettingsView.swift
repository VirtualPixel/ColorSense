//
//  SettingsView.swift
//  ColorSense
//
//  Created by Justin Wells on 1/3/24.
//

import SwiftUI
import WishKit

struct SettingsView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var isShowingPaywall = false
    @State private var isShowingWishkitScreen = false

    @AppStorage("showRgb") var showRgb = true
    @AppStorage("showHex") var showHex = true
    @AppStorage("showHsl") var showHsl = true
    @AppStorage("showCmyk") var showCmyk = true
    @AppStorage("showSwiftUI") var showSwiftUI = true
    @AppStorage("showUIKit") var showUIKit = true
    
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
                
                Section("Color Details") {
                    Toggle("Show RGB", isOn: $showRgb)
                    Toggle("Show HEX", isOn: $showHex)
                    Toggle("Show HSL", isOn: $showHsl)
                    Toggle("Show CMYK", isOn: $showCmyk)
                    Toggle("Show SwiftUI", isOn: $showSwiftUI)
                    Toggle("Show UIKit", isOn: $showUIKit)
                }

                Section("Contact Us") {
                    Button {
                        isShowingWishkitScreen = true
                    } label: {
                        Text("Feature request? Just a tap away!")
                    }

                    Button {
                        if let url = URL(string: "https://justinwells.dev/colorsense/report") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Report a problem")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Section {
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                }
            }
            .navigationTitle("Settings")
            .buttonStyle(BorderedButtonStyle())
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $isShowingWishkitScreen) {
            WishKit.FeedbackListView().withNavigation()
        }
    }
}

#Preview {
    let entitlementManager = EntitlementManager()
    SettingsView()
        .environmentObject(entitlementManager)
}
