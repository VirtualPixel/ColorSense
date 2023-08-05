//
//  ContentView.swift
//  macOSColorSense
//
//  Created by Justin Wells on 8/3/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedColor: Color?
    
    var body: some View {
        VStack {
            topBar()
            Divider()
            mainContent()
            Divider()
            bottomBar()
        }
    }
    
    @ViewBuilder func topBar() -> some View {
        HStack {
            Button {
                self.selectedColor = fetchColorAtMouse()
                print("Selected Color: \(String(describing: self.selectedColor))")
            } label: {
                Circle()
                    .fill(.clear)
                    .stroke(.white)
                    .frame(width: 16, height: 16)
                    .background(
                        Circle()
                            .frame(width: 2)
                    )
            }
            .buttonStyle(.accessoryBar)
            .padding()
            
            Spacer()
        }
    }
    
    @ViewBuilder func mainContent() -> some View {
        
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
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.accessoryBar)
            .padding()
        }
    }
    
    func fetchColorAtMouse() -> Color {
        guard let image = CGDisplayCreateImage(CGMainDisplayID(), rect: CGRect(x: NSEvent.mouseLocation.x, y: NSEvent.mouseLocation.y, width: 1, height: 1)) else {
            return Color.black
        }
        
        let rep = NSBitmapImageRep(cgImage: image)
        let color = rep.colorAt(x: 0, y: 0)
        
        return Color(color ?? NSColor.black)
    }
}

#Preview {
    ContentView()
}
