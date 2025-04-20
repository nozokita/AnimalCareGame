import SwiftUI
import AVFoundation
import Combine

// MARK: - GameViewModel クラス
class GameViewModel: ObservableObject {
    // MARK: - Animal Care Properties
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

    // MARK: - Game State
    @Published var gameState: GameState = .initialSelection

    // MARK: - Game Properties
    @Published var currentGameMode: GameMode = .shopping
    @Published var currentShopType: ShopType = .fruitStand
    
    // MARK: - Initialization
    init() {
        initializePuppyInfo()
    }
    
    deinit {
        stopTimeOfDayTimer()
    }
    
    // MARK: - Navigation Methods
    func returnToModeSelection() {
        gameState = .initialSelection
    }
    
    func startAnimalCareMode() {
        gameState = .animalCare
        // タイマーなどのリセット処理
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

// MARK: - Enum Types
// ゲームの状態を表すEnum
enum GameState {
    case initialSelection // 追加: 最初のモード選択画面
    case modeSelection    // 既存: お店屋さんモードの詳細選択
    case playing          // 既存: お店屋さんモードプレイ中
    case playingCustomer  // 追加: お客さんモードプレイ中
    case animalCare       // 追加: どうぶつのおへや
    case result
}

// ゲームモードを表すEnum
enum GameMode: CaseIterable {
    case shopping // 通常のお買い物モード
    case calculationQuiz // 簡単な計算モード
    case priceQuiz // 金額計算モード
    case listeningQuiz // リスニングクイズモード
}

// お店の種類を表すEnum
enum ShopType: String, CaseIterable, Identifiable {
    case fruitStand // 果物屋
    case bakery     // パン屋
    case cakeShop   // ケーキ屋
    case restaurant // レストラン
    
    var id: String { rawValue }
    
    // 表示名を返す
    func localizedName(language: String) -> String {
        switch self {
        case .fruitStand:
            return language == "ja" ? "くだものや" : "Fruit Stand"
        case .bakery:
            return language == "ja" ? "パンや" : "Bakery"
        case .cakeShop:
            return language == "ja" ? "ケーキや" : "Cake Shop"
        case .restaurant:
            return language == "ja" ? "レストラン" : "Restaurant"
        }
    }
    
    // 画像名を返す
    var imageName: String {
        switch self {
        case .fruitStand: return "shop_fruit"
        case .bakery: return "shop_bakery"
        case .cakeShop: return "shop_cake"
        case .restaurant: return "shop_restaurant"
        }
    }
} 