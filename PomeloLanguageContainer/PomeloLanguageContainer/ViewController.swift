//
//  ViewController.swift
//  PomeloLanguageContainer
//
//  Created by xuzhongping on 2020/3/26.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Pomelo.run(file: "/Users/xuzhongping/Desktop/work/MyGithub/PomeloLanguage/PomeloLanguage/sample.sp")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

