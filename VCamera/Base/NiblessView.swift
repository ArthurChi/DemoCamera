//
//  NiblessView.swift
//  VCamera
//
//  Created by VassilyChi on 2020/1/3.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit

open class NiblessView: UIView {
    
    public init() {
        super.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @available(*, unavailable, message: "Loading this view from a nib is unsupported")
    public required init?(coder: NSCoder) {
        fatalError("Loading this view from a nib is unsupported")
    }
}
