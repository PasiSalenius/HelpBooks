import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    let onImport: (URL, URL?) -> Void

    @State private var contentFolder: URL?
    @State private var assetsFolder: URL?

    var canImport: Bool {
        contentFolder != nil
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Import Your Help Book Content")
                .font(.title)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                // Content drop zone
                ImportDropZone(
                    title: "Content Folder",
                    subtitle: "Markdown files (.md)",
                    icon: "doc.text.fill",
                    panelMessage: "Select your content folder (e.g., content/docs)",
                    selectedFolder: $contentFolder
                )

                // Assets drop zone
                ImportDropZone(
                    title: "Assets Folder",
                    subtitle: "Images, CSS, JavaScript (Optional)",
                    icon: "photo.fill",
                    panelMessage: "Select your assets folder (e.g., static/images)",
                    selectedFolder: $assetsFolder
                )
            }
            .padding()

            VStack(spacing: 12) {
                Button {
                    guard let content = contentFolder else { return }
                    onImport(content, assetsFolder)
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canImport)

                Text(canImport ? "Ready to import" : "Select at least a content folder to continue")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                Text("Getting Started")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Drag or select your content folder (required)", systemImage: "1.circle.fill")
                    Label("Drag or select your assets folder (optional)", systemImage: "2.circle.fill")
                    Label("Click Import to process both folders", systemImage: "3.circle.fill")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct ImportDropZone: View {
    let title: String
    let subtitle: String
    let icon: String
    let panelMessage: String
    @Binding var selectedFolder: URL?

    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            // Icon (same size in both states)
            Image(systemName: selectedFolder != nil ? "checkmark.circle.fill" : icon)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundColor(selectedFolder != nil ? .green : (isTargeted ? .accentColor : .secondary))

            // Text content (same number of lines in both states)
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)

                if let folder = selectedFolder {
                    Text(folder.lastPathComponent)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 44)

            // Button (same size in both states)
            Button(selectedFolder != nil ? "Change" : "Choose Folder") {
                chooseFolder()
            }
            .buttonStyle(.bordered)
            .frame(minWidth: 120)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    selectedFolder != nil ? Color.green :
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: selectedFolder != nil ? [] : [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            selectedFolder != nil ? Color.green.opacity(0.05) :
                            isTargeted ? Color.accentColor.opacity(0.1) : Color.clear
                        )
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = panelMessage

        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            DispatchQueue.main.async {
                selectedFolder = url
            }
        }

        return true
    }
}
