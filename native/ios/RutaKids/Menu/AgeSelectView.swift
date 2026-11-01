import SwiftUI

// MARK: - Selección de edad (primera vez que se abre la app)
// Dos dibujos grandes, un toque. Los íconos son provisionales (SF Symbols): cuando
// haya arte, se agregan "age_peque" y "age_grande" a "ASSETS de menu de IOS" y se usan solos.

struct AgeSelectView: View {
    let onSelect: (String) -> Void

    var body: some View {
        ZStack {
            MenuBackground()

            VStack(spacing: 24) {
                Text(L("MENU_EDAD_TITULO"))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)

                HStack(spacing: 28) {
                    AgeCard(
                        title: L("MENU_PEQUE"),
                        ages: L("MENU_PEQUE_EDADES"),
                        asset: "age_peque",
                        symbol: "face.smiling"
                    ) { onSelect(ProgressStore.modePeque) }

                    AgeCard(
                        title: L("MENU_GRANDE"),
                        ages: L("MENU_GRANDE_EDADES"),
                        asset: "age_grande",
                        symbol: "gamecontroller.fill"
                    ) { onSelect(ProgressStore.modeGrande) }
                }
            }
            .padding(24)
        }
        .statusBar(hidden: true)
    }
}

private struct AgeCard: View {
    let title: String
    let ages: String
    let asset: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button {
            AudioManager.shared.playSound(named: "tap")
            action()
        } label: {
            VStack(spacing: 10) {
                if UIImage(named: asset) != nil {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 76, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .frame(height: 110)
                }
                Text(title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(ages)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(minWidth: 200, maxWidth: 260, minHeight: 200)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [Theme.cardTop, Theme.cardBottom],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Theme.border, lineWidth: 4))
            )
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(title), \(ages)")
    }
}
