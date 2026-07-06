//
//  DocumentPreview.swift
//  TaulbeePainting
//
//  QuickLook-based preview for document attachments (PDFs, etc.). Writes the
//  attachment data to a temporary file and presents it.
//

import SwiftUI
import QuickLook

struct DocumentPreview: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(data: data, filename: filename) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL?

        init(data: Data, filename: String) {
            let safeName = filename.isEmpty ? "document" : filename
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
            try? data.write(to: tmp)
            self.url = tmp
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            url == nil ? 0 : 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            (url ?? URL(fileURLWithPath: "")) as QLPreviewItem
        }
    }
}
