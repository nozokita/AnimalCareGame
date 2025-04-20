import Foundation
import SwiftUI
import Combine

class AnimalCareViewModel: ObservableObject {
    // 動物のリスト
    @Published var animals: [Animal] = []
    
    // 選択されている動物
    @Published var selectedAnimal: Animal?
    
    // アニメーション状態
    @Published var showAnimation = false
    @Published var animationState: AnimalState = .normal
    
    // アクション状態
    @Published var isFeeding: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isPetting: Bool = false
    
    // サウンド設定
    @Published var isSoundEnabled: Bool = true
    
    // データ保存キー
    private let saveKey = "savedAnimals"
    private let soundEnabledKey = "soundEnabled"
    
    // タイマー
    private var statusTimer: Timer?
    
    init() {
        loadAnimals()
        loadSoundPreference()
        setupTimer()
    }
    
    // タイマーセットアップ（1時間ごとに状態を更新）
    private func setupTimer() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateAllAnimalsStatus()
        }
    }
    
    // データを保存
    private func saveAnimals() {
        if let encoded = try? JSONEncoder().encode(animals) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // データを読み込み
    private func loadAnimals() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Animal].self, from: data) {
            animals = decoded
            
            // 最初の動物を選択する（存在する場合）
            if !animals.isEmpty {
                selectedAnimal = animals[0]
            }
        }
    }
    
    // サウンド設定を保存
    private func saveSoundPreference() {
        UserDefaults.standard.set(isSoundEnabled, forKey: soundEnabledKey)
    }
    
    // サウンド設定を読み込み
    private func loadSoundPreference() {
        isSoundEnabled = UserDefaults.standard.bool(forKey: soundEnabledKey)
    }
    
    // アニメーション表示
    func showAnimationFor(state: AnimalState, duration: Double = 2.0) {
        animationState = state
        showAnimation = true
        
        // 設定時間後にアニメーションを終了
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.showAnimation = false
        }
    }
    
    // すべての動物の状態を更新
    func updateAllAnimalsStatus() {
        for index in animals.indices {
            animals[index].updateStatus()
        }
        
        // 選択された動物も更新
        if let selectedIndex = animals.firstIndex(where: { $0.id == selectedAnimal?.id }) {
            selectedAnimal = animals[selectedIndex]
        }
        
        saveAnimals()
    }
    
    // 新しい動物を作成
    func createAnimal(name: String, type: AnimalType) {
        let newAnimal = Animal(name: name, type: type)
        animals.append(newAnimal)
        selectedAnimal = newAnimal
        saveAnimals()
    }
    
    // 動物を選択
    func selectAnimal(_ animal: Animal) {
        selectedAnimal = animal
    }
    
    // 動物を削除
    func deleteAnimal(_ animal: Animal) {
        animals.removeAll { $0.id == animal.id }
        
        // 選択されていた動物が削除された場合、別の動物を選択
        if selectedAnimal?.id == animal.id {
            selectedAnimal = animals.first
        }
        
        saveAnimals()
    }
    
    // 動物に餌をやる
    func feedAnimal() {
        guard var animal = selectedAnimal else { return }
        
        // 動物に餌をあげる
        animal.feed()
        
        // アニメーションフラグを設定
        isFeeding = true
        showAnimationFor(state: .eating)
        
        // アニメーションが終わったらフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isFeeding = false
        }
        
        // サウンド効果を再生（実装が必要）
        if isSoundEnabled {
            playSound("eating")
        }
        
        // 動物のリストを更新
        updateAnimalInList(animal)
    }
    
    // 動物と遊ぶ
    func playWithAnimal() {
        guard var animal = selectedAnimal else { return }
        
        // 動物と遊ぶ
        animal.play()
        
        // アニメーションフラグを設定
        isPlaying = true
        showAnimationFor(state: .playing)
        
        // アニメーションが終わったらフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isPlaying = false
        }
        
        // サウンド効果を再生（実装が必要）
        if isSoundEnabled {
            playSound("playing")
        }
        
        // 動物のリストを更新
        updateAnimalInList(animal)
    }
    
    // 動物をなでる
    func petAnimal() {
        guard var animal = selectedAnimal else { return }
        
        // 動物をなでる
        animal.pet()
        
        // アニメーションフラグを設定
        isPetting = true
        showAnimationFor(state: .petting, duration: 1.5)
        
        // アニメーションが終わったらフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isPetting = false
        }
        
        // サウンド効果を再生（実装が必要）
        if isSoundEnabled {
            playSound("petting")
        }
        
        // 動物のリストを更新
        updateAnimalInList(animal)
    }
    
    // リスト内の動物を更新
    private func updateAnimalInList(_ updatedAnimal: Animal) {
        if let index = animals.firstIndex(where: { $0.id == updatedAnimal.id }) {
            animals[index] = updatedAnimal
            selectedAnimal = updatedAnimal
            saveAnimals()
        }
    }
    
    // サウンド効果の有効/無効を切り替え
    func toggleSound() {
        isSoundEnabled.toggle()
        saveSoundPreference()
    }
    
    // サウンドを再生（実際の実装はプラットフォームに依存）
    private func playSound(_ name: String) {
        // 実際のサウンド再生コードはここに実装
        // 例: AVAudioPlayerを使用
    }
} 