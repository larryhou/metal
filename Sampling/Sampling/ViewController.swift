//
//  ViewController.swift
//  Sampling
//
//  Created by LARRYHOU on 2020/2/17.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController
{
    var mtkView: MTKView?
    var renderer: MetalRenderer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        guard let mtkView = view as? MTKView else {return}
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        self.mtkView = mtkView
        
        if let device = mtkView.device
        {
            renderer = MetalRenderer(device: device, view: mtkView)
            mtkView.delegate = renderer
            
            renderer?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        }
    }

}

