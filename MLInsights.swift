import Foundation
import CoreML

// Player Type Classifier
struct PlayerTypeClassifier {
    let model: MLModel
    
    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "PlayerTypeClassifier", withExtension: "mlmodelc") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
        }
        self.model = try MLModel(contentsOf: modelURL)
    }
    
    func prediction() throws -> String {
        let input = try MLDictionaryFeatureProvider(dictionary: [:])
        let output = try model.prediction(from: input)
        return output.featureValue(for: "label")?.stringValue ?? "Unknown"
    }
}

// Player Frustration Model
struct PlayerFrustration {
    let model: MLModel
    
    init() throws {
        guard let modelURL = Bundle.main.url(forResource: "PlayerFrustration", withExtension: "mlmodelc") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
        }
        self.model = try MLModel(contentsOf: modelURL)
    }
    
    func prediction() throws -> Double {
        let input = try MLDictionaryFeatureProvider(dictionary: [:])
        let output = try model.prediction(from: input)
        return output.featureValue(for: "frustrationScore")?.doubleValue ?? 0.0
    }
}

// Get Player Insights
struct MLInsights {
    // Add constants for timesFooled calculation
    private static let maxHesitation: Double = 10.0
    private static let maxDeaths: Double = 50.0
    private static let maxErrors: Double = 8.0
    private static let maxTimesFooled: Double = 7.0
    
    private static let weights = (
        hesitation: 0.4,  // w1
        deaths: 0.4,      // w2
        errors: 0.2       // w3
    )
    
    // Add new function to calculate timesFooled
    static func calculateTimesFooled(
        hesitationCount: Int,
        numberOfDeaths: Int,
        internalErrors: Int?
    ) -> Int {
        let hesitationRatio = Double(hesitationCount) / maxHesitation
        let deathsRatio = Double(numberOfDeaths) / maxDeaths
        let errorsRatio = Double(internalErrors ?? 0) / maxErrors
        
        let score = (
            (weights.hesitation * hesitationRatio) +
            (weights.deaths * deathsRatio) +
            (weights.errors * errorsRatio)
        ) * maxTimesFooled
        
        return min(Int(round(score)), Int(maxTimesFooled))
    }

    // Add the classify function to MLInsights
    static func classifyPlayerType(
        deaths: Int,
        hesitation: Int,
        timeSpent: TimeInterval,
        internalErrors: Int?,
        timesFooled: Int?
    ) -> String {
        let timeInMinutes = timeSpent / 60.0
        if deaths <= 15 && hesitation <= 2 && timeInMinutes <= 10 {
            return "Speedrunner"
        } else if deaths <= 10 && hesitation >= 3 && timeInMinutes >= 15 {
            return "Explorer"
        } else if deaths >= 5 && hesitation >= 5 && timeInMinutes >= 20 {
            return "Hesitant"
        } else if deaths >= 20 && hesitation <= 3 && timeInMinutes <= 15 {
            return "Risk-Taker"
        } else {
            return "Strategist"
        }
    }

    // Update getPlayerInsights to use timesFooled calculation
    static func getPlayerInsights(
        totalDeaths: Int,
        levelDeaths: Int?,
        hesitationCount: Int?,
        timeSpent: TimeInterval?,
        internalErrors: Int?,
        timesFooled: Int?,
        playerTypeClassifier: PlayerTypeClassifier?,
        frustrationModel: PlayerFrustration?
    ) -> (playerType: String, frustrationScore: Double) {
        // Calculate timesFooled if not provided
        let calculatedTimesFooled = timesFooled ?? calculateTimesFooled(
            hesitationCount: hesitationCount ?? 0,
            numberOfDeaths: totalDeaths,
            internalErrors: internalErrors
        )
        
        // Use the classifyPlayerType function instead of ML model
        let predictedType = classifyPlayerType(
            deaths: totalDeaths,
            hesitation: hesitationCount ?? 0,
            timeSpent: timeSpent ?? 0,
            internalErrors: internalErrors,
            timesFooled: calculatedTimesFooled
        )

        var frustrationScore = 0.0

        let w1: Double = 0.35
        let w2: Double = 0.20
        let w3: Double = 0.15
        let w4: Double = 0.20
        let w5: Double = 0.10

        let deaths = Double(levelDeaths ?? 0)
        let hesitations = Double(hesitationCount ?? 0)
        let time = timeSpent ?? 0
        let errors = Double(internalErrors ?? 0)
        let fooled = Double(calculatedTimesFooled)

        frustrationScore = (
            (w1 * deaths / 50) +
            (w2 * hesitations / 10) +
            (w3 * time / 30) +
            (w4 * errors / 8) +
            (w5 * fooled / 7)
        ) * 100.0
        
        frustrationScore = max(0, min(frustrationScore, 100))

        return (predictedType, frustrationScore)
    }

    // Update getPredictionMessage to include timesFooled in output
    static func getPredictionMessage(
        level: Int,
        totalDeaths: Int,
        levelDeaths: Int?,
        hesitationCount: Int?,
        timeSpent: TimeInterval?,
        internalErrors: Int?,
        timesFooled: Int?,
        playerTypeClassifier: PlayerTypeClassifier?,
        frustrationModel: PlayerFrustration?
    ) -> String {
        let calculatedTimesFooled = timesFooled ?? calculateTimesFooled(
            hesitationCount: hesitationCount ?? 0,
            numberOfDeaths: totalDeaths,
            internalErrors: internalErrors
        )
        
        let insights = getPlayerInsights(
            totalDeaths: totalDeaths,
            levelDeaths: levelDeaths,
            hesitationCount: hesitationCount,
            timeSpent: timeSpent,
            internalErrors: internalErrors,
            timesFooled: calculatedTimesFooled,
            playerTypeClassifier: playerTypeClassifier,
            frustrationModel: frustrationModel
        )

        let frustrationMessage: String = {
            switch Int(insights.frustrationScore) {
            case 0...20: return "Smooth sailing! You breezed through this level with minimal frustration."
            case 31...50: return "You’re starting to feel the heat—try a more deliberate approach next time."
            case 51...70: return "Things are getting intense—perhaps take a brief pause to regroup."
            case 71...100: return "Complete meltdown! It might be time for a break before you try again."
            default: return "Keep playing and improve your game!"
            }
        }()

        return """
        ML Insights - Level \(level):
        - Player Type: \(insights.playerType)
        - Frustration: \(String(format: "%.2f", insights.frustrationScore))/100
        - Times Fooled: \(calculatedTimesFooled)
        
        Stats:
        - Total Deaths: \(totalDeaths)
        \(levelDeaths != nil ? "- Level Deaths: \(levelDeaths!)\n" : "")
        \(hesitationCount != nil ? "- Hesitations: \(hesitationCount!)\n" : "")
        \(timeSpent != nil ? "- Time: \(String(format: "%.1f", timeSpent!))s\n" : "")
        \(internalErrors != nil ? "- Internal Errors: \(internalErrors!)\n" : "")
        
        \(frustrationMessage)
        """
    }
}
