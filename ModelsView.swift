//
//  ModelsView.swift
//  ModelCapture
//
//  Created by Matyas Vascak on 23.12.2023.
//

import Foundation
import SwiftUI
import SwiftData
import QuickLookThumbnailing

enum Theme: String, CaseIterable, Identifiable {
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

struct ModelsView: View {
    @State private var searchText = ""
    @ObservedObject var viewModel: ModelsViewModel
    @State private var showingProfileSheet = false // State variable for profile sheet

    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ObjectCaptureButtonView()
                        HelpView()
                        
                        ForEach(viewModel.models.filter { $0.url.pathExtension == "usdz" }) { model in
                            ThumbnailView(modelURL: model.url)
                                .onTapGesture {
                                    viewModel.selectedModelForPreview = model
                                }
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Models")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 10) // Adjust padding as needed
                        Spacer()
                        profileButton
                    }
                }
            }
            .sheet(isPresented: $showingProfileSheet) {
                ProfileView()
            }
            .onAppear(perform: viewModel.loadModelsFromDirectories)
            .sheet(item: $viewModel.selectedModelForPreview, onDismiss: {
                viewModel.selectedModelForPreview = nil
            }) { item in
                ModelView(modelFile: item.url, endCaptureCallback: {
                    viewModel.selectedModelForPreview = nil
                })
            }
        }
    }

    var profileButton: some View {
        Button(action: {
            showingProfileSheet = true // Toggle the sheet presentation
        }) {
            Image(systemName: "person.crop.circle") // Use your own profile image name here
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
}

struct ProfileView: View {
    @State private var showingEditProfileSheet = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    ProfileItemView(title: "[username]", subtitle: "View Profile", imageName: "yourProfileImage", showingEditProfileSheet: $showingEditProfileSheet)
                    Text("Your name and photo will be shown to others with whom you share projects.")
                    SettingsView()
                    ThemePicker()
                }
                .listStyle(InsetGroupedListStyle())

                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .navigationBarTitle(Text("Account"), displayMode: .inline)
            .sheet(isPresented: $showingEditProfileSheet) {
                EditProfileView()
            }
        }
    }
}


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
            Toggle("Enable Notifications", isOn: $notificationsEnabled.onChange(saveSettings))
            Toggle("Enable Sound Effects", isOn: $soundEffectsEnabled.onChange(saveSettings))
            Toggle("Receive Emails", isOn: $recieveEmailsEnabled.onChange(saveSettings))
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

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        TextField("Models, Notes, Help...", text: $text)
            .padding(7)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

struct HelpView: View {
    var body: some View{
        Button(action: {
            //TODO: To be implemented / shows HelpView
        }) {
            VStack{
                Image(systemName: "questionmark.circle")
                    .font(.largeTitle)
                    .padding(2)
                Text("Help")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.yellow)
    }
}

struct ObjectCaptureButtonView: View {
    @State private var showingLoadGuidedCaptureView = false
    
    var body: some View {
        Button(action: {
            //Show LoadGuidedCaptureView
            self.showingLoadGuidedCaptureView = true
        }) {
            VStack {
                Image(systemName: "camera")
                    .font(.largeTitle)
                    .padding(2)
                Text("New")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.blue)
        // Present the LoadGuidedCaptureView modally
        .sheet(isPresented: $showingLoadGuidedCaptureView) {
            LoadGuidedCaptureView()
        }
    }
}

struct ThumbnailView: View {
    var modelURL: URL
    @State private var thumbnailImage: UIImage?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Group {
                if let thumbnailImage = thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .if(colorScheme == .dark) { view in
                            view.colorInvert()
                        }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear(perform: generateThumbnail)
                        .if(colorScheme == .dark) { view in
                            view.colorInvert()
                        }
                }
            }
            .cornerRadius(10)

            StarButton()
                .offset(x: -40, y: 40)
        }
    }
    
    private func generateThumbnail() {
        let request = QLThumbnailGenerator.Request(fileAt: modelURL, size: CGSize(width: 100, height: 100), scale: UIScreen.main.scale, representationTypes: .thumbnail)
        let generator = QLThumbnailGenerator.shared
        generator.generateBestRepresentation(for: request) { (thumbnail, error) in
            DispatchQueue.main.async {
                if let thumbnail = thumbnail {
                    self.thumbnailImage = thumbnail.uiImage
                } else {
                    print("Thumbnail generation error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

struct StarButton: View {
    @State private var isStarred = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: {
            isStarred.toggle()
        }) {
            if(colorScheme == .light) {
                Image(systemName: isStarred ? "star.fill" : "star")
                    .foregroundColor(isStarred ? .yellow : .gray)
                    .padding(5)
                    .background(Color.white)
            } else {
                Image(systemName: isStarred ? "star.fill" : "star")
                    .foregroundColor(isStarred ? .yellow : .gray)
                    .padding(5)
                    .background(Color.black )
            }
        }
    }
}

#Preview {
    ModelsView(viewModel: ModelsViewModel())
}
