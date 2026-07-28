import SwiftUI

struct GoldElevatedCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color("AppSurface"))
                    .shadow(color: ThemeColor.primary.opacity(0.35), radius: 10, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColor.primary.opacity(0.55), ThemeColor.accent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.light()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(isDestructive ? Color("AppTextPrimary") : Color(red: 0.12, green: 0.12, blue: 0.14))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: isDestructive
                        ? [Color.red.opacity(0.85), Color.red.opacity(0.65)]
                        : [ThemeColor.primary, ThemeColor.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: (isDestructive ? Color.red : ThemeColor.primary).opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ThemeColor.primary, ThemeColor.accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: ThemeColor.primary.opacity(0.5), radius: 12)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

struct ProgressRingView: View {
    let progress: Double
    let label: String
    let detail: String
    var size: CGFloat = 86

    var body: some View {
        VStack(spacing: 8) {
            Canvas { context, canvasSize in
                let lineWidth: CGFloat = 8
                let rect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: lineWidth, dy: lineWidth)
                var track = Path()
                track.addEllipse(in: rect)
                context.stroke(track, with: .color(Color("AppBackground").opacity(0.6)), lineWidth: lineWidth)

                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
                    radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * min(max(progress, 0), 1)),
                    clockwise: false
                )
                context.stroke(
                    arc,
                    with: .linearGradient(
                        Gradient(colors: [ThemeColor.primary, ThemeColor.accent]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                    ),
                    lineWidth: lineWidth
                )
            }
            .frame(width: size, height: size)
            .overlay {
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color("AppTextPrimary"))
            }

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("AppTextPrimary"))
                .lineLimit(1)
            Text(detail)
                .font(.caption2)
                .foregroundColor(Color("AppTextSecondary"))
        }
        .frame(width: size + 24)
    }
}

struct ActivityBarChart: View {
    let items: [(label: String, value: Int)]

    private var maxValue: Int {
        max(items.map(\.value).max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 6) {
                    Text(item.value > 0 ? "\(item.value)" : "")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color("AppTextSecondary"))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [ThemeColor.primary, ThemeColor.accent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: max(8, CGFloat(item.value) / CGFloat(maxValue) * 110))
                        .shadow(color: ThemeColor.primary.opacity(0.35), radius: 4, y: 2)
                    Text(item.label)
                        .font(.caption2)
                        .foregroundColor(Color("AppTextSecondary"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160, alignment: .bottom)
    }
}

struct LineChartView: View {
    let items: [(label: String, value: Int)]
    var unitSuffix: String = ""

    private var maxValue: CGFloat {
        CGFloat(max(items.map(\.value).max() ?? 100, 1))
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let count = max(items.count - 1, 1)

                ZStack {
                    Path { path in
                        for i in 0..<4 {
                            let y = height * CGFloat(i) / 3
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color("AppTextSecondary").opacity(0.15), lineWidth: 1)

                    Path { path in
                        for (index, item) in items.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(count)
                            let y = height - (CGFloat(item.value) / maxValue) * (height - 8)
                            let point = CGPoint(x: x, y: y)
                            if index == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColor.primary, ThemeColor.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        let x = width * CGFloat(index) / CGFloat(count)
                        let y = height - (CGFloat(item.value) / maxValue) * (height - 8)
                        Circle()
                            .fill(ThemeColor.primary)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                            .shadow(color: ThemeColor.primary.opacity(0.45), radius: 3)
                    }
                }
            }
            .frame(height: 120)

            HStack {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 2) {
                        Text("\(item.value)\(unitSuffix)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Color("AppTextPrimary"))
                        Text(item.label)
                            .font(.caption2)
                            .foregroundColor(Color("AppTextSecondary"))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct StatusDistributionChart: View {
    let items: [(label: String, value: Int, color: String)]

    private var total: Int {
        max(items.map(\.value).reduce(0, +), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { geo in
                HStack(spacing: 3) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        if item.value > 0 {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(resolvedColor(item.color))
                                .frame(width: max(8, geo.size.width * CGFloat(item.value) / CGFloat(total)))
                        }
                    }
                }
            }
            .frame(height: 16)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack {
                    Circle()
                        .fill(resolvedColor(item.color))
                        .frame(width: 8, height: 8)
                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                    Spacer()
                    Text("\(item.value)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("AppTextPrimary"))
                    Text("\(Int((Double(item.value) / Double(total)) * 100))%")
                        .font(.caption2)
                        .foregroundColor(Color("AppTextSecondary"))
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    private func resolvedColor(_ name: String) -> Color {
        switch name {
        case "AppPrimary": return ThemeColor.primary
        case "AppAccent": return ThemeColor.accent
        default: return Color("AppTextSecondary")
        }
    }
}
