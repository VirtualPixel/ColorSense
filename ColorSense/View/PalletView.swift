//
//  PalletView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct PalletView: View {
    @ObservedObject private var viewModel = ViewModel()
    @Environment(\.modelContext) private var context
    @State private var palletName = ""
    @State private var showingAddPalletAlert = false
    
    let pallets: [Pallet]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(pallets, id: \.id) { pallet in
                    VStack {
                        Text(pallet.name)
                            .font(.title3)
                            .bold()
                    }
                }
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
            
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

struct PalletView_Previews: PreviewProvider {
    static var previews: some View {
        PalletView(pallets: [])
    }
}
