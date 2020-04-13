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
        Pomelo.run(file: "\(Bundle.main.path(forResource: "sample", ofType: "sp") ?? "")")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

