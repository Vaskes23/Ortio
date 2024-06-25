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

enum Theme: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case system

    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
}

@Model
final class User {
    @Attribute(.unique) var username: String
    @Attribute var name: String
    var appearance: Int
    @Attribute(.externalStorage) var profileImage: Data?

    init(username: String, name: String, appearance: Int, profileImage: Data?) {
        self.username = username
        self.name = name
        self.appearance = appearance
        self.profileImage = profileImage
    }
    
    convenience init() {
        self.init(username: "placeholder", name: "Placeholder User", appearance: 0, profileImage: Data())
    }

    var profileUIImage: UIImage? {
        if let data = profileImage {
            return UIImage(data: data)
        }
        return nil
    }

    func updateProfileImage(_ image: UIImage) {
        self.profileImage = image.jpegData(compressionQuality: 0.8)
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
                        ProfileItemView(title: name, subtitle: "View Profile", profileImage: user.profileUIImage)
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
    var profileImage: UIImage?

    var body: some View {
        HStack {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
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
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPhotosPickerItem: PhotosPickerItem? = nil
    @Binding var name: String
    @State private var username: String = ""
    
    @State private var rotationAngle: Double = 0
    @State private var isFlipped: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Profile Picture")) {
                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .padding()
                            .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                            .animation(.default, value: rotationAngle)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .padding()
                            .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                            .animation(.default, value: rotationAngle)
                    }
                    PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                        Text("Change")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
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
                    withAnimation(.easeInOut(duration: 0.6)) {
                        rotationAngle += 180
                        isFlipped.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedImage = uiImage
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveUser() {
        user.name = name
        user.username = username
        if let selectedImage = selectedImage {
            user.updateProfileImage(selectedImage)
        }

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
            selectedImage = user.profileUIImage
        } else {
            user = User()
            modelContext.insert(user)
            do {
                try modelContext.save()
                name = user.name
                username = user.username
                selectedImage = user.profileUIImage
            } catch {
                print("Failed to save default user: \(error)")
            }
        }
    }
}
