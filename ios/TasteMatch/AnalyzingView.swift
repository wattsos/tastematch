import SwiftUI

struct AnalyzingView: View {
    @State private var rotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var pulse: Bool = false
    @State private var textIndex: Int = 0

    private let phrases = [
        "Reading your vibe...",
        "Studying the palette...",
        "Detecting textures...",
        "Mapping your taste...",
        "Finding your style...",
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                // Outer ring
                Circle()
                    .stroke(Theme.blush.opacity(0.3), lineWidth: 3)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.65)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotation))

                // Inner ring
                Circle()
                    .stroke(Theme.blush.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(Theme.sage, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(innerRotation))

                // Center icon
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                    .scaleEffect(pulse ? 1.15 : 0.9)
            }

            VStack(spacing: 8) {
                Text(phrases[textIndex])
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Theme.espresso)
                    .animation(.easeInOut(duration: 0.3), value: textIndex)

                Text("This only takes a moment")
                    .font(.caption)
                    .foregroundStyle(Theme.clay)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever()) {
                pulse = true
            }
            // Rotate through phrases
            Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { timer in
                withAnimation {
                    textIndex = (textIndex + 1) % phrases.count
                }
            }
        }
    }
}
