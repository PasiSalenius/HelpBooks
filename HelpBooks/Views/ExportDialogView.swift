import SwiftUI

struct ExportDialogView: View {
    let project: HelpProject
    @State private var viewModel: ExportViewModel
    @Environment(\.dismiss) private var dismiss

    init(project: HelpProject) {
        self.project = project
        _viewModel = State(initialValue: ExportViewModel(project: project))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Export Help Book")
                .font(.title)

            // Destination
            HStack {
                TextField("Output Location", text: $viewModel.outputPath)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)

                Button("Choose") {
                    viewModel.chooseOutputLocation()
                }
                .disabled(viewModel.isExporting)
            }

            // Progress
            if viewModel.isExporting {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.progress) {
                        Text(viewModel.currentPhase.description)
                    }

                    if !viewModel.currentTask.isEmpty {
                        Text(viewModel.currentTask)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }

            // Status
            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            if viewModel.isComplete {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Export complete!")
                            .font(.headline)

                        Text("Your Help Book is ready to use.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        viewModel.revealInFinder()
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next steps:")
                        .font(.headline)

                    Text("1. Add the .help bundle to your Xcode project's Resources")
                        .font(.body)

                    Text("2. Add these keys to your app's Info.plist:")
                        .font(.body)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CFBundleHelpBookFolder")
                                .font(.system(.caption, design: .monospaced))
                            Text("CFBundleHelpBookName")
                                .font(.system(.caption, design: .monospaced))
                        }
                        .foregroundColor(.secondary)

                        Spacer()

                        Button {
                            copyPlistKeys()
                        } label: {
                            Label("Copy Keys", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)

                    Text("3. Build and run your app - Help will appear in the Help menu")
                        .font(.body)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            Spacer()

            // Actions
            HStack {
                Button("Close") {
                    dismiss()
                }
                .disabled(viewModel.isExporting)

                Spacer()

                if !viewModel.isComplete {
                    Button("Export") {
                        Task {
                            await viewModel.export()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isExporting || viewModel.outputPath.isEmpty)
                }
            }
        }
        .padding(24)
        .frame(width: 600, height: viewModel.isComplete ? 600 : 350)
    }

    private func copyPlistKeys() {
        let bundleName = project.metadata.bundleName
        let bundleId = project.metadata.bundleIdentifier

        let plistKeys = """
        <key>CFBundleHelpBookFolder</key>
        <string>\(bundleName).help</string>
        <key>CFBundleHelpBookName</key>
        <string>\(bundleId)</string>
        """

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(plistKeys, forType: .string)
    }
}
