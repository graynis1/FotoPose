import SwiftUI
import AVFoundation
import CoreLocation

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let photoURL: String
    let eyebrow: String
    let headline: String
    let sub: String
    let focalY: UnitPoint
}

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var index: Int = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            photoURL: "https://images.unsplash.com/photo-1524638431109-93d95c968f03?w=900&q=85&auto=format&fit=crop",
            eyebrow: "01 · Point",
            headline: "Any scene.\nInstant pose ideas.",
            sub: "Open the camera. Our on-device AI reads the light, location, and framing — and serves pose ideas that actually fit.",
            focalY: UnitPoint(x: 0.5, y: 0.3)
        ),
        OnboardingSlide(
            photoURL: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=900&q=85&auto=format&fit=crop",
            eyebrow: "02 · Follow",
            headline: "A live guide,\ndrawn on you.",
            sub: "Real-time body tracking overlays the target pose on screen. Match it, and we capture automatically.",
            focalY: UnitPoint(x: 0.5, y: 0.3)
        ),
        OnboardingSlide(
            photoURL: "https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=900&q=85&auto=format&fit=crop",
            eyebrow: "03 · Capture",
            headline: "Shots worth\nposting. Every time.",
            sub: "Built by portrait photographers. 200+ poses, coaching that adapts to your body, and zero cloud uploads — ever.",
            focalY: UnitPoint(x: 0.5, y: 0.25)
        )
    ]

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(slides.enumerated()), id: \.offset) { i, slide in
                    OnboardingSlideView(slide: slide, index: i, total: slides.count) {
                        handleCTA()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Skip
            VStack {
                HStack {
                    Spacer()
                    Button {
                        appState.skipOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .glass(tint: Color.black.opacity(0.25), borderOpacity: 0.15)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                Spacer()
            }
        }
        .statusBarHidden(false)
    }

    private func handleCTA() {
        if index < slides.count - 1 {
            withAnimation(.easeInOut) { index += 1 }
            if index == 1 {
                requestCameraPermission()
            }
        } else {
            requestLocationPermission()
            requestNotificationPermission()
            appState.completeOnboarding()
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }

    private func requestLocationPermission() {
        LocationPermissionRequester.shared.request()
    }

    private func requestNotificationPermission() {
        Task {
            await NotificationService.shared.requestAuthorizationIfNeeded()
            await NotificationService.shared.scheduleGoldenHourAlerts()
            await NotificationService.shared.scheduleWeeklyReminder()
        }
    }
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let index: Int
    let total: Int
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RemoteImage(url: slide.photoURL, focalPoint: slide.focalY)
                    .ignoresSafeArea()

                // Top gradient for status bar readability
                LinearGradient(
                    colors: [Color.black.opacity(0.5), Color.clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 160)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Bottom gradient
                LinearGradient(
                    stops: [
                        .init(color: DS.Colors.background.opacity(0), location: 0),
                        .init(color: DS.Colors.background.opacity(0.75), location: 0.4),
                        .init(color: DS.Colors.background.opacity(0.98), location: 1.0)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 500)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    Text(LocalizedStringKey(slide.eyebrow))
                        .font(DS.Font.mono(11))
                        .tracking(2.2)
                        .foregroundStyle(DS.Gradients.accent)
                        .textCase(.uppercase)
                        .padding(.bottom, 14)

                    Text(LocalizedStringKey(slide.headline))
                        .font(.system(size: 36, weight: .bold))
                        .tracking(-1.2)
                        .foregroundStyle(.white)
                        .lineSpacing(-4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(LocalizedStringKey(slide.sub))
                        .font(.system(size: 15.5, weight: .regular))
                        .tracking(-0.2)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineSpacing(2)
                        .padding(.top, 14)
                        .frame(maxWidth: 320, alignment: .leading)

                    HStack(alignment: .center) {
                        PageDots(current: index, total: total)
                        Spacer()
                        Button(action: onContinue) {
                            HStack(spacing: 10) {
                                Text(index == total - 1 ? LocalizedStringKey("Get Started") : LocalizedStringKey("Continue"))
                                    .font(.system(size: 15.5, weight: .bold))
                                    .tracking(-0.2)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .frame(height: 52)
                            .background(DS.Gradients.accent, in: Capsule())
                            .shadow(color: DS.Colors.pink.opacity(0.45), radius: 16, x: 0, y: 10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 36)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
                .frame(width: proxy.size.width, alignment: .leading)
            }
        }
    }
}

private struct PageDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.white : Color.white.opacity(0.35))
                    .frame(width: i == current ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}

// Simple, bundled-or-remote image with focal positioning.
struct RemoteImage: View {
    let url: String
    var focalPoint: UnitPoint = .center
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            case .failure:
                DS.Colors.background
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.2))
                    )
            default:
                DS.Colors.background
                    .overlay(
                        ProgressView()
                            .tint(.white.opacity(0.5))
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Location permission one-shot
final class LocationPermissionRequester: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionRequester()
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
