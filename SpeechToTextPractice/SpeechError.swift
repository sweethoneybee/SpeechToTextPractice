//
//  SpeechError.swift
//  SpeechToTextPractice
//
//  Created by 정성훈 on 2021/07/24.
//

import Foundation

enum SpeechError: Error {
    case test
}

/*
 
 1. partial 결과를 받으면서, 98초 동안 쉼없이 말했음. 잘 변환해주다가 중간에 에러 뱉음
 2021-07-24 23:18:04.615680+0900 SpeechToTextPractice[49499:5739564] [Utility] +[AFAggregator logDictationFailedWithError:] Error Domain=kAFAssistantErrorDomain Code=1107 "(null)"
 음성 변환 실패
 error=The operation couldn’t be completed. (kAFAssistantErrorDomain error 1107.)

 
 2. 아무 소리 없는 녹음파일을 넘김. 위와 동일한 에러가 뜸
 2021-07-24 23:19:42.496141+0900 SpeechToTextPractice[49499:5740535] [Utility] +[AFAggregator logDictationFailedWithError:] Error Domain=kAFAssistantErrorDomain Code=1110 "(null)"
 음성 변환 실패
 error=The operation couldn’t be completed. (kAFAssistantErrorDomain error 1110.)
 
 3. 로컬에 한국어 음성인식을 다운로드 받지 않은 경우는? (아이폰을 처음 받고, 와이파이를 한 번도 안키면 한국어팩을 다운받지 않음. 와이파이를 키면 자동으로 한국어팩을 받고 그 뒤로 온디바이스 음성인식 가능해짐)
 // 케이스 확인하기 어려움...
 
 */
