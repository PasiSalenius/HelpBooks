import SwiftUI
import UniformTypeIdentifiers

struct MetadataEditorView: View {
    @Binding var metadata: HelpBookMetadata
    @Environment(\.dismiss) private var dismiss
    @State private var showingIconPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Bundle Information Section
                VStack(alignment: .leading, spacing: 12) {
                    FormRow(label: "Bundle Identifier:") {
                        TextField("com.example.MyApp.help", text: $metadata.bundleIdentifier)
                            .textFieldStyle(.roundedBorder)
                    }

                    FormRow(label: "Bundle Name:") {
                        TextField("MyApp", text: $metadata.bundleName)
                            .textFieldStyle(.roundedBorder)
                    }

                    FormRow(label: "Version:") {
                        HStack {
                            TextField("1.0", text: $metadata.bundleShortVersionString)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)

                            Text("Build:")
                                .foregroundColor(.secondary)

                            TextField("1", text: $metadata.bundleVersion)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    FormRowHelp(text: "The bundle identifier should typically be your app's bundle ID followed by \".help\" (e.g., com.example.MyApp.help). The bundle name is a short name for the help book bundle.")
                }

                Divider()

                // Help Book Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    FormRow(label: "Help Book Title:") {
                        TextField("MyApp Help", text: $metadata.helpBookTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    FormRow(label: "Icon:") {
                        HStack {
                            if let iconPath = metadata.helpBookIconPath, !iconPath.isEmpty {
                                if let image = NSImage(contentsOfFile: iconPath) {
                                    Image(nsImage: image)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                            }

                            Button("Choose Icon") {
                                chooseIcon()
                            }

                            if metadata.helpBookIconPath != nil {
                                Button("Clear") {
                                    metadata.helpBookIconPath = nil
                                }
                            }
                        }
                    }

                    FormRowHelp(text: "The Help Book Title is displayed to users when they access help. The icon is optional and appears in the Help menu.")
                }

                Divider()

                // Advanced Section
                VStack(alignment: .leading, spacing: 12) {
                    FormRow(label: "Development Region:") {
                        TextField("en", text: $metadata.developmentRegion)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                    }

                    FormRow(label: "KB Product:") {
                        TextField("Optional", text: $metadata.kbProduct)
                            .textFieldStyle(.roundedBorder)
                    }

                    FormRow(label: "KB URL:") {
                        TextField("https://example.com", text: $metadata.kbURL)
                            .textFieldStyle(.roundedBorder)
                    }

                    FormRowHelp(text: "Development Region sets the default language (usually 'en' for English). KB Product and KB URL are optional fields for linking to external knowledge base resources.")
                }
            }
            .padding(20)
        }
        .frame(width: 500, height: 500)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    // Save metadata to UserDefaults for next time
                    metadata.saveToUserDefaults()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .navigationTitle("Help Book Metadata")
    }

    private func chooseIcon() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .image]
        panel.message = "Select an icon for your Help Book"

        if panel.runModal() == .OK, let url = panel.url {
            metadata.helpBookIconPath = url.path
        }
    }
}

struct FormRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .frame(width: 140, alignment: .trailing)
                .foregroundColor(.primary)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FormRowHelp: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer()
                .frame(width: 140)

            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
