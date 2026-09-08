import SwiftUI
import AppKit

private let ink = Color.primary
private let muted = Color.secondary

struct VistaView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme
    private var surface: Color { scheme == .dark ? Color(white: 0.09) : Color(white: 0.98) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if model.expanded {
                card
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topTrailing)))
            } else {
                FocusOrb(progress: model.progress, paused: model.clock.phase == .paused, small: true)
                    .frame(width: 44, height: 44)
                    .overlay {
                        DragHandle(
                            label: "Vista. Next break in \(model.timeLabel). Click to open, drag to move.",
                            onClick: { model.setExpanded(true) },
                            onMove: { model.onMove?() }
                        )
                    }
                .padding(2)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.settings)
        .onChange(of: model.settings) { _, _ in model.onResize?() }
    }
    private var card: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Vista").font(.system(size: 13, weight: .semibold))
                Spacer()
                if model.settings {
                    iconButton("arrow.left", "Back") { model.settings = false }
                } else {
                    iconButton("slider.horizontal.3", "Settings") { model.settings = true }
                }
                iconButton("minus", "Minimize Vista") { model.setExpanded(false) }
            }
            .foregroundStyle(ink)
            .padding(.bottom, 16)
            if model.settings { settingsContent } else { mainContent }
        }
        .padding(22)
        .frame(width: 332, height: model.settings ? 250 : 338, alignment: .top)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(surface.opacity(0.97))
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(ink.opacity(scheme == .dark ? 0.14 : 0.10), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    private var mainContent: some View {
        VStack(spacing: 0) {
            ZStack {
                FocusOrb(progress: model.progress, paused: model.clock.phase == .paused, small: false)
                    .frame(width: 64, height: 64)
                if model.clock.phase == .completed {
                    Image(systemName: "checkmark").font(.system(size: 23, weight: .light)).foregroundStyle(ink)
                        .frame(width: 44, height: 44).background(surface, in: Circle())
                }
            }
            .padding(.bottom, 15)
            Text(eyebrow).font(.system(size: 11, weight: .medium)).monospacedDigit().foregroundStyle(muted)
                .padding(.bottom, 9)
            Text(title).font(.system(size: 25, weight: .medium)).foregroundStyle(ink)
                .padding(.bottom, 8)
            Text(subtitle).font(.system(size: 12.5)).lineSpacing(4).multilineTextAlignment(.center)
                .foregroundStyle(muted).frame(height: 38)
            Spacer(minLength: 14)
            actions

        }
    }
    private var eyebrow: String {
        switch model.clock.phase {
        case .focus: return "Next break in \(model.timeLabel)"
        case .due: return "Time for a break"
        case .resting: return "Look away · \(model.remaining)s"
        case .completed: return "Break complete"
        case .paused: return "Resumes in \(model.timeLabel)"
        }
    }
    private var title: String {
        switch model.clock.phase {
        case .focus: return "Stay focused."
        case .due: return "Look into the distance."
        case .resting: return "Rest your eyes."
        case .completed: return "Welcome back."
        case .paused: return "On pause."
        }
    }
    private var subtitle: String {
        switch model.clock.phase {
        case .focus: return "A 20-second break every \(Int(model.clock.interval / 60)) minutes."
        case .due: return "Look about 20 feet (6 m) away for 20 seconds.\nBlink naturally."
        case .resting: return model.soundEnabled ? "Keep looking away. Blink naturally.\nYou’ll hear a chime when it’s time." : "Keep looking away. Blink naturally.\nCount slowly to 20; sound is off."
        case .completed: return "Your next break is in \(Int(model.clock.interval / 60)) minutes."
        case .paused: return "Reminders will resume automatically."
        }
    }
    @ViewBuilder private var actions: some View {
        switch model.clock.phase {
        case .resting:
            VStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ink.opacity(0.08))
                        Capsule().fill(ink).frame(width: max(4, geo.size.width * model.progress))
                    }
                }.frame(height: 3)
                Button("End break early") { model.resume() }.buttonStyle(QuietButton())
            }.frame(height: 69)
        case .completed:
            Button { model.resume() } label: { Label("Done", systemImage: "arrow.up.right") }
                .buttonStyle(PrimaryButton()).frame(height: 69)
        case .paused:
            Button("Resume reminders") { model.resume() }.buttonStyle(PrimaryButton()).frame(height: 69)
        case .due, .focus:
            VStack(spacing: 8) {
                Button { model.start() } label: {
                    HStack {
                        Text(model.clock.phase == .due ? "Start 20-second break" : "Take a break now")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }.buttonStyle(PrimaryButton())
                if model.clock.phase == .due {
                    Button("In 5 minutes") { model.snooze() }.buttonStyle(QuietButton())
                } else {
                    Button("Pause for an hour") { model.pause() }.buttonStyle(QuietButton())
                }
            }.frame(height: 69)
        }
    }
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings").font(.system(size: 23, weight: .medium)).foregroundStyle(ink)
            HStack {
                Text("Remind me every").font(.system(size: 12)).foregroundStyle(muted)
                Spacer()
                Picker("Reminder interval", selection: Binding(get: { Int(model.clock.interval / 60) }, set: { model.setInterval($0) })) {
                    Text("20 min").tag(20)
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                }.labelsHidden().frame(width: 105)
            }
            Toggle("Soft chime after a break", isOn: $model.soundEnabled)
            Toggle("Open at login", isOn: Binding(get: { model.loginEnabled }, set: { model.setLogin($0) }))
            if let error = model.launchError {
                Text(error).font(.system(size: 10)).foregroundStyle(ink)
            }
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button("Quit Vista") { NSApp.terminate(nil) }.buttonStyle(QuietButton())
            }.foregroundStyle(muted)
        }
        .font(.system(size: 12))
        .toggleStyle(.switch).controlSize(.mini).tint(ink)
    }
    private func iconButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 12, weight: .medium))
                .foregroundStyle(muted).frame(width: 24, height: 24)
                .background(ink.opacity(0.055), in: Circle())
        }.buttonStyle(.plain).help(label).accessibilityLabel(label)
    }
}

private struct FocusOrb: View {
    var progress: Double
    var paused: Bool
    var small: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width
            ZStack {
                if small {
                    Circle().fill(scheme == .dark ? Color(white: 0.10) : Color(white: 0.98))
                    Circle().stroke(ink.opacity(0.12), lineWidth: 1).padding(0.5)
                }
                Circle().stroke(ink.opacity(0.09), lineWidth: 1).padding(small ? 7 : 3)
                Circle().trim(from: 0, to: max(0.025, progress))
                    .stroke(ink.opacity(paused ? 0.2 : 0.65), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .rotationEffect(.degrees(-90)).padding(small ? 7 : 3)
                if paused {
                    Image(systemName: "pause.fill").font(.system(size: small ? 9 : 13)).foregroundStyle(muted)
                } else {
                    Circle().fill(ink.opacity(0.05)).frame(width: size * 0.53, height: size * 0.53)
                        .scaleEffect(breathe ? 1.1 : 0.82)
                    Circle().fill(ink.opacity(breathe ? 0.8 : 0.5))
                        .frame(width: size * 0.16, height: size * 0.16)
                        .scaleEffect(breathe ? 1.1 : 0.9)
                }
            }
        }
        .onAppear { updateMotion() }
        .onChange(of: reduceMotion) { _, _ in updateMotion() }
        .accessibilityHidden(true)
    }
    private func updateMotion() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            breathe = !reduceMotion
        }
    }
}
private struct PrimaryButton: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold))
            .foregroundStyle(scheme == .dark ? Color.black : Color.white)
            .padding(.horizontal, 16).frame(maxWidth: .infinity).frame(height: 40)
            .background((scheme == .dark ? Color.white : Color.black).opacity(configuration.isPressed ? 0.7 : 0.93), in: RoundedRectangle(cornerRadius: 12))
    }
}
private struct QuietButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 10.5)).foregroundStyle(muted.opacity(configuration.isPressed ? 0.5 : 1))
            .padding(.vertical, 3).contentShape(Rectangle())
    }
}
