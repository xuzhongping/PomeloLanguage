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
        PLDebugPrint("111")
//        Pomelo.run(file: "sample")
        Command().run()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

