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
    public struct Photo {
        public static var isAvaliable: Bool {
            return PHPhotoLibrary.authorizationStatus() == .authorized
        }
        
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
