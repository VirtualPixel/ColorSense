//
//  PalletListView.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 7/31/23.
//

import SwiftUI
import SwiftData

struct PalletListView: View {
    @Query var pallets: [Pallet]
    @Environment(\.modelContext) private var context
    @State private var palletName = ""
    @State private var colorHex = ""
    @State private var showingAddPalletAlert = false
    @State private var showingAddColorAlert = false
    @State private var selectedPallet: Pallet?
    @State private var showingInvalidHexAlert = false
    
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
                                NavigationLink {
                                    PalletDetailView(pallet: pallet)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(pallet.name)
                                            .font(.title3)
                                            .bold()
                                        
                                        HStack {
                                            // limit the colors shown
                                            ForEach(pallet.colors?.sorted(by: { $0.creationDate > $1.creationDate }).prefix(maxColorsToShow) ?? [], id: \.id) { color in
                                                RoundedRectangle(cornerRadius: 12)
                                                    .foregroundStyle(Color.init(hex: color.hex))
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
                            .onDelete(perform: deletePallet)
                        }
                        .listStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddPalletAlert = true
                        } label: {
                            Text("New Pallet")
                        }
                    }
                }
                .alert("Enter new Pallet name", isPresented: $showingAddPalletAlert) {
                    TextField("Enter new Pallet name", text: $palletName)
                    Button("Okay", action: submitPallet)
                } message: {
                    Text("This will create a new Pallet with your custom name.")
                }
                .alert("Enter new color Hex value", isPresented: $showingAddColorAlert) {
                    TextField("Enter new color Hex value", text: $colorHex)
                    Button("Okay", action: submitColor)
                } message: {
                    Text("This will add a new color to your chosen Pallet.")
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
    PalletListView()
}