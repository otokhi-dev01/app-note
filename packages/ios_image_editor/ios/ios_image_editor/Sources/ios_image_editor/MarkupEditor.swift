import QuickLook
import SwiftUI

struct MarkupEditor: UIViewControllerRepresentable {
    @Binding var image: UIImage
    var originalPath: String

    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator
        preview.delegate = context.coordinator

        objc_setAssociatedObject(
            preview,
            "coordinator",
            context.coordinator,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        let navigationController = UINavigationController(rootViewController: preview)
        navigationController.setNavigationBarHidden(true, animated: false)
        return navigationController
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        var parent: MarkupEditor
        var fileURL: URL

        init(_ parent: MarkupEditor) {
            self.parent = parent
            fileURL = URL(fileURLWithPath: parent.originalPath)
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            fileURL as NSURL
        }

        func previewController(
            _ controller: QLPreviewController,
            editingModeFor previewItem: QLPreviewItem
        ) -> QLPreviewItemEditingMode {
            .createCopy
        }

        func previewController(
            _ controller: QLPreviewController,
            didSaveEditedCopyOf previewItem: QLPreviewItem,
            at modifiedContentsURL: URL
        ) {
            do {
                _ = try FileManager.default.replaceItemAt(
                    fileURL,
                    withItemAt: modifiedContentsURL
                )

                if let updatedImage = UIImage(contentsOfFile: fileURL.path) {
                    DispatchQueue.main.async {
                        self.parent.image = updatedImage
                    }
                }
            } catch {
                assertionFailure("Could not save edited image: \(error)")
            }
        }
    }
}
