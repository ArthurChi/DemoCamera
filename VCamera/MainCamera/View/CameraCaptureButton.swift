//
//  CameraCaptureButton.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/25.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import Combine
import CombineCocoa

class CameraCaptureButton: UIButton {
    enum Action {
        case tap
        case longPress(LongPressState)
    }
    
    enum LongPressState {
        case begin
        case end
    }
    
    private var actionSubject = PassthroughSubject<Action, Never>()
    public var actionPublisher: AnyPublisher<Action, Never> { return actionSubject.eraseToAnyPublisher() }
    
    private var longPressGes = UILongPressGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        longPressGes.minimumPressDuration = 1
        addGestureRecognizer(longPressGes)
        
        longPressGes.longPressPublisher
            .removeDuplicates { $0.state != $1.state }
            .filter { $0.state == .began || $0.state == .ended }
            .map { gesture -> CameraCaptureButton.LongPressState in
                if gesture.state == .began {
                    return .begin
                } else {
                    return .end
                }
            }
            .map { Action.longPress($0) }
            .receive(subscriber: AnySubscriber(actionSubject))
            

        self.controlEventPublisher(for: .touchUpInside)
            .map { Action.tap }
            .receive(subscriber: AnySubscriber(actionSubject))
    }
}
