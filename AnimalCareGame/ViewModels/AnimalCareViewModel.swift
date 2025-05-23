import Foundation
import SwiftUI
import Combine
import AVFoundation

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
    
    // MARK: - 子犬のお世話関連のプロパティ (GameViewModel互換)
    // 子犬の状態
    @Published var puppyHunger: Double = 80
    @Published var puppyHappiness: Double = 80
    @Published var lastAnimalCareTime: Date = Date()

    // 子犬アニメーションの状態管理
    @Published var showEatingAnimation: Bool = false
    @Published var showPlayingAnimation: Bool = false
    @Published var showPettingAnimation: Bool = false
    
    // うんち関連の状態管理
    @Published var poopCount: Int = 0
    @Published var lastPoopTime: Date = Date().addingTimeInterval(-3600) // 1時間前
    @Published var showCleaningAnimation: Bool = false
    
    // 子犬の名前と飼育日数関連
    @Published var puppyName: String = "まだ名前がありません"
    @Published var puppyAdoptionDate: Date = Date()
    @Published var isPuppyMissing: Bool = false
    @Published var lastInteractionDate: Date = Date()
    private let missingTimeThreshold: TimeInterval = 60 * 60 * 24 * 3 // 3日間

    // 時間帯関連の状態管理
    @Published var isDaytime: Bool = true
    private var timeOfDayTimer: Timer?
    
    // ゲーム状態
    @Published var gameState: GameState = .initialSelection
    @Published var currentGameMode: GameMode = .shopping
    @Published var currentShopType: ShopType = .fruitStand
    
    init() {
        loadAnimals()
        loadSoundPreference()
        setupTimer()
        initializePuppyInfo() // 子犬の情報も初期化
    }
    
    deinit {
        stopTimeOfDayTimer()
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
    
    // MARK: - GameViewModel互換メソッド
    
    // Navigation Methods
    func returnToModeSelection() {
        gameState = .initialSelection
    }
    
    func startAnimalCareMode() {
        gameState = .animalCare
    }
    
    // MARK: - Animal Care Methods
    /// 子犬に餌をあげる - 満腹度と機嫌が上がる
    func feedPuppy() {
        // お腹と機嫌を増加させる（最大100まで）
        puppyHunger = min(puppyHunger + 20, 100)
        puppyHappiness = min(puppyHappiness + 10, 100)
        lastAnimalCareTime = Date()
        
        // アニメーション指示
        showEatingAnimation = true
        
        // 3秒後にリセット（もっと長い時間表示するため）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showEatingAnimation = false
        }
        
        // 操作時間を更新
        updateLastInteraction()
    }
    
    /// 子犬と遊ぶ
    func playWithPuppy() {
        // 機嫌が大幅上昇（最大100）
        puppyHappiness = min(puppyHappiness + 25, 100)
        
        // 満腹度が少し減少（最小0）
        puppyHunger = max(puppyHunger - 5, 0)
        
        // ケア時間を更新
        lastAnimalCareTime = Date()
        
        // アニメーション指示
        showPlayingAnimation = true
        
        // 3秒後にリセット（長めに表示）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showPlayingAnimation = false
        }
        
        // 操作時間を更新
        updateLastInteraction()
    }
    
    /// 子犬の状態を時間経過に応じて更新する
    func updatePuppyStatus() {
        // 前回のお世話からの経過時間に基づいてステータスを更新
        let elapsedSeconds = Date().timeIntervalSince(lastAnimalCareTime)
        let hoursElapsed = elapsedSeconds / 3600
        
        // 1時間ごとにお腹と機嫌が減少する（減少率は調整可能）
        let hungerDecrease = min(hoursElapsed * 5, puppyHunger)
        let happinessDecrease = min(hoursElapsed * 10, puppyHappiness)
        
        puppyHunger = max(puppyHunger - hungerDecrease, 0)
        puppyHappiness = max(puppyHappiness - happinessDecrease, 0)
        
        // うんちの数も計算
        calculatePoops()
    }
    
    /// うんちの数を計算する - 一定時間経過ごとにうんちが増える
    func calculatePoops() {
        // 前回のお掃除からの経過時間に基づいてうんちの数を計算
        let elapsedSeconds = Date().timeIntervalSince(lastPoopTime)
        // 30分ごとにうんちが1つ増える（お腹が空いている場合より増える）
        let basePoopInterval: TimeInterval = 30 * 60 // 30分
        let hungerFactor = max(1.0, 2.0 - (Double(puppyHunger) / 100.0)) // お腹が空いているほど頻度が上がる
        let intervalAdjusted = basePoopInterval / hungerFactor
        
        let newPoops = Int(elapsedSeconds / intervalAdjusted)
        if newPoops > 0 {
            // 最大10個まで
            poopCount = min(poopCount + newPoops, 10)
            // 最後のうんち時間を更新（未来にならないように現在時刻を基準）
            lastPoopTime = Date()
        }
    }
    
    /// うんちを掃除する
    func cleanPoops() {
        // うんちがない場合は何もしない
        guard poopCount > 0 else { return }
        
        // うんちを0にする
        poopCount = 0
        // 最後の掃除時間を更新
        lastPoopTime = Date()
        
        // 掃除アニメーション指示
        showCleaningAnimation = true
        
        // 2秒後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCleaningAnimation = false
        }
        
        // 掃除すると機嫌が上がる
        puppyHappiness = min(puppyHappiness + 5, 100)
        
        // 操作時間を更新
        updateLastInteraction()
    }
    
    // MARK: - Time of Day Management
    /// 現在の時間帯を更新する
    func updateTimeOfDay() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // 6時〜18時を昼間、それ以外を夜とする
        isDaytime = (6...18).contains(hour)
    }
    
    /// 時間帯更新タイマーを開始する
    func startTimeOfDayTimer() {
        // 初期状態を設定
        updateTimeOfDay()
        
        // すでにタイマーがある場合は無効化
        timeOfDayTimer?.invalidate()
        
        // 1分ごとに時間帯をチェック
        timeOfDayTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeOfDay()
        }
    }
    
    /// 時間帯更新タイマーを停止する
    func stopTimeOfDayTimer() {
        timeOfDayTimer?.invalidate()
        timeOfDayTimer = nil
    }
    
    /// デモ用に時間帯を切り替える（開発用）
    func toggleTimeOfDay() {
        isDaytime.toggle()
    }
    
    // MARK: - Pet Name & Adoption Management
    /// 子犬の名前を保存する
    func savePuppyName(_ name: String) {
        puppyName = name
        UserDefaults.standard.set(name, forKey: "puppyName")
        updateLastInteraction() // 名前を付けたときに操作時間を更新
    }
    
    /// 子犬の名前を読み込む
    func loadPuppyName() {
        if let savedName = UserDefaults.standard.string(forKey: "puppyName") {
            puppyName = savedName
        }
    }
    
    /// 飼育開始日を保存する
    func savePuppyAdoptionDate(_ date: Date) {
        puppyAdoptionDate = date
        UserDefaults.standard.set(date, forKey: "puppyAdoptionDate")
        updateLastInteraction() // 飼育開始日を設定したときに操作時間を更新
    }
    
    /// 飼育開始日を読み込む
    func loadPuppyAdoptionDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "puppyAdoptionDate") as? Date {
            puppyAdoptionDate = savedDate
        } else {
            // 初めて開く場合は現在日時を設定
            puppyAdoptionDate = Date()
            savePuppyAdoptionDate(puppyAdoptionDate)
        }
    }
    
    /// 最後の操作日時を保存する
    private func saveLastInteractionDate(_ date: Date) {
        lastInteractionDate = date
        UserDefaults.standard.set(date, forKey: "lastInteractionDate")
    }
    
    /// 最後の操作日時を読み込む
    private func loadLastInteractionDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "lastInteractionDate") as? Date {
            lastInteractionDate = savedDate
        } else {
            // 初めての場合は現在日時を設定
            lastInteractionDate = Date()
            saveLastInteractionDate(lastInteractionDate)
        }
    }
    
    /// 子犬との最後の操作時間を更新する
    func updateLastInteraction() {
        let now = Date()
        saveLastInteractionDate(now)
        
        // 操作があったので子犬が去った状態をリセット
        if isPuppyMissing {
            isPuppyMissing = false
        }
    }
    
    /// 子犬が去ったかどうかをチェックする
    func checkPuppyMissing() {
        let now = Date()
        let timeSinceLastInteraction = now.timeIntervalSince(lastInteractionDate)
        
        // 一定時間操作がない場合、子犬が去った状態にする
        if timeSinceLastInteraction > missingTimeThreshold && !isPuppyMissing {
            isPuppyMissing = true
        }
    }
    
    /// 子犬の飼育をリセットする
    func resetPuppyAdoption() {
        // 新しい飼育開始日を設定
        savePuppyAdoptionDate(Date())
        
        // 子犬が去った状態をリセット
        isPuppyMissing = false
        
        // 操作時間を更新
        updateLastInteraction()
        
        // 子犬の状態をリセット
        puppyHunger = 100
        puppyHappiness = 100
        poopCount = 0
    }
    
    /// 飼育日数を計算して返す
    var puppyDaysWithYou: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: puppyAdoptionDate, to: Date())
        return max(components.day ?? 0, 0) // nilや負の値の場合は0を返す
    }
    
    /// 子犬の情報を初期化する
    func initializePuppyInfo() {
        // 既存の情報を読み込む
        loadPuppyName()
        loadPuppyAdoptionDate()
        loadLastInteractionDate()
        
        // 子犬が去ったかどうかをチェック
        checkPuppyMissing()
    }
} 