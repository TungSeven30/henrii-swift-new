import SwiftUI

struct TimerCardView: View {
    @Bindable var timerVM: TimerViewModel
    let onStop: ((category: EventCategory, duration: Double, side: FeedingType)?) -> Void

    @Environment(\.henriiReduceMotion) private var reduceMotion
    @State private var slideOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    private let slideThreshold: CGFloat = 120

    var body: some View {
        VStack(spacing: HenriiSpacing.md) {
            HStack {
                Image(systemName: timerVM.timerCategory == .sleep ? "moon.fill" : "cup.and.saucer.fill")
                    .font(.headline)
                    .foregroundStyle(timerVM.timerCategory == .sleep ? HenriiColors.dataSleep : HenriiColors.dataFeeding)

                Text(timerVM.timerCategory == .sleep ? "Sleep Timer" : "Feed Timer")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)

                Spacer()

                if timerVM.timerCategory == .feeding {
                    Button { timerVM.toggleSide() } label: {
                        Text(timerVM.feedingSide == .breastLeft ? "L" : "R")
                            .font(.henriiHeadline)
                            .foregroundStyle(HenriiColors.accentPrimary)
                            .frame(width: 44, height: 44)
                            .background(HenriiColors.accentPrimary.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }

            Text(timerVM.formattedTime)
                .font(.henriiData(size: 48))
                .foregroundStyle(HenriiColors.textPrimary)
                .scaleEffect(reduceMotion ? 1.0 : pulseScale)
                .animation(
                    reduceMotion || timerVM.isPaused ? .default : .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .onAppear {
                    if !reduceMotion { pulseScale = 1.02 }
                }
                .contentTransition(.numericText())

            HStack(spacing: HenriiSpacing.lg) {
                Button {
                    if timerVM.isPaused {
                        timerVM.resumeTimer()
                    } else {
                        timerVM.pauseTimer()
                    }
                } label: {
                    Image(systemName: timerVM.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundStyle(HenriiColors.textPrimary)
                        .frame(width: 56, height: 44)
                        .background(HenriiColors.canvasElevated)
                        .clipShape(Capsule())
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: timerVM.isPaused)

                slideToStopButton
            }
        }
        .padding(HenriiSpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: HenriiRadius.large))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    private var slideToStopButton: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(HenriiColors.accentPrimary.opacity(0.15))

                Capsule()
                    .fill(HenriiColors.accentPrimary.opacity(0.3))
                    .frame(width: max(56, slideOffset + 56))

                HStack {
                    Circle()
                        .fill(HenriiColors.accentPrimary)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "stop.fill")
                                .font(.callout)
                                .foregroundStyle(.white)
                        }
                        .offset(x: slideOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    slideOffset = max(0, min(value.translation.width, geo.size.width - 56))
                                }
                                .onEnded { value in
                                    if slideOffset > slideThreshold {
                                        let result = timerVM.stopTimer()
                                        onStop(result)
                                    }
                                    withAnimation(.spring(duration: 0.3)) {
                                        slideOffset = 0
                                    }
                                }
                        )
                        .padding(.leading, 4)

                    if slideOffset < 40 {
                        Text("Slide to stop")
                            .font(.henriiCallout)
                            .foregroundStyle(HenriiColors.textSecondary)
                            .transition(.opacity)
                    }

                    Spacer()
                }
            }
        }
        .frame(height: 52)
        .sensoryFeedback(.impact(weight: .heavy), trigger: slideOffset > slideThreshold)
    }
}
