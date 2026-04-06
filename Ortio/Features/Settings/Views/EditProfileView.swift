//
//  EditProfileView.swift
//  Ortio
//
//  Created by Matyas Vascak on 22.06.2024.
//

import SwiftUI
import SwiftData
import PhotosUI
import os

/// Form for editing user profile: name, username, and photo.
/// Loads the user from SwiftData via `@Query` on appear.
struct EditProfileView: View {
    private static let logger = Logger(
        subsystem: OrtioApp.subsystem,
        category: "EditProfileView"
    )
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    @Query var users: [User]

    @State private var user: User?
    @State private var selectedImage: UIImage?
    @State private var selectedPhotosPickerItem: PhotosPickerItem?
    @Binding var name: String
    @State private var username: String = ""
    @State private var errorMessage: String?

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
                        TextField("Name", text: $name)
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
            loadUser()
        }
        .onChange(of: selectedPhotosPickerItem) { newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        rotationAngle += 180
                        isFlipped.toggle()
                    }
                    try? await Task.sleep(for: .milliseconds(300))
                    selectedImage = uiImage
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func saveUser() {
        guard let user else { return }
        user.name = name
        user.username = username
        if let selectedImage = selectedImage {
            user.updateProfileImage(selectedImage)
        }

        do {
            try modelContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            Self.logger.error("Failed to save user: \(error)")
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
    }

    /// Loads the existing user from the `@Query`, or creates a default one.
    private func loadUser() {
        if let existingUser = users.first {
            user = existingUser
            name = existingUser.name
            username = existingUser.username
            selectedImage = existingUser.profileUIImage
        } else {
            let newUser = User()
            modelContext.insert(newUser)
            do {
                try modelContext.save()
                user = newUser
                name = newUser.name
                username = newUser.username
                selectedImage = newUser.profileUIImage
            } catch {
                Self.logger.error("Failed to save default user: \(error)")
                errorMessage = "Failed to create profile: \(error.localizedDescription)"
            }
        }
    }
}
