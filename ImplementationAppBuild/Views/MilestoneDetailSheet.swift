import SwiftUI
import PhotosUI

struct MilestoneDetailSheet: View {
    let event: BabyEvent
    @Environment(\.dismiss) private var dismiss
    @State private var context: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HenriiSpacing.xl) {
                    milestoneHeader

                    photoSection

                    contextSection
                }
                .padding(.horizontal, HenriiSpacing.margin)
                .padding(.top, HenriiSpacing.lg)
                .padding(.bottom, 40)
            }
            .background(HenriiColors.canvasPrimary)
            .navigationTitle("Milestone Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                context = event.milestoneContext ?? ""
                selectedImageData = event.milestonePhotoData
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }

    private var milestoneHeader: some View {
        VStack(spacing: HenriiSpacing.md) {
            Circle()
                .fill(HenriiColors.dataGrowth.opacity(0.12))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(HenriiColors.dataGrowth)
                }

            Text(event.milestoneDescription ?? event.notes ?? "Milestone")
                .font(.henriiTitle2)
                .foregroundStyle(HenriiColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(event.timestamp, format: .dateTime.month(.wide).day().year().hour().minute())
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HenriiSpacing.md)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Photo")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Color(.secondarySystemBackground)
                        .frame(height: 240)
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: HenriiRadius.large))

                    Button {
                        selectedImageData = nil
                        selectedItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(HenriiSpacing.sm)
                }
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: HenriiSpacing.sm) {
                    Image(systemName: selectedImageData != nil ? "photo.badge.arrow.down" : "photo.badge.plus")
                        .font(.callout)
                    Text(selectedImageData != nil ? "Change Photo" : "Add a Photo")
                        .font(.henriiCallout)
                }
                .foregroundStyle(HenriiColors.accentPrimary)
                .padding(.horizontal, HenriiSpacing.lg)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(HenriiColors.accentPrimary.opacity(0.1))
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            }
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Context")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            TextField("What was happening? How did it feel?", text: $context, axis: .vertical)
                .font(.henriiBody)
                .lineLimit(3...8)
                .padding(HenriiSpacing.lg)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        }
    }

    private func save() {
        event.milestonePhotoData = selectedImageData
        event.milestoneContext = context.isEmpty ? nil : context
        dismiss()
    }
}
