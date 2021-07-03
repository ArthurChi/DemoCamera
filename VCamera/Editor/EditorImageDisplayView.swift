//
//  EditorImageDisplayView.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/24.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit
import SnapKit

class EditorImageDisplayView: NiblessView {
    private var imageView: UIImageView
    
    init(image: UIImage) {
        imageView = UIImageView()
        super.init()
        
        addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.center.size.equalTo(self)
        }
        
        imageView.image = image
    }
}
