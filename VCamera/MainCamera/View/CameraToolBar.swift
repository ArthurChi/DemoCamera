//
//  CameraToolBar.swift
//  VCamera
//
//  Created by VassilyChi on 2020/1/3.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import Combine
import CombineCocoa

enum CameraToolBarAction {
    case clickRatio
    case clickChangeCamera
}

final class CameraToolBar: NiblessView {
    
    private let clickedSubject = PassthroughSubject<CameraToolBarAction, Never>()
    public var clickeObservable: AnyPublisher<CameraToolBarAction, Never> { clickedSubject.eraseToAnyPublisher() }
    
    private var changeCameraButton: UIButton
    
    private var changeRatioButton: UIButton
    
    override init() {
        changeCameraButton = UIButton(type: .custom)
        changeRatioButton = UIButton(type: .custom)
        super.init(frame: .zero)
        
        setup()
    }
    
    private func setup() {
        
        addSubview(changeRatioButton)
        addSubview(changeCameraButton)
        
        changeCameraButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.right.equalToSuperview()
            maker.width.equalTo(44)
        }
        
        changeRatioButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview()
            maker.width.equalTo(44)
        }
        
        changeCameraButton.setImage(UIImage(named: "camera_ic_lens_w"), for: .normal)
        changeRatioButton.setImage(UIImage(named: "more_ic_full_b_n"), for: .normal)
        
        changeCameraButton
            .tapPublisher
            .map({ CameraToolBarAction.clickChangeCamera })
            .receive(subscriber: AnySubscriber(self.clickedSubject))
        
        changeRatioButton
            .tapPublisher
            .map({ CameraToolBarAction.clickRatio })
            .receive(subscriber: AnySubscriber(self.clickedSubject))
    }
}
