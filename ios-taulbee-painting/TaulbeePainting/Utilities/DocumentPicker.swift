//
//  DocumentPicker.swift
//  TaulbeePainting
//
//  Thin UIKit wrapper around UIDocumentPickerViewController for importing
//  documents (PDFs, etc.) into the Vault. Returns the file's data, name and
//  extension.
//

import SwiftUI
import UniformTypeIdentifiers

struct PickedDocument {
    let data: Data
    let filename: String
    let fileExtension: String
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (PickedDocument) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .plainText, .rtf, .spreadsheet, .presentation, .item]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        init(_ parent: DocumentPicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            defer { parent.dismiss() }
            guard let url = urls.first else { return }
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { return }
            let ext = url.pathExtension.lowercased()
            parent.onPick(PickedDocument(data: data, filename: url.lastPathComponent, fileExtension: ext))
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
