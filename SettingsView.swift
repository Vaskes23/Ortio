//
//  SettingsView.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 22.06.2024.
//  Copyright © 2024 Apple. All rights reserved.

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
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
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
    
    var theme: Theme {
        get {
            switch appearance {
            case 1: return .dark
            case 2: return .system
            default: return .light
            }
        }
        set {
            switch newValue {
            case .light: appearance = 0
            case .dark: appearance = 1
            case .system: appearance = 2
            }
        }
    }
}

struct ThemePicker: View {
    @Binding var selectedTheme: Theme
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Theme.allCases, id: \.self) { theme in
                Button(action: {
                    selectedTheme = theme
                }) {
                    HStack {
                        Image(systemName: iconForTheme(theme))
                            .foregroundColor(.primary)
                            .frame(width: 20)
                        
                        Text(theme.description)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Select \(theme.description) theme")
            }
        }
    }
    
    private func iconForTheme(_ theme: Theme) -> String {
        switch theme {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .system:
            return "gear"
        }
    }
}

struct SettingsView: View {
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var soundEffectsEnabled = UserDefaults.standard.bool(forKey: "soundEffectsEnabled")
    @State private var recieveEmailsEnabled = UserDefaults.standard.bool(forKey: "recieveEmailsEnabled")
    @Query var users: [User]
    @State private var user: User = User()
    @State private var name: String = "Placeholder User"
    @State private var selectedTheme: Theme = .system
    
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Profile Section
                    VStack(spacing: 16) {
                        sectionHeader("Profile")
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: EditProfileView(name: $name)) {
                                ProfileItemView(title: name, subtitle: "View Profile", profileImage: user.profileUIImage)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Edit profile")
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Notifications Section
                    VStack(spacing: 16) {
                        sectionHeader("Notifications")
                        
                        VStack(spacing: 0) {
                            settingsRow(
                                icon: "bell",
                                title: "Push Notifications",
                                toggle: $notificationsEnabled.onChange(saveSettings)
                            )
                            
                            settingsRow(
                                icon: "speaker.wave.2",
                                title: "Sound Effects",
                                toggle: $soundEffectsEnabled.onChange(saveSettings)
                            )
                            
                            settingsRow(
                                icon: "envelope",
                                title: "Email Updates",
                                toggle: $recieveEmailsEnabled.onChange(saveSettings),
                                isLast: true
                            )
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Appearance Section
                    VStack(spacing: 16) {
                        sectionHeader("Appearance")
                        
                        VStack(spacing: 0) {
                            ThemePicker(selectedTheme: $selectedTheme.onChange(saveTheme))
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(selectedTheme.colorScheme)
        }
        .onAppear {
            loadUser()
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private func settingsRow(
        icon: String,
        title: String,
        toggle: Binding<Bool>,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: toggle)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            
            if !isLast {
                Divider()
                    .padding(.leading, 48)
            }
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
        UserDefaults.standard.set(recieveEmailsEnabled, forKey: "recieveEmailsEnabled")
    }
    
    private func saveTheme() {
        user.theme = selectedTheme
        do {
            try modelContext.save()
        } catch {
            print("Failed to save theme: \(error)")
        }
    }

    private func loadUser() {
        if let existingUser = users.first {
            user = existingUser
            name = user.name
            selectedTheme = user.theme
        } else {
            user = User()
            modelContext.insert(user)
            do {
                try modelContext.save()
                name = user.name
                selectedTheme = user.theme
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
        HStack(spacing: 12) {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
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
            Section {
                HStack(spacing: 16) {
                    // Collapsed avatar to 56x56
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
