import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    let fileTree: FileTreeNode?
    let assets: [AssetReference]
    @Binding var selectedDocumentIds: Set<UUID>
    @Binding var selectedAssetIds: Set<UUID>
    var onDropContentFolder: ((URL) -> Void)?
    var onDropAssetsFolder: ((URL) -> Void)?
    var onDeleteDocuments: ((Set<UUID>) -> Void)?
    var onDeleteAssets: ((Set<UUID>) -> Void)?

    @State private var dividerPosition: CGFloat = 0.6 // 60% for content, 40% for assets

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Content section (top)
                ContentSectionView(
                    fileTree: fileTree,
                    selectedDocumentIds: $selectedDocumentIds,
                    onDropFolder: onDropContentFolder,
                    onDelete: onDeleteDocuments
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
                    selectedAssetIds: $selectedAssetIds,
                    onDropFolder: onDropAssetsFolder,
                    onDelete: onDeleteAssets
                )
                .frame(height: geometry.size.height * (1 - dividerPosition))
            }
        }
        .navigationTitle("Project")
    }
}

struct ContentSectionView: View {
    let fileTree: FileTreeNode?
    @Binding var selectedDocumentIds: Set<UUID>
    var onDropFolder: ((URL) -> Void)?
    var onDelete: ((Set<UUID>) -> Void)?

    @State private var isDropTargeted = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Content")
                    .font(.headline)
                Spacer()
                if !selectedDocumentIds.isEmpty {
                    Text("\(selectedDocumentIds.count) selected")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))

            // File tree
            List(selection: $selectedDocumentIds) {
                if let tree = fileTree {
                    ForEach(tree.children ?? []) { node in
                        FileTreeNodeView(node: node, selectedIds: $selectedDocumentIds)
                    }
                } else {
                    Text("No content imported")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
            }
            .listStyle(.sidebar)
            .focused($isFocused)
            .onDeleteCommand {
                if !selectedDocumentIds.isEmpty {
                    onDelete?(selectedDocumentIds)
                    selectedDocumentIds = []
                }
            }
            .contextMenu(forSelectionType: UUID.self) { items in
                if !items.isEmpty {
                    Button("Delete", role: .destructive) {
                        onDelete?(Set(items))
                        selectedDocumentIds.subtract(items)
                    }
                }
            }
            .onChange(of: selectedDocumentIds) { oldValue, newValue in
                print("Selection changed from \(oldValue.count) to \(newValue.count) documents")
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers -> Bool in
                guard !providers.isEmpty else { return false }

                // Process each dropped item
                for provider in providers {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) else {
                            return
                        }

                        DispatchQueue.main.async {
                            onDropFolder?(url)
                        }
                    }
                }

                return true
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
        .onAppear {
            isFocused = true
        }
    }
}

struct AssetsSectionView: View {
    let assets: [AssetReference]
    @Binding var selectedAssetIds: Set<UUID>
    var onDropFolder: ((URL) -> Void)?
    var onDelete: ((Set<UUID>) -> Void)?

    @State private var isDropTargeted = false
    @State private var expandedTypes: Set<AssetReference.AssetType> = [.image]
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assets")
                    .font(.headline)
                Spacer()
                if !selectedAssetIds.isEmpty {
                    Text("\(selectedAssetIds.count) selected")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(assets.count)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))

            // Assets list
            List(selection: $selectedAssetIds) {
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
                            ForEach(typeAssets.sorted(by: { $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending })) { asset in
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
            .focused($isFocused)
            .onDeleteCommand {
                if !selectedAssetIds.isEmpty {
                    onDelete?(selectedAssetIds)
                    selectedAssetIds = []
                }
            }
            .contextMenu(forSelectionType: UUID.self) { items in
                if !items.isEmpty {
                    Button("Delete", role: .destructive) {
                        onDelete?(Set(items))
                        selectedAssetIds.subtract(items)
                    }
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers -> Bool in
                guard !providers.isEmpty else { return false }

                // Process each dropped item
                for provider in providers {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) else {
                            return
                        }

                        DispatchQueue.main.async {
                            onDropFolder?(url)
                        }
                    }
                }

                return true
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
    @Binding var selectedIds: Set<UUID>
    @State private var isExpanded = true

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                if let children = node.children {
                    ForEach(children) { child in
                        FileTreeNodeView(node: child, selectedIds: $selectedIds)
                    }
                }
            } label: {
                Label(node.name, systemImage: "folder")
                    .foregroundColor(.primary)
                    .tag(node.id)
            }
        } else {
            if let docId = node.documentId {
                Label(node.name, systemImage: "doc.text")
                    .tag(docId)
            }
        }
    }
}
