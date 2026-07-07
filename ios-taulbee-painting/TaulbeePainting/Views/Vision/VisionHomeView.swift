//
//  VisionHomeView.swift
//  TaulbeePainting
//
//  Entry point for the color visualizer: start a new visualization or revisit
//  saved projects.
//

import SwiftUI
import SwiftData
import PhotosUI

struct VisionHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisionProject.createdAt, order: .reverse) private var projects: [VisionProject]

    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showSourceDialog = false
    @State private var cameraUnavailable = false
    @State private var pendingImage: UIImage?
    @State private var loadingLibrary = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    hero
                    if projects.isEmpty {
                        emptyHint
                    } else {
                        projectsSection
                    }
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: VisionProject.self) { project in
                SavedProjectView(project: project)
            }
            .navigationDestination(item: $pendingImage) { image in
                VisualizeView(image: image)
            }
        }
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

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Vision Tool")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Text("See your space in a new color before you commit.")
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var hero: some View {
        VStack(spacing: 18) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(.white.opacity(0.16), in: .rect(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.25), lineWidth: 1))

            VStack(spacing: 8) {
                Text("Preview Your Home\nin a New Color")
                    .font(.system(size: 23, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Upload a photo, then tap through 7,700+ real Sherwin-Williams, Benjamin Moore & PPG colors — your walls repaint instantly.")
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
                        Image(systemName: "photo.badge.plus.fill")
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text("New Visualization")
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
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.brand.opacity(0.6))
            Text("Your projects will appear here")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Visualize a space, then save it and send it to us for a quote.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .paintCard()
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(icon: "square.grid.2x2.fill", title: "Recent Visualizations")
            VStack(spacing: 12) {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        ProjectRow(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Project row

struct ProjectRow: View {
    let project: VisionProject

    var body: some View {
        HStack(spacing: 14) {
            Color(.secondarySystemBackground)
                .frame(width: 64, height: 64)
                .overlay {
                    if let image = UIImage(data: project.resultImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(.rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(project.surfaceLabel.isEmpty ? project.colorName : project.surfaceLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(project.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: project.colorHex.isEmpty ? "CCCCCC" : project.colorHex))
                    .frame(width: 24, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.hairline, lineWidth: 1))
            }
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

// MARK: - Project card

struct ProjectCard: View {
    let project: VisionProject

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color(.secondarySystemBackground)
                .frame(height: 120)
                .overlay {
                    if let image = UIImage(data: project.resultImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                }
                .clipped()
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: project.colorHex.isEmpty ? "CCCCCC" : project.colorHex))
                    .frame(width: 22, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.hairline, lineWidth: 1))
                VStack(alignment: .leading, spacing: 1) {
                    Text(project.colorName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(project.surfaceLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Theme.surface)
        }
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Decorative dots

struct ColorDots: View {
    private let palette: [Color] = [
        Color(hex: "E29A3B"), Color(hex: "CDD5CA"), Color(hex: "2F3A4A"), Color(hex: "AD6A4E")
    ]

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Circle().fill(palette[0].opacity(0.25)).frame(width: 150).offset(x: 130, y: -70)
                Circle().fill(palette[2].opacity(0.30)).frame(width: 90).offset(x: 150, y: 70)
                Circle().fill(palette[1].opacity(0.22)).frame(width: 60).offset(x: 100, y: 30)
            }
        }
    }
}
