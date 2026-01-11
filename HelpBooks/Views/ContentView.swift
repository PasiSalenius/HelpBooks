import SwiftUI

struct ContentView: View {
    @State private var viewModel = ProjectViewModel()
    @State private var selectedDocumentId: UUID?
    @State private var selectedAssetId: UUID?
    @State private var showingMetadataEditor = false
    @State private var showingExport = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var selectedDocument: MarkdownDocument? {
        guard let id = selectedDocumentId else {
            print("No selectedDocumentId")
            return nil
        }
        let doc = viewModel.project?.documents.first { $0.id == id }
        print("Selected document: \(doc?.fileName ?? "nil"), ID: \(id)")
        return doc
    }

    var selectedAsset: AssetReference? {
        guard let id = selectedAssetId else { return nil }
        return viewModel.project?.assets.first { $0.id == id }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            if let project = viewModel.project {
                SidebarView(
                    fileTree: project.fileTree,
                    assets: project.assets,
                    selectedDocumentId: $selectedDocumentId,
                    selectedAssetId: $selectedAssetId,
                    onDropContentFolder: { url in
                        // Re-import content folder
                        viewModel.importContentAndAssets(contentURL: url, assetsURL: nil)
                    },
                    onDropAssetsFolder: viewModel.addAssetsFromFolder
                )
            } else {
                Text("No Project")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            if let project = viewModel.project {
                if let asset = selectedAsset, asset.type == .image {
                    ImagePreviewView(asset: asset)
                } else if let document = selectedDocument {
                    PreviewPane(
                        document: document,
                        assets: project.assets,
                        viewModel: viewModel.previewViewModel
                    )
                } else {
                    ContentUnavailableView(
                        "No Document Selected",
                        systemImage: "doc.text",
                        description: Text("Select a document or image from the sidebar to preview")
                    )
                }
            } else {
                ImportView(
                    onImport: viewModel.importContentAndAssets
                )
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 230, max: 400)
        .toolbar {
            ToolbarItemGroup {
                if viewModel.project != nil {
                    Button {
                        showingMetadataEditor = true
                    } label: {
                        Label("Metadata", systemImage: "info.circle")
                    }

                    Button {
                        showingExport = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.project?.isValid != true)
                }
            }
        }
        .sheet(isPresented: $showingMetadataEditor) {
            if let project = viewModel.project {
                MetadataEditorView(metadata: Binding(
                    get: { project.metadata },
                    set: { project.metadata = $0 }
                ))
            }
        }
        .sheet(isPresented: $showingExport) {
            if let project = viewModel.project {
                ExportDialogView(project: project)
            }
        }
        .overlay {
            if viewModel.isImporting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Importing...")
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { viewModel.importError != nil },
            set: { if !$0 { viewModel.importError = nil } }
        )) {
            Button("OK") { viewModel.importError = nil }
        } message: {
            if let error = viewModel.importError {
                Text(error)
            }
        }
        .onChange(of: selectedDocumentId) { _, newValue in
            if newValue != nil {
                selectedAssetId = nil
            }
        }
        .onChange(of: selectedAssetId) { _, newValue in
            if newValue != nil {
                selectedDocumentId = nil
            }
        }
    }
}
