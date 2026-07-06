//
//  RequestEstimateView.swift
//  TaulbeePainting
//
//  The in-app estimate / help request form: name, contact, optional room,
//  project details, and photos. Sends a neatly formatted request to Taulbee
//  Painting via Mail (or the share sheet when photos are attached) and logs
//  the request in the activity timeline.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RequestEstimateView: View {
    /// Optional context appended to the request, e.g. "Regarding defect scan: Peeling".
    var contextLine: String? = nil
    /// Preselects a room chip when opened from a room or reminder.
    var prefilledRoomName: String? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PaintRoom.name) private var rooms: [PaintRoom]

    @AppStorage("estimateName") private var name = ""
    @AppStorage("estimateContact") private var contact = ""
    @State private var selectedRoomName: String
    @State private var details = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    @State private var showShare = false
    @State private var sent = false

    init(contextLine: String? = nil, prefilledRoomName: String? = nil) {
        self.contextLine = contextLine
        self.prefilledRoomName = prefilledRoomName
        _selectedRoomName = State(initialValue: prefilledRoomName ?? "")
    }

    private var canSend: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !contact.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if sent {
                        successCard
                    } else {
                        intro
                        if let contextLine {
                            contextChip(contextLine)
                        }
                        nameField
                        contactField
                        roomSection
                        detailsField
                        photosSection
                        sendButton
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(16)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Request Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(sent ? "Done" : "Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(items: shareItems)
            }
            .onChange(of: photoItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await loadPhotos(items) }
            }
        }
    }

    // MARK: Sections

    private var intro: some View {
        HStack(spacing: 13) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Theme.brandGradient, in: .rect(cornerRadius: 15))
                .shadow(color: Theme.brand.opacity(0.3), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text("Free, no-pressure pricing")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Tell us about your project — we usually reply within one business day.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .paintCard(padding: 14)
    }

    private func contextChip(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12.5, weight: .semibold))
                .lineLimit(2)
        }
        .foregroundStyle(Theme.brand)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.lavender, in: .rect(cornerRadius: 12))
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Your name")
            TextField("e.g. Jamie Carter", text: $name)
                .font(.system(size: 16))
                .textContentType(.name)
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var contactField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Email or phone")
            TextField("How should we reach you?", text: $contact)
                .font(.system(size: 16))
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    @ViewBuilder
    private var roomSection: some View {
        let names = roomChipNames
        if !names.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("Room or area (optional)")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(names, id: \.self) { roomName in
                            Button {
                                Haptics.tap()
                                selectedRoomName = selectedRoomName == roomName ? "" : roomName
                            } label: {
                                Text(roomName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(selectedRoomName == roomName ? .white : Theme.inkSecondary)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(
                                        selectedRoomName == roomName ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Theme.surface),
                                        in: .capsule
                                    )
                                    .overlay(Capsule().stroke(Theme.hairline, lineWidth: selectedRoomName == roomName ? 0 : 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .scrollClipDisabled()
            }
        }
    }

    private var roomChipNames: [String] {
        var names = rooms.map(\.name)
        if let prefilledRoomName, !prefilledRoomName.isEmpty, !names.contains(prefilledRoomName) {
            names.insert(prefilledRoomName, at: 0)
        }
        return names
    }

    private var detailsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Project details")
            TextField("What would you like painted or looked at?", text: $details, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(3...7)
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Photos (optional)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    PhotosPicker(selection: $photoItems, maxSelectionCount: 4, matching: .images) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                            Text("Add")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Theme.brand)
                        .frame(width: 76, height: 76)
                        .background(Theme.brand.opacity(0.10), in: .rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.brand.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                    }

                    ForEach(Array(photos.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Color(.secondarySystemBackground)
                                .frame(width: 76, height: 76)
                                .overlay {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .allowsHitTesting(false)
                                }
                                .clipShape(.rect(cornerRadius: 14))
                            Button {
                                Haptics.tap()
                                photos.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white, .black.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .padding(3)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    private var sendButton: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Send Request", systemImage: "paperplane.fill") {
                send()
            }
            .opacity(canSend ? 1 : 0.5)
            .disabled(!canSend)
            Text("Sent straight to the Taulbee Painting team at \(BusinessInfo.email).")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private var successCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.lavender)
                    .frame(width: 84, height: 84)
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Theme.brand)
            }
            VStack(spacing: 5) {
                Text("Request on its way")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Thanks, \(name.isEmpty ? "neighbor" : name)! The Taulbee Painting team usually replies within one business day.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 42)
                    .background(Theme.brandGradient, in: .capsule)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .paintCard()
        .padding(.top, 20)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .heavy))
            .tracking(1)
            .foregroundStyle(Theme.inkSecondary)
    }

    // MARK: Sending

    private var messageBody: String {
        var lines = ["New estimate request from the Taulbee Painting app", ""]
        lines.append("Name: \(name.trimmingCharacters(in: .whitespaces))")
        lines.append("Contact: \(contact.trimmingCharacters(in: .whitespaces))")
        if !selectedRoomName.isEmpty {
            lines.append("Room / area: \(selectedRoomName)")
        }
        if let contextLine {
            lines.append(contextLine)
        }
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDetails.isEmpty {
            lines.append("")
            lines.append("Project details:")
            lines.append(trimmedDetails)
        }
        return lines.joined(separator: "\n")
    }

    private var shareItems: [Any] {
        var items: [Any] = [messageBody]
        items.append(contentsOf: photos)
        return items
    }

    private var mailtoURL: URL? {
        let subject = "Estimate request — \(name.trimmingCharacters(in: .whitespaces))"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? messageBody
        return URL(string: "mailto:\(BusinessInfo.email)?subject=\(encodedSubject)&body=\(encodedBody)")
    }

    private func send() {
        guard canSend else { return }
        Haptics.success()
        logRequest()

        if photos.isEmpty, let url = mailtoURL {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    showShare = true
                }
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { sent = true }
        } else {
            showShare = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { sent = true }
        }
    }

    private func logRequest() {
        var detail = selectedRoomName
        if let contextLine, detail.isEmpty { detail = contextLine }
        ActivityEvent.log(
            .estimateRequested,
            title: selectedRoomName.isEmpty ? "Estimate requested" : "Estimate requested for \(selectedRoomName)",
            detail: detail,
            in: modelContext
        )
        try? modelContext.save()
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                photos.append(image)
            }
        }
        photoItems = []
    }
}
