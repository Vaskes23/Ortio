//
//  EditProfileView.swift
//  Ortio
//
//  Created by Matyas Vascak on 22.06.2024.
//

import os
import SwiftUI
import SwiftData
import PhotosUI

/// Form for editing user profile: name, username, and photo.
struct EditProfileView: View {
    private static let logger = Logger(
        subsystem: OrtioApp.subsystem,
        category: "EditProfileView"
    )
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var viewModel: SettingsViewModel
    @State private var selectedImage: UIImage?
    @State private var selectedPhotosPickerItem: PhotosPickerItem?
    @State private var username: String = ""

    @State private var rotationAngle: Double = 0
    @State private var isFlipped: Bool = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                                .animation(.default, value: rotationAngle)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .foregroundColor(.gray)
                                .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                                .animation(.default, value: rotationAngle)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile Photo")
                            .font(.callout)
                            .fontWeight(.medium)

                        PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                            Text("Choose Photo")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            Section("User Information") {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        TextField("Name", text: $viewModel.name)
                            .font(.callout)
                    }

                    Divider()

                    HStack {
                        Image(systemName: "at")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        TextField("Username", text: $username)
                            .font(.callout)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarItems(trailing: Button("Save") {
            saveUser()
        })
        .onAppear {
            username = viewModel.user.username
            selectedImage = viewModel.user.profileUIImage
        }
        .onChange(of: selectedPhotosPickerItem) { _, newItem in
            Task { @MainActor in
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.6)) {
                        rotationAngle += 180
                        isFlipped.toggle()
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    selectedImage = uiImage
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func saveUser() {
        let didSave = viewModel.saveProfile(
            username: username,
            selectedImage: selectedImage,
            context: modelContext
        )
        if didSave {
            dismiss()
        }
    }
}
