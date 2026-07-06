//
//  ScannerHomeView.swift
//  TaulbeePainting
//
//  The dedicated Paint Defect Scanner: a purple hero CTA that opens the
//  camera/photo flow, recent scans, and a tips card. Pushed from the
//  Home/Dashboard inside the Scan tab's navigation stack.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ScannerHomeView: View {
    @Query(sort: \PaintScan.createdAt, order: .reverse) private var scans: [PaintScan]

    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showSourceDialog = false
    @State private var cameraUnavailable = false
    @State private var pendingImage: UIImage?
    @State private var loadingLibrary = false

    private var recentScans: [PaintScan] { Array(scans.prefix(5)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                hero
                if scans.isEmpty {
                    emptyHint
                } else {
                    recentSection
                }
                tipsCard
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Add a photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            Button("Take Photo") {
                if CameraPicker.isAvailable { showCamera = true } else { cameraUnavailable = true }
            }
            Button("Choose from Library") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in pendingImage = image }
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $pendingImage) { image in
            ScanFlowView(image: image)
        }
        .alert("Camera unavailable", isPresented: $cameraUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Install this app on your device via the Rork App to use the camera. You can still choose a photo from your library.")
        }
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            loadingLibrary = true
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pendingImage = image
                }
                photoItem = nil
                loadingLibrary = false
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Paint Defect Scanner")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Snap a problem area. Get causes, fixes, and next steps.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 18) {
            Image(systemName: "viewfinder")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(.white.opacity(0.16), in: .rect(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.25), lineWidth: 1))

            VStack(spacing: 8) {
                Text("Scan for Paint Defects")
                    .font(.system(size: 23, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Upload a photo of peeling, cracking, mildew, staining, or other paint issues.")
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Haptics.tap()
                showSourceDialog = true
            } label: {
                HStack(spacing: 10) {
                    if loadingLibrary {
                        ProgressView().tint(Theme.brand)
                    } else {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text("Scan a Defect")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(Theme.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white, in: .rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background { HeroBackground() }
        .clipShape(.rect(cornerRadius: Theme.heroRadius))
        .shadow(color: Theme.brand.opacity(0.30), radius: 22, y: 14)
    }

    private var emptyHint: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Theme.brand.opacity(0.6))
            Text("Your scans will appear here")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Tap “Scan a Defect” to analyze peeling, cracking, mildew, efflorescence and more.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .paintCard()
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(icon: "clock.arrow.circlepath", title: "Recent Scans")
            VStack(spacing: 12) {
                ForEach(recentScans) { scan in
                    NavigationLink(value: scan) {
                        ScanRow(scan: scan)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var tipsCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.accent.opacity(0.12), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tips for Best Results")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Use good lighting, fill the frame, and include the edges of the affected area.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .paintCard()
    }
}

// MARK: - Shared scan row

struct ScanRow: View {
    let scan: PaintScan

    var body: some View {
        HStack(spacing: 14) {
            Color(.secondarySystemBackground)
                .frame(width: 60, height: 60)
                .overlay {
                    if let image = UIImage(data: scan.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(.rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(scan.defectName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(scan.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Text(scan.severity.label)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(scan.severity.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(scan.severity.color.opacity(0.14), in: .capsule)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.5))
        }
        .padding(12)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

extension UIImage: @retroactive Identifiable {
    public var id: String { String(UInt(bitPattern: ObjectIdentifier(self).hashValue)) }
}
