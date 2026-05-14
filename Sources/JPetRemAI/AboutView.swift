// AboutView.swift — 关于页面

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .padding(.top, 24)

            Text("JPetRemAI")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("版本 6.0.0 · macOS 26 Native")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)

            Text("AI 桌面宠物 · 本地 LLM 推理 · SwiftUI 原生体验")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()
        }
        .frame(width: 300, height: 250)
    }
}