//
//  ThirdPartySpeechRecognition.swift
//  SpeechToTextPractice
//
//  Created by 정성훈 on 2021/08/06.
//

import UIKit
import Foundation
import AVFoundation

class ThirdPartySpeechRecognition: UIViewController {
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFileURL: URL!
    private var recordStartTime: Date!
    private var recordFinishTime: Date!
    
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var recordTimeLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onRecordButton(_ sender: Any) {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func startRecording() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async { [self] in
                    guard let self = self else { return }
                    if allowed {
                        self.audioFileURL = self.getDocumentsDirectory().appendingPathComponent("recording_\(SpeechDefaults.shared.fileId).m4a")
                        
                        let settings = [
                            AVFormatIDKey: Int(kAudioFormatLinearPCM),
                            AVSampleRateKey: 12000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                        ]
                        
                        do {
                            self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL, settings: settings)
                            self.audioRecorder.delegate = self
                            self.audioRecorder.record()
                            self.recordStartTime = Date()
                            
                            self.urlLabel.text = self.audioFileURL.absoluteString
                            SpeechDefaults.shared.fileURL = self.audioFileURL
                            self.recordButton.setTitle("녹음중", for: [])
                        } catch {
                            self.finishRecording(success: false)
                        }
                    } else {
                        self.finishRecording(success: false)
                    }
                }
                
            }
            
        } catch {
            print("세션 초기화, 권한 획득 중 오류! \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            recordFinishTime = Date()
            let recordTime = Double(recordFinishTime.timeIntervalSince(recordStartTime))
            recordTimeLabel.text = String(format: "%.2f 초 녹음", recordTime)
            
            recordButton.setTitle("다시 녹음?", for: [])
        }
        else {
            recordButton.setTitle("실패함. 다시 녹음?", for: [])
        }
    }
    
    // MARK:- Recognition
    @IBAction func requestRecognition(_ sender: Any) {
        guard let kakaoUrl = URL(string:"https://kakaoi-newtone-openapi.kakao.com/v1/recognize") else { return }
        var request = URLRequest(url: kakaoUrl)
        request.httpMethod = "POST"
        request.addValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.addValue("KakaoAK \(ApiKey.kakaoI)", forHTTPHeaderField: "Authorization")
        
        guard let data = try? Data(contentsOf: audioFileURL) else {
            print("데이터 준비 실패")
            return
        }
        request.httpBody = data
        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("요청 실패. 에러=\(error)")
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    print("response 캐스팅 실패")
                    return
                }
                guard let data = data else {
                    print("data 캐스팅 실패")
                    return
                }
                
                print("response = \(response)")
                
                print("data = \(data)")
                
                let str = String(data: data, encoding: .utf8)
                print("문자열 =\(str!)")
                
            }.resume()
        }
    }
}

extension ThirdPartySpeechRecognition: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: true)
        }
    }
}

