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
    var task: SFSpeechRecognitionTask!
    
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
    
    @IBOutlet weak var currentId: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setIdLabel()
        
        title = "녹음 변환"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("뷰 사라질 것임")
        task.finish()
        print("테스크 취소!")
    }
    
    private func setIdLabel(newId: Int? = nil) {
        if let id = newId {
            currentId.text = "현재 \(id)까지"
        } else {
            let id = SpeechDefaults.shared.fileId
            currentId.text = "현재 \(id - 1)까지"
        }
    }
    // MARK: - RECORD
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
            
            let id = SpeechDefaults.shared.fileId
            setIdLabel(newId: id)
            SpeechDefaults.shared.fileId = id + 1
            
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
    
    // MARK:- Recognizer
    @IBAction func onSpeechToTextButton(_ sender: Any) {
        speechToText()
    }
    
    @IBAction func onIdButton(_ sender: Any) {
        guard let text = idTextField.text,
              let id = Int(text) else { return }
        speechToText(id: id)
    }
    
    func speechToText(id: Int? = nil) {
        if speechRecognizer == nil {
                speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier:"ko-KR"))
                speechRecognizer.queue.maxConcurrentOperationCount = 1
                print("리코그나이저 새로 할당")
        }
        
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
            let audioFile = try! AVAudioFile(forReading: url)
            let duration = Double(audioFile.duration)
            recordTimeLabel.text = String(format: "약 %.2f초", duration)
        } else {
            url = audioFileURL!
        }
        
        print("리퀘스트 할당")
        request = SFSpeechURLRecognitionRequest(url: url)
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        urlLabel.text = url.absoluteString
        var timeFlag = false
        
        print("테스크 시작") // 권한획득 안했어도 이때 물어봄. 반약 권한 거부하면 아래 요청은 fail뜸
        task = recognizer.recognitionTask(with: request) { result, error in
            if !timeFlag {
                self.conversionStartTime = Date()
                timeFlag = true
            }
            guard let result = result else {
                print("음성 변환 실패")
                print("error=\(String(describing: error?.localizedDescription))")
                self.caculateFinishTime()
                return
            }
            
            print(result.bestTranscription.formattedString)
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
        let conversionTime = Double(conversionFinishTime.timeIntervalSince(conversionStartTime))
        conversionTimeLabel.text = String(format: "%.2f 초 걸림", conversionTime)
    }
    
    // MARK:- keyboard
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

class SpeechDefaults {
    private static let fileId = "fileId"
    private static let fileURL = "fileURL"
    
    static let shared = SpeechDefaults()
    
    var fileId: Int {
        get {
            return UserDefaults.standard.integer(forKey: SpeechDefaults.fileId)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SpeechDefaults.fileId)
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


