//
//  Codables.swift
//  SpeechToTextPractice
//
//  Created by 정성훈 on 2021/08/10.
//

import Foundation

// MARK: - GoogleSpeechJSON
struct GoogleSpeechJSON: Codable {
    let config: Config
    let audio: Audio
}

// MARK: - Audio
struct Audio: Codable {
    let content: String
}

// MARK: - Config
struct Config: Codable {
    let encoding: String
    let sampleRateHertz: Int
    let languageCode: String
}

// MARK: - GoogleSpeechResult
struct GoogleSpeechResult: Decodable {
    let results: [Result]
    let totalBilledTime: String
}

struct Result: Decodable {
    let alternatives: [Alternative]
    let languageCode: String
}

struct Alternative: Decodable {
    let transcript: String
    let confidence: Double
}
