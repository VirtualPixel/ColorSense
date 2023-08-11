//
//  ContentView.swift
//  macOSColorSense
//
//  Created by Justin Wells on 8/3/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query var pallets: [Pallet]
    @Environment(\.modelContext) private var context
    @State private var selectedColor: Color?
    
    var sortedPallets: [Pallet] {
        pallets.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    var body: some View {
        VStack {
            topBar()
            Divider()
            mainContent()
            Divider()
            bottomBar()
        }
        .frame(width: 350, height: 350)
    }
    
    @ViewBuilder func topBar() -> some View {
        HStack {
            Button {
                self.selectedColor = fetchColorAtMouse()
                print("Selected Color: \(String(describing: self.selectedColor))")
            } label: {
                Image(systemName: "eyedropper.full")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .buttonStyle(.accessoryBar)
            .padding(10)
            
            Spacer()
            
            Button {
                print("Creating new pallet")
            } label: {
                Text("New Pallet")
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder func mainContent() -> some View {
        GeometryReader { geo in
            let maxColorsToShow = max(0, Int((geo.size.width - 100) / 80))
            Group {
                if pallets.isEmpty {
                    Image("empty_pallet")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300)
                        .opacity(0.7)
                        .padding(30)
                } else {
                    List {
                        ForEach(sortedPallets, id: \.id) { pallet in
                            NavigationLink {
                                //PalletDetailView(pallet: pallet)
                            } label: {
                                GroupBox {
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
                                                // add pallet
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
                        }
                        .onDelete(perform: deletePallet)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder func bottomBar() -> some View {
        HStack {
            Spacer()
            
            Button {
                NSApplication.shared.terminate(self)
            } label: {
                Image(systemName: "power.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.accessoryBar)
            .padding(10)
        }
    }
    
    private func fetchColorAtMouse() -> Color {
        guard let image = CGDisplayCreateImage(CGMainDisplayID(), rect: CGRect(x: NSEvent.mouseLocation.x, y: NSEvent.mouseLocation.y, width: 1, height: 1)) else {
            return Color.black
        }
        
        let rep = NSBitmapImageRep(cgImage: image)
        let color = rep.colorAt(x: 0, y: 0)
        
        return Color(color ?? NSColor.black)
    }
    private func deletePallet(at offsets: IndexSet) {
        offsets.forEach { index in
            let pallet = sortedPallets[index]
            context.delete(pallet)
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
}
