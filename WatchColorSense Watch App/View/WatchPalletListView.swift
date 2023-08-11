//
//  PalletListView.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 7/31/23.
//

import SwiftUI
import SwiftData

struct WatchPalletListView: View {
    @Query var pallets: [Pallet]
    @Environment(\.modelContext) private var context
    @State private var palletName = ""
    @State private var colorHex = ""
    @State private var selectedPallet: Pallet?
    @State private var showingInvalidHexAlert = false
    
    var colorToAdd: String?
    
    var body: some View {
        GeometryReader { geo in
            let maxColorsToShow = max(0, Int((geo.size.width - 100) / 80))
            NavigationStack {
                Group {
                    if pallets.isEmpty {
                        Image("empty_pallet")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250)
                            .opacity(0.7)
                    } else {
                        List {
                            ForEach(pallets, id: \.id) { pallet in
                                HStack {
                                    NavigationLink {
                                        WatchPalletDetailView(pallet: pallet)
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(pallet.name ?? "Pallet")
                                                .font(.title3)
                                                .bold()
                                            
                                            HStack {
                                                // limit the colors shown
                                                ForEach(pallet.colors?.sorted(by: { $0.creationDate ?? Date() > $1.creationDate ?? Date() }).prefix(maxColorsToShow) ?? [], id: \.id) { color in
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .foregroundStyle(Color.init(hex: color.hex ?? "000000"))
                                                        .frame(width: 50, height: 50)
                                                }
                                                
                                                ForEach(Array(repeating: 0, count: max(maxColorsToShow - (pallet.colors?.count ?? 0), 0)), id: \.self) { _ in
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .opacity(0)
                                                        .frame(width: 50, height: 50)
                                                }
                                                
                                                if (pallet.colors?.count ?? 0) > maxColorsToShow {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .foregroundStyle(.gray.opacity(0.2))
                                                        .frame(width: 50, height: 50)
                                                        .overlay(
                                                            Text("+\((pallet.colors?.count ?? 0) - maxColorsToShow)")
                                                        )
                                                }
                                                
                                                Spacer()
                                                
                                                Divider()
                                                Button {
                                                    selectedPallet = pallet
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
                            .onDelete(perform: deletePallet)
                        }
                        .listStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showNewPalletTextInputAlert()
                        } label: {
                            Text("New Pallet")
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
                .navigationTitle("Color Pallets")
            }
        }
    }
    
    private func submitPallet() {
        guard !palletName.isEmpty else { return }
        
        let pallet = Pallet(name: palletName, colors: [])
        
        if let colorToHex = colorToAdd {
            if pallet.colors != nil {
                pallet.colors?.append(ColorStructure(hex: colorToHex))
            } else {
                pallet.colors = [ColorStructure(hex: colorToHex)]
            }
        }
        
        context.insert(pallet)
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        
        palletName = ""
    }
    
    private func submitColor() {
        guard !colorHex.isEmpty else { return }
        
        guard let selectedPallet = selectedPallet,
            isValidHexColor(hex: colorHex)
        else {
            showingInvalidHexAlert = true
            return
        }
        
        let newColor = ColorStructure(hex: colorHex)
        
        if let index = pallets.firstIndex(where: { $0.id == selectedPallet.id }) {
            if pallets[index].colors != nil {
                pallets[index].colors?.append(newColor)
            } else {
                pallets[index].colors = [newColor]
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
    
    private func showNewPalletTextInputAlert() {
        guard let controller = WKExtension.shared().rootInterfaceController else { return }
        controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { results in
            if let results = results as? [String], !results.isEmpty {
                self.palletName = results[0]
                self.submitPallet()
            }
        }
    }
    
    private func deletePallet(indexSet: IndexSet) {
        indexSet.forEach { index in
            let pallet = pallets[index]
            context.delete(pallet)
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
    WatchPalletListView()
}
