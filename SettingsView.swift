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

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    ProfileItemView(title: "[username]", subtitle: "View Profile", imageName: "yourProfileImage", showingEditProfileSheet: .constant(false))
                    Text("Your name and photo will be shown to others with whom you share projects.")
                    NavigationLink(destination: SettingsDetailView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    ThemePicker()
                }
                .listStyle(InsetGroupedListStyle())
                Spacer()
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsDetailView: View {
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var soundEffectsEnabled = UserDefaults.standard.bool(forKey: "soundEffectsEnabled")
    @State private var recieveEmailsEnabled = UserDefaults.standard.bool(forKey: "recieveEmailsEnabled")

    var body: some View {
        Form {
            Toggle("Enable Notifications", isOn: $notificationsEnabled.onChange(saveSettings))
            Toggle("Enable Sound Effects", isOn: $soundEffectsEnabled.onChange(saveSettings))
            Toggle("Receive Emails", isOn: $recieveEmailsEnabled.onChange(saveSettings))
        }
        .navigationTitle("Settings")
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

struct ThemePicker: View {
    @State private var selectedTheme: Theme = .system

    var body: some View {
        Picker("Appearance", selection: $selectedTheme) {
            ForEach(Theme.allCases) {
                Text($0.description).tag($0)
            }
        }
        .pickerStyle(.automatic)
    }
}

struct ProfileItemView: View {
    var title: String
    var subtitle: String
    var imageName: String
    @Binding var showingEditProfileSheet: Bool

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Button(action: {
                    showingEditProfileSheet = true
                }) {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
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
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                presentationMode.wrappedValue.dismiss()
            })
            .navigationBarTitle("Edit Profile", displayMode: .inline)
        }
    }
}
