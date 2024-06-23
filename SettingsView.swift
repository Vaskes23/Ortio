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

struct ThemePicker: View {
    @State private var selectedTheme: Theme = .system

    var body: some View {
        Picker("Appearance",
               selection: $selectedTheme) {
            ForEach(Theme.allCases) {
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

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    NavigationLink(destination: EditProfileView()) {
                        ProfileItemView(title: "[username]", subtitle: "View Profile", imageName: "yourProfileImage")
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
    }

    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
        UserDefaults.standard.set(recieveEmailsEnabled, forKey: "recieveEmailsEnabled")
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

    var body: some View {
        Form {
            Section(header: Text("Profile Picture")) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding()
                    Button(action: {
                        // Action to change profile picture
                    }) {
                        Text("Change")
                    }
                }
            }
            Section(header: Text("User Info")) {
                TextField("Name", text: .constant("Username Example"))
                TextField("Username", text: .constant("@username"))
            }
        }
        .navigationBarItems(trailing: Button("Save") {
            presentationMode.wrappedValue.dismiss()
        })
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
