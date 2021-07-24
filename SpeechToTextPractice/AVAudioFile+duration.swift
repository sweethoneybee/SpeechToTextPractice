//
//  AVAudioFile+duration.swift
//  SpeechToTextPractice
//
//  Created by 정성훈 on 2021/07/11.
//

import Foundation
import AVFoundation

extension AVAudioFile{

    var duration: TimeInterval{
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong
        return lengthSongSeconds
    }

}
