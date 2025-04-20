import SwiftUI

struct AnimalCareView: View {
    @ObservedObject var viewModel: AnimalCareViewModel
    
    var body: some View {
        ZStack {
            // 背景画像（昼/夜で切り替え）
            Image(viewModel.isDaytime ? "bg_room_day_portrait" : "bg_room_night_portrait")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                // ヘッダー
                HStack {
                    Button {
                        viewModel.returnToModeSelection()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .padding(10)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(viewModel.puppyName == "まだ名前がありません" ? "どうぶつのおへや" : viewModel.puppyName)
                            .font(.title2.bold())
                        
                        if viewModel.puppyName != "まだ名前がありません" {
                            Text("\(viewModel.puppyDaysWithYou)日目")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // デモ用に昼夜切り替えボタンを追加（開発用）
                    Button {
                        viewModel.toggleTimeOfDay()
                    } label: {
                        Image(systemName: viewModel.isDaytime ? "sun.max.fill" : "moon.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.isDaytime ? .orange : .indigo)
                            .padding(10)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // メインコンテンツエリア
                ZStack {
                    // 子犬の表示
                    puppyView
                    
                    // うんちの表示
                    poopView
                }
                
                Spacer()
                
                // ステータスバー
                statusBarsView
                    .padding(.horizontal)
                
                // アクションボタン
                actionButtonsView
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            
            // 子犬が不在の場合のオーバーレイ
            if viewModel.isPuppyMissing {
                missingPuppyOverlay
            }
            
            // 名前入力が必要な場合のオーバーレイ（初回のみ）
            if viewModel.puppyName == "まだ名前がありません" {
                nameInputOverlay
            }
        }
        .onAppear {
            // 画面表示時に子犬の状態を更新
            viewModel.updatePuppyStatus()
            viewModel.startTimeOfDayTimer()
        }
        .onDisappear {
            viewModel.stopTimeOfDayTimer()
        }
    }
    
    // 子犬の表示
    private var puppyView: some View {
        ZStack {
            if viewModel.isPuppyMissing {
                Image("puppy_missing")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else if viewModel.showEatingAnimation {
                Image("puppy_eating_1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else if viewModel.showPlayingAnimation {
                Image(["puppy_playing_1", "puppy_playing_2"].randomElement() ?? "puppy_playing_1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else if viewModel.showPettingAnimation {
                Image(["puppy_pet", "puppy_pet_1"].randomElement() ?? "puppy_pet")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else if viewModel.puppyHunger < 30 {
                Image("puppy_hungry_1.")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else if viewModel.puppyHappiness < 30 {
                Image("puppy_sad_1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else if viewModel.puppyHappiness > 80 {
                Image(["puppy_happy_1", "puppy_happy_2"].randomElement() ?? "puppy_happy_1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Image("puppy")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.showEatingAnimation)
        .animation(.easeInOut(duration: 0.5), value: viewModel.showPlayingAnimation)
        .animation(.easeInOut(duration: 0.5), value: viewModel.showPettingAnimation)
    }
    
    // うんちの表示
    private var poopView: some View {
        VStack {
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<min(viewModel.poopCount, 5), id: \.self) { index in
                    Image("poop")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .offset(y: -20)
                        .offset(x: CGFloat((index - 2) * 20))
                }
            }
            .frame(height: 40)
        }
        .padding(.bottom, 20)
    }
    
    // ステータスバー
    private var statusBarsView: some View {
        VStack(spacing: 15) {
            // 満腹度
            statusBar(
                label: "おなか",
                value: viewModel.puppyHunger,
                icon: "fork.knife",
                color: statusColor(for: viewModel.puppyHunger)
            )
            
            // 機嫌
            statusBar(
                label: "きもち",
                value: viewModel.puppyHappiness,
                icon: "heart.fill",
                color: statusColor(for: viewModel.puppyHappiness)
            )
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
    }
    
    // 個別のステータスバー
    private func statusBar(label: String, value: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // バックグラウンド
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: 10)
                        .cornerRadius(5)
                    
                    // フィルバー
                    Rectangle()
                        .foregroundColor(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 10)
                        .cornerRadius(5)
                }
            }
            .frame(height: 10)
        }
    }
    
    // アクションボタン
    private var actionButtonsView: some View {
        HStack(spacing: 15) {
            // 餌やりボタン
            actionButton(
                imageNamed: "icon_feed",
                label: "餌やり",
                action: { viewModel.feedPuppy() }
            )
            
            // 遊ぶボタン
            actionButton(
                imageNamed: "icon_play",
                label: "遊ぶ",
                action: { viewModel.playWithPuppy() }
            )
            
            // 撫でるボタン
            actionButton(
                imageNamed: "icon_pet",
                label: "なでる",
                action: {
                    // なでるアニメーションの表示
                    viewModel.showPettingAnimation = true
                    // 機嫌を少し上げる
                    viewModel.puppyHappiness = min(viewModel.puppyHappiness + 10, 100)
                    // 操作時間を更新
                    viewModel.updateLastInteraction()
                    
                    // 2秒後にアニメーションを終了
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        viewModel.showPettingAnimation = false
                    }
                }
            )
            
            // 掃除ボタン
            actionButton(
                imageNamed: "icon_clean",
                label: "掃除",
                action: { viewModel.cleanPoops() },
                disabled: viewModel.poopCount == 0
            )
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
    }
    
    // アクションボタンのコンポーネント
    private func actionButton(
        imageNamed: String,
        label: String,
        action: @escaping () -> Void,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(imageNamed)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 70)
            .foregroundColor(disabled ? .gray : .primary)
        }
        .disabled(disabled)
    }
    
    // 子犬が不在のオーバーレイ
    private var missingPuppyOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("子犬がいなくなりました...")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("長い間会いに来てくれなかったので\n子犬は新しい家族を探しに行ったようです")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                
                Button {
                    viewModel.resetPuppyAdoption()
                } label: {
                    Text("新しい子犬を迎える")
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // 名前入力オーバーレイ
    @State private var puppyNameInput: String = ""
    private var nameInputOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("新しい子犬がやってきました！")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Image("puppy_happy_1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                
                Text("名前をつけてあげましょう")
                    .foregroundColor(.white)
                
                TextField("子犬の名前", text: $puppyNameInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button {
                    if !puppyNameInput.isEmpty {
                        viewModel.savePuppyName(puppyNameInput)
                        viewModel.savePuppyAdoptionDate(Date())
                    }
                } label: {
                    Text("決定")
                        .fontWeight(.bold)
                        .padding()
                        .frame(width: 150)
                        .background(puppyNameInput.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(puppyNameInput.isEmpty)
                .padding(.top, 10)
            }
            .padding(30)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
            .padding()
        }
    }
    
    // ステータス値に応じた色を取得
    private func statusColor(for value: Double) -> Color {
        if value > 80 {
            return .green
        } else if value > 50 {
            return .blue
        } else if value > 30 {
            return .orange
        } else {
            return .red
        }
    }
} 