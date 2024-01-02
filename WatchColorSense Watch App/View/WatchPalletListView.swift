//
//  PaletteListView.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 7/31/23.
//

import SwiftUI
import SwiftData

struct WatchPaletteListView: View {
    @Query var palettes: [Palette]
    @Environment(\.modelContext) private var context
    @State private var paletteName = ""
    @State private var colorHex = ""
    @State private var selectedPalette: Palette?
    @State private var showingInvalidHexAlert = false
    
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
                            ForEach(palettes, id: \.id) { palette in
                                HStack {
                                    NavigationLink {
                                        WatchPaletteDetailView(palette: palette)
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(palette.name ?? "Palette")
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
                                                    showTextInputAlert()
                                                } label: {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .foregroundStyle(.gray.opacity(0.2))
                                                        .frame(width: 50, height: 50)
                                                        .overlay(
                                                            Image(systemName: "plus")
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: deletePalette)
                        }
                        .listStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showNewPaletteTextInputAlert()
                        } label: {
                            Text("New Palette")
                        }
                    }
                }
                .alert("Invalid color hex value", isPresented: $showingInvalidHexAlert) {
                    Button("Okay") {
                        showingInvalidHexAlert = false
                    }
                } message: {
                    Text("The color hex value you entered is not valid. It should be a 3- or 6-digit hexadecimal number, optionally starting with a '#'.")
                }
                .navigationTitle("Color Palettes")
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

    private func showTextInputAlert() {
        guard let controller = WKExtension.shared().rootInterfaceController else { return }
        controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { results in
            if let results = results as? [String], !results.isEmpty {
                self.colorHex = results[0]
                self.submitColor()
            }
        }
    }
    
    private func showNewPaletteTextInputAlert() {
        guard let controller = WKExtension.shared().rootInterfaceController else { return }
        controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { results in
            if let results = results as? [String], !results.isEmpty {
                self.paletteName = results[0]
                self.submitPalette()
            }
        }
    }
    
    private func deletePalette(indexSet: IndexSet) {
        indexSet.forEach { index in
            let palette = palettes[index]
            context.delete(palette)
        }
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func isValidHexColor(hex: String) -> Bool {
        let hexColorPattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let hexColorPredicate = NSPredicate(format:"SELF MATCHES %@", hexColorPattern)
        return hexColorPredicate.evaluate(with: hex)
    }
}

#Preview {
    WatchPaletteListView()
}
