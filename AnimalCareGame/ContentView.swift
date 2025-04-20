//
//  ContentView.swift
//  AnimalCareGame
//
//  Created by Nozomu Kitamura on 4/20/25.
//

import SwiftUI

struct ContentView: View {
    // ビューモデルをStateObjectとして保持
    @StateObject private var viewModel = AnimalCareViewModel()
    
    // シート表示用の状態変数
    @State private var showingAnimalCreation = false
    @State private var showingAnimalCare = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.animals.isEmpty {
                    // 動物がいない場合のビュー
                    emptyStateView
                } else {
                    // 動物一覧
                    animalListView
                }
            }
            .navigationTitle("動物のお世話")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAnimalCreation = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.toggleSound()
                    }) {
                        Image(systemName: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAnimalCreation) {
                AnimalCreationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAnimalCare) {
                AnimalCareView(viewModel: viewModel)
            }
        }
    }
    
    // 動物がいない場合のビュー
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("動物がいません")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("「+」ボタンから新しい動物を追加しましょう")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                showingAnimalCreation = true
            }) {
                Text("動物を追加する")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    // 動物一覧ビュー
    private var animalListView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                ForEach(viewModel.animals) { animal in
                    AnimalCardView(animal: animal)
                        .onTapGesture {
                            viewModel.selectAnimal(animal)
                            showingAnimalCare = true
                        }
                }
            }
            .padding()
        }
    }
}

// 動物カードビュー
struct AnimalCardView: View {
    let animal: Animal
    
    var body: some View {
        VStack(spacing: 0) {
            // 動物のアイコン
            Image(systemName: animal.type.iconName)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .foregroundColor(.accentColor)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            // 動物名
            Text(animal.name)
                .font(.headline)
                .padding(.bottom, 4)
            
            // 動物の種類
            Text(animal.type.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            // ステータスバー
            HStack(spacing: 4) {
                // 満腹度
                statusBar(value: animal.hunger, color: .orange)
                
                // 幸福度
                statusBar(value: animal.happiness, color: .pink)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
            // 状態ラベル
            Text(animal.currentState.displayMessage)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor(for: animal.currentState))
                .foregroundColor(.white)
                .cornerRadius(0, corners: [.topLeft, .topRight])
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // ステータスバー
    private func statusBar(value: Int, color: Color) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // バックグラウンド
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(width: geometry.size.width, height: 8)
                    .cornerRadius(4)
                
                // フィルバー
                Rectangle()
                    .foregroundColor(color)
                    .frame(width: geometry.size.width * CGFloat(value) / 100, height: 8)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
    
    // 状態に応じた色
    private func statusColor(for state: AnimalState) -> Color {
        switch state {
        case .normal:
            return .blue
        case .happy:
            return .green
        case .hungry:
            return .orange
        case .sad:
            return .gray
        case .eating:
            return .orange
        case .playing:
            return .green
        case .petting:
            return .purple
        }
    }
}

// 角丸カスタマイズ用の拡張
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// 角丸カスタマイズ用の形状
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
}
