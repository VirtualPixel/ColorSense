//
//  PalletView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI
import SwiftData

struct PalletView: View {
    @Query var pallets: [Pallet]
    @ObservedObject private var viewModel = ViewModel()
    @Environment(\.modelContext) private var context
    @State private var palletName = ""
    @State private var showingAddPalletAlert = false
        
    var body: some View {
        NavigationStack {
            List {
                ForEach(pallets, id: \.id) { pallet in
                    HStack {
                        Text(pallet.name)
                            .font(.title3)
                            .bold()
                        Spacer()
                        Text("\(pallet.colors.count)")
                    }
                }
                .onDelete(perform: deletePallet)
            }
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
                Button("Okay", action: submit)
            } message: {
                Text("This will create a new Pallet with your custom name.")
            }
            .navigationTitle("Color Pallets")
        }
    }
    
    private func submit() {
        guard !palletName.isEmpty else { return }
        
        let pallet = Pallet(name: palletName, colors: [])
        pallet.colors.append(ColorStructure(hex: "FFAA60"))
        
        context.insert(pallet)
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        
        palletName = ""
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
}

struct PalletView_Previews: PreviewProvider {
    static var previews: some View {
        PalletView()
    }
}
