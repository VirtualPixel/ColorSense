//
//  PaletteView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI
import SwiftData

struct PaletteListView: View {
    @Query var palettes: [Palette]
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject var camera: CameraModel
    @State private var editMode: EditMode = .inactive
    @State private var paletteName = ""
    @State private var showingAddNewPalette = false
    @State private var showingAddColorAlert = false
    @State private var selectedPalette: Palette?
    @State private var colorHex = ""
    @State private var showPaywall = false
    let maxColorsToShow = max(0, Int(UIScreen.main.bounds.width - 100) / 80)

    var sortedPalettes: [Palette] {
        palettes.sorted(by: { $0.creationDate ?? Date() > $1.creationDate ?? Date() })
    }
    
    var colorToAdd: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if palettes.isEmpty {
                        noPalettes
                    } else {
                        paletteList
                    }
                }

                selectedColor
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if editMode == .inactive {
                        Button {
                            if palettes.count >= 2 {
                                checkForProEntitlement(for: $showingAddNewPalette)
                            } else {
                                showingAddNewPalette = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    } else {
                        EditButton()
                    }
                }
            }
            .navigationTitle("Color Palettes")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingAddNewPalette) {
                if let selectedColor = colorToAdd {
                    PaletteEditView(selectedColor: Color(hex: selectedColor), editMode: .active)
                } else {
                    PaletteEditView(editMode: .active)
                }
            }
            .onAppear {
                camera.isPausingColorProcessing = true
            }
        }
    }

    private var paletteList: some View {
        List {
            ForEach(sortedPalettes, id: \.id) { palette in
                if let _ = colorToAdd {
                    paletteView(palette: palette)
                } else {
                    NavigationLink {
                        PaletteEditView(palette: palette)
                    } label: {
                        paletteView(palette: palette)
                    }
                }
            }
            .onDelete(perform: deletePalette)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private var noPalettes: some View {
        VStack {
            Image("empty_palette")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250)
                .opacity(0.7)
            Text("It seems pretty empty here! Try adding a palette or two.")
                .frame(width: 300)
                .multilineTextAlignment(.center)
        }
    }

    private var selectedColor: some View {
        Group {
            if let _ = colorToAdd {
                VStack {
                    Spacer()
                    ColorCardView(isDisabled: true)
                }
            }
        }
    }

    private func paletteView(palette: Palette) -> some View {
        GroupBox {
            VStack(alignment: .leading) {
                Text(palette.name ?? "Palette View")
                    .font(.title3)
                    .bold()

                HStack {
                    // limit the colors shown
                    ForEach(palette.colors?.sorted(by: { $0.creationDate ?? Date() > $1.creationDate ?? Date() }).prefix(maxColorsToShow) ?? [], id: \.id) { color in
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(Color.init(hex: color.hex ?? "000000"))
                            .frame(width: 50, height: 50)
                    }

                    ForEach(0..<max(maxColorsToShow - (palette.colors?.count ?? 0), 0), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .opacity(0)
                            .frame(width: 50, height: 50)
                    }

                    if (palette.colors?.count ?? 0) > maxColorsToShow {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("+\((palette.colors?.count ?? 0) - maxColorsToShow)")
                            )
                    }

                    Spacer()

                    addSelectedColor(palette: palette)
                }
            }
        }
    }

    private func submitColor() {
        guard !colorHex.isEmpty else { return }
        
        guard let selectedPalette = selectedPalette else {
            return
        }
        
        let newColor = ColorStructure(hex: colorHex)
        
        if let index = palettes.firstIndex(where: { $0.id == selectedPalette.id }) {
            if palettes[index].colors != nil {
                palettes[index].colors?.append(newColor)
            } else {
                palettes[index].colors = [newColor]
            }
            
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
        
        colorHex = ""
    }
    
    private func submitPalette() {
        guard !paletteName.isEmpty else { return }
        
        let palette = Palette(name: paletteName, colors: [])
        
        if let colorToHex = colorToAdd {
            if palette.colors != nil {
                palette.colors?.append(ColorStructure(hex: colorToHex))
            } else {
                palette.colors = [ColorStructure(hex: colorToHex)]
            }
        }
        
        context.insert(palette)
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        
        paletteName = ""
    }
    
    private func deletePalette(at offsets: IndexSet) {
        offsets.forEach { index in
            let palette = sortedPalettes[index]
            context.delete(palette)
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func checkForProEntitlement(for feature: Binding<Bool>) {
        if entitlementManager.hasPro {
            feature.wrappedValue = true
        } else {
            showPaywall = true
        }
    }

    private func addSelectedColor(palette: Palette) -> some View {
        Group {
            if let colorToHex = colorToAdd {
                Divider()

                Button {
                    selectedPalette = palette
                    let colorCount = selectedPalette?.colors?.count ?? 0

                    if colorCount >= 5 && !entitlementManager.hasPro {
                        showPaywall = true
                        return
                    }

                    colorHex = colorToHex
                    submitColor()
                } label: {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "plus")
                        )
                }
            }
        }
    }
}

#Preview {    
    PaletteListView()
        // .environmentObject(PreviewCameraModel())
        .environmentObject(EntitlementManager())
}
