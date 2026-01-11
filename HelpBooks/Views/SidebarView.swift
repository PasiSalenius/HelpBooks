import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    let fileTree: FileTreeNode?
    let assets: [AssetReference]
    @Binding var selectedDocumentId: UUID?
    @Binding var selectedAssetId: UUID?
    var onDropContentFolder: ((URL) -> Void)?
    var onDropAssetsFolder: ((URL) -> Void)?

    @State private var dividerPosition: CGFloat = 0.6 // 60% for content, 40% for assets

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Content section (top)
                ContentSectionView(
                    fileTree: fileTree,
                    selectedDocumentId: $selectedDocumentId,
                    onDropFolder: onDropContentFolder
                )
                .frame(height: geometry.size.height * dividerPosition)

                // Draggable divider
                Divider()
                    .overlay(
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 8)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newPosition = (value.location.y + geometry.size.height * dividerPosition) / geometry.size.height
                                        dividerPosition = min(max(newPosition, 0.2), 0.8)
                                    }
                            )
                            .cursor(.resizeUpDown)
                    )

                // Assets section (bottom)
                AssetsSectionView(
                    assets: assets,
                    selectedAssetId: $selectedAssetId,
                    onDropFolder: onDropAssetsFolder
                )
                .frame(height: geometry.size.height * (1 - dividerPosition))
            }
        }
        .navigationTitle("Project")
    }
}

struct ContentSectionView: View {
    let fileTree: FileTreeNode?
    @Binding var selectedDocumentId: UUID?
    var onDropFolder: ((URL) -> Void)?

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Content")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))

            // File tree
            List(selection: $selectedDocumentId) {
                if let tree = fileTree {
                    ForEach(tree.children ?? []) { node in
                        FileTreeNodeView(node: node, selectedId: $selectedDocumentId)
                    }
                } else {
                    Text("No content imported")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedDocumentId) { oldValue, newValue in
                print("Selection changed from \(oldValue?.uuidString ?? "nil") to \(newValue?.uuidString ?? "nil")")
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers)
            }
            .overlay {
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .padding(4)
                        .allowsHitTesting(false)
                }
            }
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
                onDropFolder?(url)
            }
        }

        return true
    }
}

struct AssetsSectionView: View {
    let assets: [AssetReference]
    @Binding var selectedAssetId: UUID?
    var onDropFolder: ((URL) -> Void)?

    @State private var isDropTargeted = false
    @State private var expandedTypes: Set<AssetReference.AssetType> = [.image]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assets")
                    .font(.headline)
                Spacer()
                Text("\(assets.count)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))

            // Assets list
            List(selection: $selectedAssetId) {
                if assets.isEmpty {
                    Text("No assets imported")
                        .foregroundColor(.secondary)
                        .font(.body)
                } else {
                    ForEach(groupedAssets.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { assetType, typeAssets in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedTypes.contains(assetType) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedTypes.insert(assetType)
                                    } else {
                                        expandedTypes.remove(assetType)
                                    }
                                }
                            )
                        ) {
                            ForEach(typeAssets) { asset in
                                Label(asset.fileName, systemImage: assetType.systemImage)
                                    .font(.body)
                                    .tag(asset.id)
                            }
                        } label: {
                            Label("\(assetType.displayName) (\(typeAssets.count))", systemImage: assetType.systemImage)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers)
            }
            .overlay {
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .padding(4)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var groupedAssets: [AssetReference.AssetType: [AssetReference]] {
        Dictionary(grouping: assets, by: \.type)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            DispatchQueue.main.async {
                onDropFolder?(url)
            }
        }

        return true
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onContinuousHover { phase in
            switch phase {
            case .active:
                cursor.set()
            case .ended:
                NSCursor.arrow.set()
            }
        }
    }
}

struct FileTreeNodeView: View {
    let node: FileTreeNode
    @Binding var selectedId: UUID?
    @State private var isExpanded = true

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                if let children = node.children {
                    ForEach(children) { child in
                        FileTreeNodeView(node: child, selectedId: $selectedId)
                    }
                }
            } label: {
                Label(node.name, systemImage: "folder")
                    .foregroundColor(.primary)
            }
        } else {
            if let docId = node.documentId {
                Button {
                    selectedId = docId
                    print("Button clicked for: \(node.name), ID: \(docId)")
                } label: {
                    Label(node.name, systemImage: "doc.text")
                }
                .buttonStyle(.plain)
                .tag(docId)
            }
        }
    }
}
