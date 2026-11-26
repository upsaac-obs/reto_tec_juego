// Creación y desarrollo: Dylan Isaac Mancilla López
import SwiftUI

// MARK: - Garaje (se abre desde el mapa; igual que GarageScreen.kt de Android)
// El niño gasta sus estrellas en otro vehículo y elige con cuál juega. Comprar pide
// confirmación porque no hay devoluciones.
// - Comprado: un toque lo elige.
// - Alcanza: un toque pregunta si lo compra.
// - No alcanza: suena cerrado y avisa "Te faltan estrellas".
// - Kiosco: todo disponible, sin precios ni saldo.

struct GarageView: View {
    let model: AppModel
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var confirm: Vehicle?
    @State private var showMissing = false
    @State private var missingToken = 0

    private var store: ProgressStore { model.store }

    var body: some View {
        ZStack {
            MenuBackground()

            VStack(spacing: 12) {
                HStack {
                    BackButton {
                        AudioManager.shared.playSound(named: "menu_tap")
                        dismiss()
                    }
                    Spacer()
                    Text(L("GARAJE_TITULO"))
                        .font(.fredoka(30, .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if store.kiosk {
                        Color.clear.frame(width: Theme.cornerButton, height: Theme.cornerButton)
                    } else {
                        CoinBalance(balance: store.coinBalance)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Garage.all) { vehicle in
                            VehicleCard(
                                vehicle: vehicle,
                                owned: store.ownsVehicle(vehicle.id),
                                selected: store.currentVehicle == vehicle.id,
                                affordable: store.coinBalance >= vehicle.price
                            ) { tap(vehicle) }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: .infinity)

                Text(L("GARAJE_FALTAN"))
                    .font(.fredoka(18, .bold))
                    .foregroundColor(Theme.gold)
                    .opacity(showMissing ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showMissing)
            }
            .padding(16)

            if let vehicle = confirm {
                BuyDialog(vehicle: vehicle) {
                    AudioManager.shared.playSound(named: "menu_unlock")
                    store.buyVehicle(vehicle.id)
                    confirm = nil
                } onNo: {
                    AudioManager.shared.playSound(named: "menu_tap")
                    confirm = nil
                }
            }
        }
        .statusBar(hidden: true)
    }

    private func tap(_ vehicle: Vehicle) {
        if store.ownsVehicle(vehicle.id) {
            AudioManager.shared.playSound(named: "menu_tap")
            store.selectVehicle(vehicle.id)
        } else if store.coinBalance >= vehicle.price {
            AudioManager.shared.playSound(named: "menu_tap")
            confirm = vehicle
        } else {
            AudioManager.shared.playSound(named: "menu_locked")
            showMissing = true
            missingToken += 1
            let token = missingToken
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if missingToken == token { showMissing = false }
            }
        }
    }
}

// MARK: - Tarjeta de un vehículo

private struct VehicleCard: View {
    let vehicle: Vehicle
    let owned: Bool
    let selected: Bool
    let affordable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Image(vehicle.image)
                        .resizable()
                        .scaledToFit()
                        .opacity(owned || affordable ? 1 : 0.55)
                    if vehicle.id == Garage.motoId {
                        Image("icon_helmet")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .accessibilityLabel(L("GARAJE_MOTO_CASCO"))
                    }
                    if !owned && !affordable {
                        Image("icon_lock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                .frame(height: 96)

                Text(L(vehicle.nameKey))
                    .font(.fredoka(18, .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Group {
                    if selected {
                        Text(L("GARAJE_USANDO"))
                            .font(.fredoka(14, .bold))
                            .foregroundColor(Theme.gold)
                    } else if !owned {
                        Price(price: vehicle.price).opacity(affordable ? 1 : 0.6)
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 32)
            }
            .padding(12)
            .frame(width: 170)
            .background(RoundedRectangle(cornerRadius: 22).fill(Theme.darkPurple.opacity(0.9)))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(selected ? Theme.gold : Color(hex: "1E0F26"), lineWidth: selected ? 4 : 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(L(vehicle.nameKey))
        .accessibilityValue(selected ? L("GARAJE_USANDO") : (owned ? "" : "\(vehicle.price) ★"))
    }
}

// MARK: - Precio y saldo (estrella moneda)

private struct Price: View {
    let price: Int
    var iconSize: CGFloat = 26

    var body: some View {
        HStack(spacing: 4) {
            Image("icon_coin_star").resizable().scaledToFit().frame(width: iconSize, height: iconSize)
            Text("\(price)").font(.fredoka(20, .bold)).foregroundColor(Theme.gold)
        }
    }
}

private struct CoinBalance: View {
    let balance: Int

    var body: some View {
        HStack(spacing: 8) {
            Image("icon_coin_star").resizable().scaledToFit().frame(width: 34, height: 34)
            Text("\(balance)").font(.fredoka(22, .bold)).foregroundColor(Theme.gold)
        }
        .padding(.leading, 8)
        .padding(.trailing, 18)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.darkPurple.opacity(0.88)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(balance) ★")
    }
}

// MARK: - ¿Lo compras?

private struct BuyDialog: View {
    let vehicle: Vehicle
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "1E0F26").opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onNo)

            VStack(spacing: 8) {
                Image(vehicle.image).resizable().scaledToFit().frame(height: 100)
                Text(L(vehicle.nameKey)).font(.fredoka(22, .bold)).foregroundColor(.white)
                Price(price: vehicle.price)
                if vehicle.id == Garage.motoId {
                    Text(L("GARAJE_MOTO_CASCO"))
                        .font(.fredoka(15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                Text(L("GARAJE_COMPRAR"))
                    .font(.fredoka(16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                HStack(spacing: 14) {
                    Pill(label: L("GARAJE_NO"), fill: Color(hex: "534A5E"), text: .white, action: onNo)
                    Pill(label: L("GARAJE_SI"), fill: Theme.gold, text: Theme.darkPurple, action: onYes)
                }
                .padding(.top, 6)
            }
            .padding(18)
            .frame(width: 380)
            .background(RoundedRectangle(cornerRadius: 26).fill(Theme.darkPurple))
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Theme.gold, lineWidth: 3))
        }
    }
}

private struct Pill: View {
    let label: String
    let fill: Color
    let text: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.fredoka(20, .bold))
                .foregroundColor(text)
                .padding(.horizontal, 26)
                .padding(.vertical, 10)
                .background(Capsule().fill(fill))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
