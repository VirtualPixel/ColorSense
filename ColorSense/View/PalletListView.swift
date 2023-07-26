//
//  PalletView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI
import SwiftData

struct PalletListView: View {
    @Query var pallets: [Pallet]
    @ObservedObject private var viewModel = ViewModel()
    @Environment(\.modelContext) private var context
    @State private var palletName = ""
    @State private var colorHex = ""
    @State private var showingAddPalletAlert = false
    @State private var showingAddColorAlert = false
    @State private var selectedPallet: Pallet?
    @State private var showingInvalidHexAlert = false

    private let maxColorsToShow = Int((UIScreen.main.bounds.width - 100) / 80)
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(pallets, id: \.id) { pallet in
                    GroupBox {
                        VStack(alignment: .leading) {
                            Text(pallet.name)
                                .font(.title3)
                                .bold()
                            
                            HStack {
                                // limit the colors shown
                                ForEach(pallet.colors.prefix(maxColorsToShow), id: \.id) { color in
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundStyle(Color.init(hex: color.hex))
                                        .frame(width: 50, height: 50)
                                        .onTapGesture {
                                            print(color.hex)
                                        }
                                }
                                
                                if pallet.colors.count > maxColorsToShow {
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundStyle(.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text("+\(pallet.colors.count - maxColorsToShow)")
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
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPalletAlert = true
                    } label: {
                        Image(systemName: "plus")
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
            pallets[index].colors.append(newColor)
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

struct PalletView_Previews: PreviewProvider {
    static var previews: some View {
        PalletListView()
    }
}
