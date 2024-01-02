//
//  ContentView.swift
//  macOSColorSense
//
//  Created by Justin Wells on 8/3/23.
//

import SwiftUI
import SwiftData
import ScreenCaptureKit

struct ContentView: View {
    @Query var palettes: [Palette]
    @Environment(\.modelContext) private var context
    @State private var selectedColor: Color?
    
    var sortedPalettes: [Palette] {
        palettes.sorted(by: { $0.wrappedCreationDate > $1.wrappedCreationDate })
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
                pickColor()
            } label: {
                Image(systemName: "eyedropper.full")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .buttonStyle(.accessoryBar)
            .padding(10)
            
            Button {
                print("Selected Color: \(String(describing: selectedColor))")
            } label: {
                Text("Print")
            }
            
            Spacer()
            
            Button {
                // create new palette
                let palette = Palette(name: "TestPalette", colors: [])
                print(palette)
                context.insert(palette)
                
                do {
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
            } label: {
                Text("New Palette")
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder func mainContent() -> some View {
        GeometryReader { geo in
            let maxColorsToShow = max(0, Int((geo.size.width - 100) / 80))
            Group {
                if palettes.isEmpty {
                    VStack {
                        Image("empty_palette")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300)
                            .opacity(0.7)
                            .padding(30)
                    }
                } else {
                    List {
                        ForEach(sortedPalettes, id: \.id) { palette in
                            NavigationLink {
                                //PaletteDetailView(palette: palette)
                            } label: {
                                GroupBox {
                                    VStack(alignment: .leading) {
                                        Text(palette.wrappedName)
                                            .font(.title3)
                                            .bold()
                                        
                                        HStack {
                                            // limit the colors shown
                                            ForEach(palette.wrappedColors.prefix(maxColorsToShow), id: \.id) { color in
                                                RoundedRectangle(cornerRadius: 12)
                                                    .foregroundStyle(Color.init(hex: color.wrappedHex))
                                                    .frame(width: 50, height: 50)
                                            }

                                            ForEach(Array(repeating: 0, count: max(maxColorsToShow - (palette.wrappedColors.count), 0)), id: \.self) { _ in
                                                RoundedRectangle(cornerRadius: 12)
                                                    .opacity(0)
                                                    .frame(width: 50, height: 50)
                                            }
                                            
                                            if (palette.wrappedColors.count) > maxColorsToShow {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .foregroundStyle(.gray.opacity(0.2))
                                                    .frame(width: 50, height: 50)
                                                    .overlay(
                                                        Text("+\((palette.wrappedColors.count) - maxColorsToShow)")
                                                    )
                                            }
                                            
                                            Spacer()
                                            
                                            Divider()
                                            
                                            Button {
                                                print("Add color to palette")
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
                        .onDelete(perform: deletePalette)
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
    
    private func deletePalette(at offsets: IndexSet) {
        offsets.forEach { index in
            let palette = sortedPalettes[index]
            context.delete(palette)
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func pickColor() {
        Task {
            guard let color = await NSColorSampler().sample() else {
                return
            }
            
            selectedColor = Color(nsColor: color)
            //addToRecentlyPickedColor(color)
            //requestReview()
            
            //if Defaults[.copyColorAfterPicking] {
            //    color.stringRepresentation.copyToPasteboard()
            //}
        }
    }
}

#Preview {
    ContentView()
}
