import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onDrop: (URL) -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundColor(.secondary)

            Text("Drag Hugo Content Folder Here")
                .font(.headline)

            Text("Or click to browse")
                .font(.footnote)
                .foregroundColor(.secondary)

            Button("Choose Folder") {
                chooseFolder()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary,
                    style: StrokeStyle(lineWidth: 2, dash: [10])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ?
                              Color.accentColor.opacity(0.1) :
                              Color.clear)
                )
        )
        .padding()
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your Hugo content folder"

        if panel.runModal() == .OK, let url = panel.url {
            onDrop(url)
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
                onDrop(url)
            }
        }

        return true
    }
}
