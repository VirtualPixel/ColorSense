//
//  PaletteDetailView.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 7/31/23.
//

import SwiftUI

struct WatchPaletteDetailView: View {
    @Environment(\.modelContext) private var context
    var palette: Palette
    
    var sortedColors: [ColorStructure] {
        return palette.colors?.sorted(by: { $0.creationDate ?? Date() > $1.creationDate ?? Date() }) ?? []
    }
    
    var body: some View {
        List {
            ForEach(sortedColors, id: \.id) { color in
                HStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(color.color)
                        .frame(width: 50, height: 50)
                    NavigationLink {
                        WatchColorDetailView(color: color.color, showAddToPalette: false)
                    } label: {
                        Text(UIColor(color.color).exactName)
                            .font(.title3)
                    }
                }
            }
            .onDelete(perform: deleteColor)
        }
        .navigationTitle(palette.name ?? "Palette Detail")
    }
    
    private func deleteColor(at offsets: IndexSet) {
        offsets.forEach { index in
            let color = sortedColors[index]
            if let index = palette.colors!.firstIndex(where: { $0.id == color.id }) {
                let colorToDelete = palette.colors!.remove(at: index)
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
    WatchPaletteDetailView(palette: Palette(name: "Test", colors: [ColorStructure(hex: "#ff0000"), ColorStructure(hex: "#00ff00"), ColorStructure(hex: "#0000ff")]))
}
