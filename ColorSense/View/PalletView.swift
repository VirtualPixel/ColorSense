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
                        viewModel.showingAddPalletAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Enter new Pallet name", isPresented: $viewModel.showingAddPalletAlert) {
                TextField("Enter new Pallet name", text: $viewModel.palletName)
                Button("Okay", action: submit)
            } message: {
                Text("This will create a new Pallet with your custom name.")
            }
        }
    }
    
    private func submit() {
        guard viewModel.palletName != "" else { return }
        
        let pallet = Pallet(name: viewModel.palletName, colors: [])
        
        context.insert(pallet)
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        
        viewModel.palletName = ""
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
