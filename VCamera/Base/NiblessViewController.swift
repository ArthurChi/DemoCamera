//
//  NiblessViewController.swift
//  VCamera
//
//  Created by VassilyChi on 2020/8/11.
//  Copyright © 2020 VassilyChi. All rights reserved.
//

import UIKit

class NiblessViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable, message: "Loading this view controller from a nib is unsupported")
    required init?(coder: NSCoder) {
        fatalError("Loading this view controller from a nib is unsupported")
    }
}
