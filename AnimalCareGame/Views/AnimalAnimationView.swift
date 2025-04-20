import SwiftUI

struct AnimalAnimationView: View {
    // 表示する動物
    let animal: Animal
    
    // アニメーション状態
    let isFeeding: Bool
    let isPlaying: Bool
    let isPetting: Bool
    
    // アニメーション用の状態変数
    @State private var bounceEffect = false
    @State private var rotationEffect = false
    @State private var scaleEffect = false
    
    var body: some View {
        VStack {
            // 動物のアニメーション
            ZStack {
                // 基本イメージ（システムアイコンを使用、実際のアプリでは画像を使用）
                Image(systemName: getAnimalIcon())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .foregroundColor(getAnimalColor())
                    .opacity(0.9)
                    .offset(y: bounceEffect ? -10 : 0)
                    .rotationEffect(.degrees(rotationEffect ? 5 : -5))
                    .scaleEffect(scaleEffect ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: bounceEffect
                    )
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: rotationEffect
                    )
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: scaleEffect
                    )
                    .onAppear {
                        startAnimationIfNeeded()
                    }
                    .onChange(of: isFeeding) { _ in startAnimationIfNeeded() }
                    .onChange(of: isPlaying) { _ in startAnimationIfNeeded() }
                    .onChange(of: isPetting) { _ in startAnimationIfNeeded() }
                
                // 状態によるテキストオーバーレイ
                if let overlayText = getOverlayText() {
                    Text(overlayText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getOverlayColor())
                        .padding(10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.bottom, 10)
            
            // 動物の名前と種類表示
            VStack(spacing: 4) {
                Text(animal.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(animal.type.displayName)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // 動物のアイコンを取得
    private func getAnimalIcon() -> String {
        // 状態に応じてアイコンを返す
        if isFeeding {
            return "\(animal.type.iconName).fill"
        } else if isPlaying {
            return animal.type.iconName
        } else if isPetting {
            return "\(animal.type.iconName).fill"
        } else if animal.hunger < 30 {
            return "exclamationmark.\(animal.type.iconName)"
        } else if animal.happiness < 30 {
            return animal.type.iconName
        } else {
            return "\(animal.type.iconName).fill"
        }
    }
    
    // 動物の色を取得
    private func getAnimalColor() -> Color {
        if isFeeding {
            return .orange
        } else if isPlaying {
            return .green
        } else if isPetting {
            return .purple
        } else if animal.hunger < 30 {
            return .red
        } else if animal.happiness < 30 {
            return .gray
        } else {
            return .accentColor
        }
    }
    
    // オーバーレイテキストを取得
    private func getOverlayText() -> String? {
        if isFeeding {
            return "もぐもぐ..."
        } else if isPlaying {
            return "わーい！"
        } else if isPetting {
            return "なでなで♪"
        } else if animal.hunger < 30 {
            return "おなかすいた..."
        } else if animal.happiness < 30 {
            return "さみしい..."
        }
        return nil
    }
    
    // オーバーレイの色を取得
    private func getOverlayColor() -> Color {
        if isFeeding {
            return .orange
        } else if isPlaying {
            return .green
        } else if isPetting {
            return .purple
        } else if animal.hunger < 30 {
            return .red
        } else if animal.happiness < 30 {
            return .gray
        }
        return .primary
    }
    
    // アニメーションを開始
    private func startAnimationIfNeeded() {
        // アクションが実行されていたらアニメーションをランダム化
        if isFeeding || isPlaying || isPetting {
            bounceEffect = true
            
            // ランダムな遅延でアニメーションを開始して自然に見せる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                rotationEffect = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                scaleEffect = true
            }
        } else {
            // 通常状態では動物の状態に基づいてアニメーション
            let needsAnimation = animal.hunger < 30 || animal.happiness < 30
            
            if needsAnimation {
                bounceEffect = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    rotationEffect = true
                }
            } else {
                // 元の状態に戻す
                bounceEffect = false
                rotationEffect = false
                scaleEffect = false
            }
        }
    }
} 