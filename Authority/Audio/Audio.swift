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
    /// 声音权限相关
    public struct Audio {
        /// 声音权限是否可用
        public static var isAvaliable: Bool {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
        
        /// 请求声音权限
        /// - Returns: 返回请求结果的publisher
        public static func requestAuthority() -> AnyPublisher<Bool, AuthorityError> {
            Future<Bool, AuthorityError>.init { promise in
                AVCaptureDevice.requestAccess(for: .audio) { result in
                    if result {
                        promise(.success(result))
                    } else {
                        promise(.failure(AuthorityError.accessDeny))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
    }
}
