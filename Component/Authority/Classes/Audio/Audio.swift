//
//  Audio.swift
//  Pods-VCamera
//
//  Created by VassilyChi on 2019/12/18.
//

import Foundation
import AVFoundation
import Combine

extension Authority {
    public struct Audio {
        public static var isAvaliable: Bool {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
        
        public func requestAuthority() -> AnyPublisher<Bool, Never> {
            
            Future<Bool, Never>.init { promise in
                AVCaptureDevice.requestAccess(for: .audio) { result in
                    promise(.success(result))
                }
            }
            .eraseToAnyPublisher()
        }
    }
}
