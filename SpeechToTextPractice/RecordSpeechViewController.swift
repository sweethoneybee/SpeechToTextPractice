//
//  RecordSpeechViewController.swift
//  SpeechToTextPractice
//
//  Created by 정성훈 on 2021/07/08.
//
// ref: https://www.hackingwithswift.com/example-code/media/how-to-record-audio-using-avaudiorecorder

import UIKit
import Speech
import AVFoundation

class RecordSpeechViewController: UIViewController, AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFileURL: URL!
    
    var speechRecognizer: SFSpeechRecognizer!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recognizeButton: UIButton!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var resultTextView: UITextView!
    
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
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 12000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                        ]
                        
                        do {
                            self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL, settings: settings)
                            self.audioRecorder.delegate = self
                            self.audioRecorder.record()
                            
                            self.urlLabel.text = self.audioFileURL.absoluteString ?? "URL 잘못됨"
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
            recordButton.setTitle("다시 녹음?", for: [])
        }
        else {
            recordButton.setTitle("실패함. 다시 녹음?", for: [])
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: true)
        }
    }
    
    // MARK: Recognizer
    @IBAction func onSpeechToTextButton(_ sender: Any) {
 
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier:"ko-KR"))
        guard let recognizer = speechRecognizer else {
            print("지원하지 않는 로케일입니다")
            return
        }
        
        if !recognizer.isAvailable {
            print("현재 사용가능하지 않습니다")
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioFileURL ?? SpeechDefaults.shared.fileURL ?? URL(fileURLWithPath: "abc"))
        
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        recognizer.recognitionTask(with: request) { result, error in
            guard let result = result else {
                print("음성 변환 실패")
                print("error=\(error)")
                return
            }
            
            print(result.bestTranscription.formattedString)
            if result.isFinal {
                self.resultTextView.text = result.bestTranscription.formattedString
            }
        }
    }
    
    func askPermission(completionHandler: @escaping (Bool) -> (Void)) {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    break
                default:
                    self?.recognizeButton.isEnabled = false
                }
            }
        }
    }
}

class SpeechDefaults {
    private static let fileId = "fileId"
    private static let fileURL = "fileURL"
    
    static let shared = SpeechDefaults()
    
    var fileId: Int {
        get {
            let ret = UserDefaults.standard.integer(forKey: SpeechDefaults.fileId)
            UserDefaults.standard.set(ret + 1, forKey: SpeechDefaults.fileId)
            return ret
        }
    }
    
    var fileURL: URL? {
        get {
            return UserDefaults.standard.url(forKey: SpeechDefaults.fileURL)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SpeechDefaults.fileURL)
        }
    }
}
