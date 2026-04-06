//
//  SettingsView.swift
//  OrtioVision
//
//  App settings and user profile
//

import SwiftUI
import SwiftData
import OrtioShared

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var currentUser: User? {
        users.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    if let user = currentUser {
                        HStack {
                            if let imageData = user.profileImage,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No user profile found")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Appearance") {
                    if let user = currentUser {
                        Picker("Theme", selection: Binding(
                            get: { user.theme },
                            set: { user.theme = $0 }
                        )) {
                            ForEach(Theme.allCases) { theme in
                                Text(theme.description).tag(theme)
                            }
                        }
                    }
                }

                Section("Cloud") {
                    Button("Sign Out") {
                        // TODO: Implement sign out
                    }
                    .foregroundStyle(.red)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [User.self], inMemory: true)
}
