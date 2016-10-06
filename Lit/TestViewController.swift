//
//  TestViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    var picture: UIImage?
    
    @IBOutlet weak var pictureView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pictureView.image = picture
    }
    
}