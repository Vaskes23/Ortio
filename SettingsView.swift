//
//  SettingsView.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 22.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI

#if canImport(AppKit)
import AppKit

extension NSImage {
    public func pngData() -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRepresentation = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRepresentation.representation(using: .png, properties: [:])
    }
}
#elseif canImport(UIKit)
import UIKit

extension UIImage {
    public func pngData() -> Data? {
        return self.pngData()
    }
}
#endif

enum ImageError: Error {
    case conversionFailed(String)
}

@Model
final class ImageModel {
    var type: String = "profile"  // Define different types if needed
    @Attribute(.externalStorage) var pngData: Data? = nil

    init(type: String, pngData: Data) {
        self.type = type
        self.pngData = pngData
    }

    #if canImport(AppKit)
    convenience init(type: String, image: NSImage) throws {
        guard let pngData = image.pngData() else {
            throw ImageError.conversionFailed("Unable to get PNG data for image")
        }
        self.init(type: type, pngData: pngData)
    }
    #elseif canImport(UIKit)
    convenience init(type: String, image: UIImage) throws {
        guard let pngData = image.pngData() else {
            throw ImageError.conversionFailed("Unable to get PNG data for image")
        }
        self.init(type: type, pngData: pngData)
    }
    #endif
}

@Model
final class User {
    @Attribute(.unique) var username: String
    @Attribute var name: String
    var appearance: Int
    @Relationship(deleteRule: .cascade) var profileImage: ImageModel?

    // Existing initializer
    init(username: String, name: String, appearance: Int, profileImage: ImageModel? = nil) {
        self.username = username
        self.name = name
        self.appearance = appearance
        self.profileImage = profileImage
    }
    
    // Default initializer
    convenience init() {
        self.init(username: "placeholder", name: "Placeholder User", appearance: 0)
    }
}

struct ThemePicker: View {
    @State private var selectedTheme: Theme = .system

    var body: some View {
        Picker("Appearance",
               selection: $selectedTheme) {
            ForEach(Theme.allCases, id: \.self) {
                Text($0.description)
                    .tag($0)
            }
        }
        .pickerStyle(.automatic)
    }
}

struct SettingsView: View {
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var soundEffectsEnabled = UserDefaults.standard.bool(forKey: "soundEffectsEnabled")
    @State private var recieveEmailsEnabled = UserDefaults.standard.bool(forKey: "recieveEmailsEnabled")
    @Query var users: [User]
    @State private var user: User = User()
    @State private var name: String = "Placeholder User"

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    NavigationLink(destination: EditProfileView(name: $name)) {
                        ProfileItemView(title: name, subtitle: "View Profile", imageName: "yourProfileImage")
                    }
                    Toggle("Enable Notifications", isOn: $notificationsEnabled.onChange(saveSettings))
                    Toggle("Enable Sound Effects", isOn: $soundEffectsEnabled.onChange(saveSettings))
                    Toggle("Receive Emails", isOn: $recieveEmailsEnabled.onChange(saveSettings))
                    ThemePicker()
                }
                .navigationTitle("Account")
                .navigationBarTitleDisplayMode(.inline)
                Spacer()
            }
        }
        .onAppear {
            loadUser()
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
        UserDefaults.standard.set(recieveEmailsEnabled, forKey: "recieveEmailsEnabled")
    }

    private func loadUser() {
        @Environment(\.modelContext) var modelContext
        
        if let existingUser = users.first {
            user = existingUser
            name = user.name
        } else {
            user = User()
            modelContext.insert(user)
            do {
                try modelContext.save()
                name = user.name
            } catch {
                print("Failed to save default user: \(error)")
            }
        }
    }
}


extension Binding {
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
    }
}

struct ProfileItemView: View {
    var title: String
    var subtitle: String
    var imageName: String

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    @Query var users: [User]

    @State private var user: User = User()
    @State private var selectedImage: UIImage? = nil // or NSImage for macOS
    @State private var selectedPhotosPickerItem: PhotosPickerItem? = nil
    @Binding var name: String
    @State private var username: String = ""

    var body: some View {
        Form {
            Section(header: Text("Profile Picture")) {
                HStack {
                    if let image = selectedImage {
                        Image(uiImage: image)  // or Image(nsImage: image) for macOS
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding()
                    }
                    PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                        Text("Change")
                    }
                }
            }
            Section(header: Text("User Info")) {
                TextField("Name", text: $name)
                TextField("Username", text: $username)
            }
        }
        .navigationBarItems(trailing: Button("Save") {
            saveUser()
        })
        .onAppear {
            loadUser()
        }
        .onChange(of: selectedPhotosPickerItem) { newItem in
            Task {
                if let newItem = newItem, let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveUser() {
        // Update the user
        user.name = name
        user.username = username
        if let selectedImage = selectedImage {
            do {
                let imageModel = try ImageModel(type: "profile", image: selectedImage)
                user.profileImage = imageModel
                modelContext.insert(imageModel)
            } catch {
                // Handle error
                print("Failed to save image: \(error)")
            }
        }

        // Save the context
        do {
            modelContext.insert(user)  // Ensure the user is in the context
            try modelContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save user: \(error)")
        }
    }

    private func loadUser() {
        if let existingUser = users.first {
            user = existingUser
            name = user.name
            username = user.username
            if let profileImage = user.profileImage, let data = profileImage.pngData, let image = UIImage(data: data) {
                selectedImage = image
            }
        } else {
            // Insert a default user if no users are found
            user = User()
            modelContext.insert(user)
            do {
                try modelContext.save()
                name = user.name
                username = user.username
            } catch {
                print("Failed to save default user: \(error)")
            }
        }
    }
}

