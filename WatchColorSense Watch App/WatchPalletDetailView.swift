//
//  PalletDetailView.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 7/31/23.
//

import SwiftUI

struct WatchPalletDetailView: View {
    @Environment(\.modelContext) private var context
    var pallet: Pallet
    
    var sortedColors: [ColorStructure] {
        return pallet.colors?.sorted(by: { $0.creationDate > $1.creationDate }) ?? []
    }
    
    var body: some View {
        List {
            ForEach(sortedColors, id: \.id) { color in
                HStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(color.color)
                        .frame(width: 50, height: 50)
                    NavigationLink {
                        WatchColorDetailView(color: color.color, showAddToPallet: false)
                    } label: {
                        Text(UIColor(color.color).exactName)
                            .font(.title3)
                    }
                }
            }
            .onDelete(perform: deleteColor)
        }
        .navigationTitle(pallet.name)
    }
    
    private func deleteColor(at offsets: IndexSet) {
        offsets.forEach { index in
            let color = sortedColors[index]
            if let index = pallet.colors!.firstIndex(where: { $0.id == color.id }) {
                let colorToDelete = pallet.colors!.remove(at: index)
                context.delete(colorToDelete)
                do {
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    WatchPalletDetailView(pallet: Pallet(name: "Test", colors: [ColorStructure(hex: "#ff0000"), ColorStructure(hex: "#00ff00"), ColorStructure(hex: "#0000ff")]))
}
