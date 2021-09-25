//
//  Photo.swift
//  Pods-VCamera
//
//  Created by VassilyChi on 2019/12/18.
//

import Foundation
import Photos
import Combine

extension Authority {
    /// 相册权限相关
    public struct Photo {
        /// 相册权限是否可用
        public static var isAvaliable: Bool {
            return PHPhotoLibrary.authorizationStatus() == .authorized
        }
        
        /// 请求相册权限
        /// - Returns: 请求权限的结果的publisher
        public static func requestAuthority() -> AnyPublisher<PHAuthorizationStatus, Never> {
            Future<PHAuthorizationStatus, Never>.init { promise in
                PHPhotoLibrary.requestAuthorization { (result) in
                    promise(.success(result))
                }
            }
            .eraseToAnyPublisher()
        }
    }
}
