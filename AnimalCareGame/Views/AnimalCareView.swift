import SwiftUI

struct AnimalCareView: View {
    @ObservedObject var viewModel: AnimalCareViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            if let animal = viewModel.selectedAnimal {
                // 選択された動物がいる場合
                VStack(spacing: 24) {
                    // ヘッダー
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("\(animal.name)のお世話")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleSound()
                        }) {
                            Image(systemName: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // 動物のアニメーションビュー
                            AnimalAnimationView(
                                animal: animal,
                                isFeeding: viewModel.isFeeding,
                                isPlaying: viewModel.isPlaying,
                                isPetting: viewModel.isPetting
                            )
                            .padding(.top, 10)
                            
                            // ステータスカード
                            statusCard(animal)
                                .padding(.horizontal)
                            
                            // アクションボタン
                            actionButtons(animal)
                                .padding(.horizontal)
                                .padding(.bottom, 24)
                        }
                    }
                }
                .padding(.top)
            } else {
                // 選択された動物がいない場合
                VStack {
                    Text("動物が選択されていません")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("戻る")
                            .fontWeight(.semibold)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
            }
        }
        .onAppear {
            viewModel.updateAllAnimalsStatus()
        }
    }
    
    // ステータスカード
    private func statusCard(_ animal: Animal) -> some View {
        VStack(spacing: 16) {
            // 満腹度
            statusBar(
                title: "おなか",
                value: animal.hunger,
                maxValue: 100,
                icon: "fork.knife",
                color: animal.hungerStatus.color
            )
            
            // 幸福度
            statusBar(
                title: "きもち",
                value: animal.happiness,
                maxValue: 100,
                icon: "heart.fill",
                color: animal.happinessStatus.color
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    // ステータスバー
    private func statusBar(title: String, value: Int, maxValue: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(value)/\(maxValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // バックグラウンド
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width, height: 12)
                        .cornerRadius(6)
                    
                    // フィルバー
                    Rectangle()
                        .foregroundColor(color)
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 12)
                        .cornerRadius(6)
                }
            }
            .frame(height: 12)
        }
    }
    
    // アクションボタン
    private func actionButtons(_ animal: Animal) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 餌やりボタン
                actionButton(
                    title: "えさをあげる",
                    icon: "fork.knife",
                    color: .orange,
                    action: { viewModel.feedAnimal() },
                    disabled: animal.hunger >= 100
                )
                
                // 遊ぶボタン
                actionButton(
                    title: "あそぶ",
                    icon: "figure.play",
                    color: .green,
                    action: { viewModel.playWithAnimal() },
                    disabled: animal.hunger <= 10
                )
            }
            
            // 撫でるボタン
            actionButton(
                title: "なでる",
                icon: "hand.tap.fill",
                color: .purple,
                action: { viewModel.petAnimal() },
                disabled: false,
                isFullWidth: true
            )
        }
    }
    
    // アクションボタンのコンポーネント
    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void,
        disabled: Bool,
        isFullWidth: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: isFullWidth ? .infinity : .none)
            .background(disabled ? Color.gray.opacity(0.3) : color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(disabled)
        .frame(maxWidth: isFullWidth ? .infinity : .none)
    }
} 