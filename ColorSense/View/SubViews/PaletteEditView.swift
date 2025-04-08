//
//  PaletteEditView.swift
//  ColorSense
//
//  Created by Justin Wells on 4/7/25.
//

import SwiftUI
import SwiftData

struct PaletteEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var viewModel: ViewModel
    // @State private var editMode: EditMode = .inactive

    var body: some View {
        // NavigationStack {
            List {
                Section(header: Text("Palette Information")) {
                    TextField("Palette Name", text: $viewModel.paletteName)
                        .font(.title3)
                }

                Section(header: Text("Colors")) {
                    ForEach(viewModel.colors, id: \.id) { color in
                        HStack {
                            Circle()
                                .frame(width: 48, height: 48)
                                .foregroundStyle(Color(hex: color.wrappedHex))
                            Text(UIColor(hex: color.wrappedHex).exactName)
                        }
                    }
                }
            }
        //}
    }

    private func isValidHexColor(hex: String) -> Bool {
        let hexColorPattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let hexColorPredicate = NSPredicate(format:"SELF MATCHES %@", hexColorPattern)
        return hexColorPredicate.evaluate(with: hex)
    }

    init(palette: Palette? = nil) {
        _viewModel = ObservedObject(wrappedValue: ViewModel(palette: palette))
    }
}

#Preview {
    NavigationStack {
        PaletteEditView(palette: Palette.defaultPalette)
    }
}
