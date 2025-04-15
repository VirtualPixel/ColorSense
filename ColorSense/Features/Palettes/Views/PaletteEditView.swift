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
    @EnvironmentObject var camera: CameraModel

    @StateObject private var viewModel: ViewModel
    @State private var hexColorInput: String = ""
    @State private var showingColorPicker: Bool = false
    @State private var showingHexInput: Bool = false
    @State private var showingInvalidHexAlert: Bool = false
    @State private var isShowingDeleteAlert: Bool = false
    @State private var editMode: EditMode

    var body: some View {
        NavigationStack {
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
                            Button {
                                UIPasteboard.general.string = color.wrappedHex
                            } label: {
                                Label("Copy Hex", systemImage: "doc.on.doc")
                            }
                        }
                    }
                    .onDelete(perform: { indexSet in
                        viewModel.removeColors(at: indexSet)
                        viewModel.savePalette(context: context)
                    })
                    .onMove(perform: { source,destination in
                        viewModel.moveColors(from: source, to: destination)
                        viewModel.savePalette(context: context)
                    })

                    Button {
                        showingColorPicker = true
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
                            isShowingDeleteAlert = true
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
                    EditButton()
                        .disabled(viewModel.paletteName.isEmpty && editMode == .active)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    SharePalette(palette: viewModel.palette)
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(onColorSelected: { color in
                    viewModel.addColor(hex: color.toHex())
                    viewModel.savePalette(context: context)
                })
            }
            .alert("Invalid Hex Color", isPresented: $showingInvalidHexAlert) {
                Button("OK", role: .cancel) {
                    hexColorInput = ""
                }
            } message: {
                Text("Please enter a valid hex color code (e.g. #FF5500 or FF5500)")
            }
            .alert("Are you sure you want to delete \(viewModel.paletteName.isEmpty ? "this palette" : viewModel.paletteName)?", isPresented: $isShowingDeleteAlert) {
                Button("Cancel", role: .cancel){}
                Button("Delete", role: .destructive) {
                    viewModel.deletePalette(context: context)
                    dismiss()
                }
            }
            .onChange(of: editMode) { oldValue, newValue in
                if newValue == .inactive {
                    print("Saved!")
                    viewModel.savePalette(context: context)
                }
            }
        }
    }

    private func isValidHexColor(hex: String) -> Bool {
        let hexColorPattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let hexColorPredicate = NSPredicate(format:"SELF MATCHES %@", hexColorPattern)
        return hexColorPredicate.evaluate(with: hex)
    }

    init(palette: Palette? = nil, selectedColor: Color? = nil, editMode: EditMode = .inactive) {
        _viewModel = StateObject(wrappedValue: ViewModel(palette: palette, selectedColor: selectedColor))
        self.editMode = editMode
    }
}

#Preview {
    NavigationStack {
        PaletteEditView(palette: Palette.defaultPalette)
            .environmentObject(PreviewCameraModel())
    }
}
