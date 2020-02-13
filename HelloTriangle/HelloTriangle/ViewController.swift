//
//  ViewController.swift
//  HelloTriangle
//
//  Created by LARRYHOU on 2020/2/13.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController
{
    var mtkView:MTKView!
    var renderer: MetalRenderer!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        guard let mtkView = self.view as? MTKView else { return }
        
        self.mtkView = mtkView
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        renderer = MetalRenderer(view: mtkView)
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
    }


}

