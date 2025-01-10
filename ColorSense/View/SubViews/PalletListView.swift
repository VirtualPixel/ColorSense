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
    @ObservedObject private var viewModel = ViewModel()
    @EnvironmentObject private var cameraFeed: CameraFeed
    @Environment(\.modelContext) private var context
    @State private var paletteName = ""
    @State private var colorHex = ""
    @State private var showingAddPaletteAlert = false
    @State private var showingAddColorAlert = false
    @State private var selectedPalette: Palette?
    @State private var showingInvalidHexAlert = false
    
    var sortedPalettes: [Palette] {
        palettes.sorted(by: { $0.creationDate ?? Date() > $1.creationDate ?? Date() })
    }
    
    var colorToAdd: String?
    
    var body: some View {
        GeometryReader { geo in
            let maxColorsToShow = max(0, Int((geo.size.width - 100) / 80))
            NavigationStack {
                Group {
                    if palettes.isEmpty {
                        Image("empty_palette")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250)
                            .opacity(0.7)
                    } else {
                        List {
                            ForEach(sortedPalettes, id: \.id) { palette in
                                NavigationLink {
                                    PaletteDetailView(palette: palette)
                                } label: {
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
                                                
                                                ForEach(Array(repeating: 0, count: max(maxColorsToShow - (palette.colors?.count ?? 0), 0)), id: \.self) { _ in
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
                                                
                                                Divider()
                                                Button {
                                                    selectedPalette = palette
                                                    if let colorToHex = colorToAdd {
                                                        colorHex = colorToHex
                                                        submitColor()
                                                        return
                                                    }
                                                    showingAddColorAlert = true
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
                            }
                            .onDelete(perform: deletePalette)
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddPaletteAlert = true
                        } label: {
                            Text("New Palette")
                        }
                    }
                }
                .alert("Enter new Palette name", isPresented: $showingAddPaletteAlert) {
                    TextField("Enter new Palette name", text: $paletteName)
                    Button("Okay", action: submitPalette)
                } message: {
                    Text("This will create a new Palette with your custom name.")
                }
                .alert("Enter new color Hex value", isPresented: $showingAddColorAlert) {
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
                .navigationTitle("Color Palettes")
                .onAppear {
                    cameraFeed.pauseProcessing = true
                }
                .onDisappear {
                    cameraFeed.pauseProcessing = false
                }
            }
        }
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
    
    private func submitColor() {
        guard !colorHex.isEmpty else { return }
        
        guard let selectedPalette = selectedPalette,
              isValidHexColor(hex: colorHex)
        else {
            showingInvalidHexAlert = true
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
    
    private func isValidHexColor(hex: String) -> Bool {
        let hexColorPattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let hexColorPredicate = NSPredicate(format:"SELF MATCHES %@", hexColorPattern)
        return hexColorPredicate.evaluate(with: hex)
    }
}

struct PaletteView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        PaletteListView()
            .environmentObject(cameraFeed)
    }
}
