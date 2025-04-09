//
//  PaletteDetailView.swift
//  ColorSense
//
//  Created by Justin Wells on 7/27/23.
//

import SwiftUI

struct PaletteDetailView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    
    @State private var showingAddHexColorAlert = false
    @State private var colorHex = ""
    @State private var showingInvalidHexAlert = false
    @State private var showingPaywall = false
    
    var palette: Palette

    var sortedColors: [ColorStructure] {
        return palette.colors!.sorted(by: { $0.creationDate ?? Date() > $1.creationDate ?? Date() })
    }
    
    var body: some View {
        Group {
            if sortedColors.isEmpty {
                VStack {
                    Image("empty_palette")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250)
                        .opacity(0.7)
                    Text("It seems pretty empty here! Try adding a color or two.")
                        .frame(width: 300)
                        .multilineTextAlignment(.center)
                }
            } else {
                List {
                    ForEach(sortedColors, id: \.id) { color in
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(color.color)
                                .frame(width: 50, height: 50)
                            NavigationLink {
                                ColorDetailView(color: color.color, showAddToPalette: false)
                            } label: {
                                Text(UIColor(color.color).exactName)
                                    .font(.title3)
                            }
                        }
                    }
                    .onDelete(perform: deleteColor)
                }
            }
        }
        .alert("Enter new color Hex value", isPresented: $showingAddHexColorAlert) {
            TextField("Enter new color Hex value", text: $colorHex)
            Button("Okay", action: submitColor)
        } message: {
            Text("This will add a new color to your chosen Palette.")
        }
        .alert("Invalid color hex value", isPresented: $showingInvalidHexAlert) {
            Button("Okay") {
                showingInvalidHexAlert = false
            }
        } message: {
            Text("The color hex value you entered is not valid. It should be a 3- or 6-digit hexadecimal number, optionally starting with a '#'.")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let colorCount = palette.colors?.count ?? 0
                    if colorCount >= 5 && !entitlementManager.hasPro {
                        showingPaywall = true
                        return
                    }
                    showingAddHexColorAlert = true
                } label: {
                    Text("New Color from Hex")
                }
            }
        }
        .navigationTitle(palette.name ?? "Palette View")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private func deleteColor(at offsets: IndexSet) {
        offsets.forEach { index in
            let color = sortedColors[index]
            if let index = palette.colors!.firstIndex(where: { $0.id == color.id }) {
                let colorToDelete = palette.colors!.remove(at: index)
                context.delete(colorToDelete)
                do {
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func submitColor() {
        guard !colorHex.isEmpty else { return }
        
        guard isValidHexColor(hex: colorHex) else {
            showingInvalidHexAlert = true
            return
        }
        
        let newColor = ColorStructure(hex: colorHex)
        
        palette.colors?.append(newColor)
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        
        colorHex = ""
    }
    
    private func isValidHexColor(hex: String) -> Bool {
        let hexColorPattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let hexColorPredicate = NSPredicate(format:"SELF MATCHES %@", hexColorPattern)
        return hexColorPredicate.evaluate(with: hex)
    }
}

#Preview {
    let entitlementManager = EntitlementManager()
    PaletteDetailView(palette: Palette.defaultPalette)
    .environmentObject(entitlementManager)
}
