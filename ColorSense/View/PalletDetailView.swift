//
//  PalletDetailView.swift
//  ColorSense
//
//  Created by Justin Wells on 7/27/23.
//

import SwiftUI

struct PalletDetailView: View {
    @Environment(\.modelContext) private var context
    var pallet: Pallet

    var sortedColors: [ColorStructure] {
        return pallet.colors.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    var body: some View {
        List {
            ForEach(sortedColors, id: \.id) { color in
                HStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(color.color)
                        .frame(width: 50, height: 50)
                    NavigationLink {
                        ColorDetailView(color: color.color, showAddToPallet: false)
                    } label: {
                        Text(color.hex)
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
            if let index = pallet.colors.firstIndex(where: { $0.id == color.id }) {
                let colorToDelete = pallet.colors.remove(at: index)
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
    PalletDetailView(pallet: Pallet(name: "Test", colors: [ColorStructure(hex: "#ff0000"), ColorStructure(hex: "#00ff00"), ColorStructure(hex: "#0000ff")]))
}
