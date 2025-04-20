import Foundation
import SwiftUI

// 動物の種類を表す列挙型
enum AnimalType: String, Codable, CaseIterable, Identifiable {
    case dog
    case cat
    case rabbit
    case hamster
    
    var id: String { rawValue }
    
    // 表示名
    var displayName: String {
        switch self {
        case .dog:
            return "いぬ"
        case .cat:
            return "ねこ"
        case .rabbit:
            return "うさぎ"
        case .hamster:
            return "ハムスター"
        }
    }
    
    // アイコン名
    var iconName: String {
        switch self {
        case .dog:
            return "dog"
        case .cat:
            return "cat"
        case .rabbit:
            return "hare"
        case .hamster:
            return "tortoise"
        }
    }
    
    // 通常画像名
    var normalImageName: String {
        return "\(rawValue)_normal"
    }
    
    // 幸せ時の画像名
    var happyImageName: String {
        return "\(rawValue)_happy"
    }
    
    // お腹が空いた時の画像名
    var hungryImageName: String {
        return "\(rawValue)_hungry"
    }
    
    // 悲しい時の画像名
    var sadImageName: String {
        return "\(rawValue)_sad"
    }
}

// 動物の状態を表す列挙型
enum AnimalState: String, Codable {
    case normal
    case happy
    case hungry
    case sad
    case eating
    case playing
    case petting
    
    // 表示メッセージ
    var displayMessage: String {
        switch self {
        case .normal:
            return "ふつう"
        case .happy:
            return "うれしい！"
        case .hungry:
            return "おなかすいた..."
        case .sad:
            return "さみしい..."
        case .eating:
            return "もぐもぐ..."
        case .playing:
            return "わーい！"
        case .petting:
            return "なでなで♪"
        }
    }
}

// ケアレベルのステータス
enum CareLevelStatus {
    case excellent
    case good
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

// 動物クラス
struct Animal: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: AnimalType
    var hunger: Int = 70
    var happiness: Int = 70
    private var lastCareTime: Date = Date()
    
    init(name: String, type: AnimalType) {
        self.name = name
        self.type = type
        self.hunger = 70
        self.happiness = 70
        self.lastCareTime = Date()
    }
    
    // 現在の状態を計算
    var currentState: AnimalState {
        if hunger < 30 {
            return .hungry
        } else if happiness < 30 {
            return .sad
        } else if happiness > 80 {
            return .happy
        } else {
            return .normal
        }
    }
    
    // 満腹度のステータス
    var hungerStatus: CareLevelStatus {
        if hunger > 80 {
            return .excellent
        } else if hunger > 50 {
            return .good
        } else if hunger > 30 {
            return .warning
        } else {
            return .critical
        }
    }
    
    // 幸福度のステータス
    var happinessStatus: CareLevelStatus {
        if happiness > 80 {
            return .excellent
        } else if happiness > 50 {
            return .good
        } else if happiness > 30 {
            return .warning
        } else {
            return .critical
        }
    }
    
    // 状態に応じた画像名を取得
    func getImageName() -> String {
        switch currentState {
        case .hungry:
            return type.hungryImageName
        case .sad:
            return type.sadImageName
        case .happy:
            return type.happyImageName
        default:
            return type.normalImageName
        }
    }
    
    // 餌をあげる
    mutating func feed() {
        hunger = min(hunger + 20, 100)
        happiness = min(happiness + 10, 100)
        lastCareTime = Date()
    }
    
    // 遊ぶ
    mutating func play() {
        happiness = min(happiness + 25, 100)
        hunger = max(hunger - 5, 0)
        lastCareTime = Date()
    }
    
    // なでる
    mutating func pet() {
        happiness = min(happiness + 15, 100)
        lastCareTime = Date()
    }
    
    // 状態を更新する
    mutating func updateStatus() {
        // 最後のケアからの経過時間（時間単位）
        let hoursElapsed = hoursSinceLastCare
        
        if hoursElapsed > 0 {
            // 1時間ごとに満腹度は5減少
            hunger = max(hunger - (Int(hoursElapsed) * 5), 0)
            
            // 1時間ごとに幸福度は10減少
            happiness = max(happiness - (Int(hoursElapsed) * 10), 0)
            
            // 状態を更新した時間を記録
            lastCareTime = Date()
        }
    }
    
    // 最後のケアからの経過時間（時間単位）
    private var hoursSinceLastCare: Double {
        return Date().timeIntervalSince(lastCareTime) / 3600
    }
} 