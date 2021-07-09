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
    
    private var conversionStartTime: Date!
    private var conversionFinishTime: Date!
    private var recordStartTime: Date!
    private var recordFinishTime: Date!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recognizeButton: UIButton!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var resultTextView: UITextView!
    
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var conversionTimeLabel: UILabel!
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
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 12000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                        ]
                        
                        do {
                            self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL, settings: settings)
                            self.audioRecorder.delegate = self
                            self.audioRecorder.record()
                            self.recordStartTime = Date()
                            
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
            recordFinishTime = Date()
            var recordTime = Double(recordFinishTime.timeIntervalSince(recordStartTime))
            recordTime = recordTime - recordTime.truncatingRemainder(dividingBy: 0.01)
            recordTimeLabel.text = "\(recordTime)초 녹음"
            
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
        speechToText()
    }
    
    @IBAction func onIdButton(_ sender: Any) {
        guard let text = idTextField.text,
              let id = Int(text) else { return }
        speechToText(id: id)
    }
    
    func speechToText(id: Int? = nil) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier:"ko-KR"))
        guard let recognizer = speechRecognizer else {
            print("지원하지 않는 로케일입니다")
            return
        }
        
        if !recognizer.isAvailable {
            print("현재 사용가능하지 않습니다")
            return
        }
        
        var url: URL!
        var request: SFSpeechURLRecognitionRequest!
        if let id = id {
            url = self.getDocumentsDirectory().appendingPathComponent("recording_\(id).m4a")
        } else {
            url = audioFileURL!
        }
        
        request = SFSpeechURLRecognitionRequest(url: url)
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        urlLabel.text = url.absoluteString
        
        conversionStartTime = Date()
        recognizer.recognitionTask(with: request) { result, error in
            guard let result = result else {
                print("음성 변환 실패")
                print("error=\(error)")
                self.caculateFinishTime()
                return
            }
            
            if result.isFinal {
                self.caculateFinishTime()
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
    
    func caculateFinishTime() {
        conversionFinishTime = Date()
        var conversionTime = Double(conversionFinishTime.timeIntervalSince(conversionStartTime))
        conversionTime = conversionTime - conversionTime.truncatingRemainder(dividingBy: 0.01)
        conversionTimeLabel.text = "\(conversionTime) 초 걸림"
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
