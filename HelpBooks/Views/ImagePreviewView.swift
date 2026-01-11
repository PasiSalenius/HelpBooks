import SwiftUI

struct ImagePreviewView: View {
    let asset: AssetReference

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(asset.fileName)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            // Image preview
            GeometryReader { geometry in
                if let nsImage = NSImage(contentsOf: asset.originalPath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    ContentUnavailableView(
                        "Cannot Display Image",
                        systemImage: "photo.badge.exclamationmark",
                        description: Text("Unable to load the image file")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
        }
    }
}
