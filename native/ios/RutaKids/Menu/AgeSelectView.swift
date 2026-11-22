import SwiftUI

// MARK: - Selección de edad (primera vez que se abre la app)
// Dos tarjetas grandes, un toque. Cada una es la ilustración del lote 10 ("age_peque",
// "age_grande") con el título y las edades debajo, igual que en Android.

struct AgeSelectView: View {
    let onSelect: (String) -> Void

    var body: some View {
        ZStack {
            MenuBackground()

            VStack(spacing: 12) {
                Text(L("MENU_EDAD_TITULO"))
                    .font(.fredoka(32, .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)

                HStack(spacing: 36) {
                    AgeCard(title: L("MENU_PEQUE"), ages: L("MENU_PEQUE_EDADES"), asset: "age_peque") {
                        onSelect(ProgressStore.modePeque)
                    }
                    AgeCard(title: L("MENU_GRANDE"), ages: L("MENU_GRANDE_EDADES"), asset: "age_grande") {
                        onSelect(ProgressStore.modeGrande)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .statusBar(hidden: true)
    }
}

private struct AgeCard: View {
    let title: String
    let ages: String
    let asset: String
    let action: () -> Void

    var body: some View {
        Button {
            AudioManager.shared.playSound(named: "tap")
            action()
        } label: {
            VStack(spacing: 2) {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Text(title)
                    .font(.fredoka(32, .bold))
                    .foregroundColor(Theme.gold)
                    .padding(.top, 4)
                Text(ages)
                    .font(.fredoka(17, .medium))
                    .foregroundColor(.white)
            }
            .padding(10)
            .aspectRatio(0.82, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Theme.darkPurple)
                    .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Theme.gold, lineWidth: 5))
            )
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(title), \(ages)")
    }
}
