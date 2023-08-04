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

    var body: some View {
        VStack {
            Text("Hello")
            Text("World")
        }
    }
}

#Preview {
    ContentView()
}
