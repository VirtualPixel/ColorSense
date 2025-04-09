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

    @StateObject private var viewModel: ViewModel
    @State private var hexColorInput: String = ""
    @State private var showingColorPicker: Bool = false
    @State private var showingHexInput: Bool = false
    @State private var showingInvalidHexAlert: Bool = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            Section(header: Text("Palette Information")) {
                if (editMode == .active) {
                    TextField("Palette Name", text: $viewModel.paletteName)
                        .font(.title3)
                } else {
                    Text(viewModel.paletteName)
                        .font(.title3)
                }
            }

            Section(header: Text("Colors")) {
                ForEach(viewModel.colors, id: \.id) { color in
                    HStack {
                        if editMode == .active {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.gray)
                        }

                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: color.wrappedHex))
                            .frame(width: 40, height: 40)

                        NavigationLink {
                            ColorDetailView(color: color.color, showAddToPalette: false)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(UIColor(hex: color.wrappedHex).exactName)
                                    .font(.headline)
                                Text(color.wrappedHex)
                                    .font(.caption)
                            }
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            // viewModel.removeColor(color: color)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            UIPasteboard.general.string = color.wrappedHex
                        } label: {
                            Label("Copy Hex", systemImage: "doc.on.doc")
                        }
                    }
                }
                .onDelete(perform: viewModel.removeColors)
                .onMove(perform: viewModel.moveColors)

                Menu {
                    Button {
                        showingHexInput = true
                    } label: {
                        Label("Add from hex", systemImage: "number")
                    }

                    Button {
                        showingColorPicker = true
                    } label: {
                        Label("Color Picker", systemImage: "eyedropper")
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Color")
                    }
                }
            }

            if !viewModel.isNewPalette {
                Section {
                    Button(role: .destructive) {
                        viewModel.deletePalette()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Palette")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.isNewPalette ? "Create Pelette" : "Edit Palette")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.savePalette()
                    dismiss()
                } label: {
                    Text("Save")
                }
                .disabled(viewModel.paletteName.isEmpty)
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(onColorSelected: { color in
                viewModel.addColor(hex: color.toHex())
            })
        }
        .alert("Add Color from Hex", isPresented: $showingHexInput) {
            TextField("e.g. #FF5500", text: $hexColorInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Cancel", role: .cancel) {
                hexColorInput = ""
            }

            Button("Add") {
                if isValidHexColor(hex: hexColorInput) {
                    viewModel.addColor(hex: hexColorInput)
                    hexColorInput = ""
                } else {
                    showingInvalidHexAlert = true
                }
            }
        }
        .alert("Invalid Hex Color", isPresented: $showingInvalidHexAlert) {
            Button("OK", role: .cancel) {
                hexColorInput = ""
            }
        } message: {
            Text("Please enter a valid hex color code (e.g. #FF5500 or FF5500)")
        }
    }

    private func isValidHexColor(hex: String) -> Bool {
        let hexColorPattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let hexColorPredicate = NSPredicate(format:"SELF MATCHES %@", hexColorPattern)
        return hexColorPredicate.evaluate(with: hex)
    }

    init(palette: Palette? = nil) {
        _viewModel = StateObject(wrappedValue: ViewModel(palette: palette))
    }
}

#Preview {
    NavigationStack {
        PaletteEditView(palette: Palette.defaultPalette)
    }
}
