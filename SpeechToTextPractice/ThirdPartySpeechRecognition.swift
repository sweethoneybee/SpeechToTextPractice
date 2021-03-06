//
//  ThirdPartySpeechRecognition.swift
//  SpeechToTextPractice
//
//  Created by 정성훈 on 2021/08/06.
//

import UIKit
import Foundation
import AVFoundation
import Alamofire
import os


class ThirdPartySpeechRecognition: UIViewController {
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFileURL: URL!
    private var recordStartTime: Date!
    private var recordFinishTime: Date!
    private var logger = Logger()
    
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
                        self.audioFileURL = self.getDocumentsDirectory().appendingPathComponent("recording_\(SpeechDefaults.shared.fileId).mp4")
                        
                        let settings = [
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//                            AVFormatIDKey: Int(kAudioFormatLinearPCM),
                            AVSampleRateKey: 16000,
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
            logger.info("세션 초기화, 권한 획등 중 오류!")
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
    
    // MARK:- File Format
    @IBAction
    func fileMove() {
        let atPath = audioFileURL.absoluteString
        if let range = atPath.range(of: ".m4a") {
            var toPath = String(atPath[..<range.lowerBound])
            toPath.append(".wav")
            guard let data = try? Data(contentsOf: audioFileURL) else { return }
            
            do {
                let toURL = URL(string: toPath)!
                try data.write(to: toURL)
                print("성공")
                logger.debug("성공")
                audioFileURL = toURL
            } catch {
                print("실패")
                logger.debug("실패")
            }
        }
    }
    // MARK:- Recognition
    @IBAction func requestRecognition(_ sender: Any) {
        guard let audioFileURL = audioFileURL,
              let data = try? Data(contentsOf: audioFileURL) else {
            print("데이터 준비 실패")
            return
        }
        
//        requestKakao(data: data)
//        requestKakaoAF(data: data)
//        requestGoogle(data: data)
        requestGoogleAF(data: data)
    }
    
    private func requestKakao(data: Data) {
        guard let kakaoUrl = URL(string:"https://kakaoi-newtone-openapi.kakao.com/v1/recognize") else { return }
    
        guard let audioFileURL = audioFileURL,
              let data = try? Data(contentsOf: audioFileURL) else {
            print("데이터 준비 실패")
            return
        }
        
        print("요청할 URL=\(audioFileURL)")
        var request = URLRequest(url: kakaoUrl)
        request.httpMethod = "POST"
        request.addValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.addValue("KakaoAK \(ApiKey.kakaoI)", forHTTPHeaderField: "Authorization")

        request.httpBody = data
        let workItem = DispatchWorkItem {
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

        DispatchQueue.global().async(execute: workItem)
        workItem.cancel()
        
        
    }
    
    private func requestKakaoAF(data: Data) {
        guard let kakaoUrl = URL(string:"https://kakaoi-newtone-openapi.kakao.com/v1/recognize") else { return }
        let headers: HTTPHeaders = [
            "Transfer-Encoding": "chunked",
            "Content-Type": "application/octet-stream",
            "Authorization": "KakaoAK \(ApiKey.kakaoI)"
        ]
        
        AF.upload(data, to: kakaoUrl, headers: headers)
            .response { response in
                print("요청성공")
                guard let data = response.data else {
                    print("데이터 변환실패")
                    return
                }
                
                let str = String(data: data, encoding: .utf8)!
                print(str)
            }
    }
    
    private func requestGoogle(data: Data) {
        var request = URLRequest(url: URL(string: "https://speech.googleapis.com/v1p1beta1/speech:recognize?key=\(ApiKey.google)")!)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let config = Config(encoding: "MP3", // "LINEAR16"
                            sampleRateHertz: 16000,
                            languageCode: "ko-KR")
        let audio = Audio(content: data.base64EncodedString())
        let googleSpeechJSON = GoogleSpeechJSON(config: config, audio: audio)
        
        guard let body = try? JSONEncoder().encode(googleSpeechJSON) else {
            print("JSON 인코딩 실패")
            return
        }
        request.httpBody = body
        
        let workItem = DispatchWorkItem {
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

                do {
                    let resultJSON = try JSONDecoder().decode(GoogleSpeechResult.self, from: data)
                    print("=========구글 결과물 변환 성공========")
                    print("결과물=\(resultJSON)")
                } catch {
                    print("구글 결과물 변환 실패")
                }
                let str = String(data: data, encoding: .utf8)
                print("==============결과물 텍스트로 변환==============")
                print(str!)
            }.resume()
        }
        
        DispatchQueue.global().async(execute: workItem)
    }
    
    private func requestGoogleAF(data: Data) {
        guard let url = URL(string: "https://speech.googleapis.com/v1p1beta1/speech:recognize?key=\(ApiKey.google)") else { return }
        let config = Config(encoding: "MP3", // "LINEAR16"
                            sampleRateHertz: 16000,
                            languageCode: "ko-KR")
        let audio = Audio(content: data.base64EncodedString())
        let googleSpeechJSON = GoogleSpeechJSON(config: config, audio: audio)
    
        _ = AF.request(url, method: .post, parameters: googleSpeechJSON, encoder: JSONParameterEncoder.default).response { response in
            switch response.result {
            case .failure(let error):
                print("에러!=\(error)")
            case .success(let data):
                guard let data = data,
                      let result = try? JSONDecoder().decode(GoogleSpeechResult.self, from: data) else {
                    print("성공은 했지만 데이터 닐")
                    self.logger.info("성공은 했지만 데이터 닐")
                    return
                }
                
                self.logger.debug("디버그 로깅")
                print(result)
            }
        }
        
        
//        _ = AF.request(url, method: .post, parameters: googleSpeechJSON, encoder: JSONParameterEncoder.default)
//            .responseDecodable(of: GoogleSpeechResult.self) { response in
//                print(response)
//            }
    }
}

extension ThirdPartySpeechRecognition: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: true)
        }
    }
}


