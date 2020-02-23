//
//  MTKMeshModel.swift
//  Sampling
//
//  Created by LARRYHOU on 2020/2/22.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

import Foundation
import MetalKit

class MTKMeshModel
{
    let bundle:Bundle?
    let device:MTLDevice
    
    var mdlMeshes: [MDLMesh] = []
    var mtkMeshes: [MTKMesh] = []
    
    convenience init(device: MTLDevice)
    {
        self.init(bundle: Bundle.main, device: device)
    }
    
    convenience init(bundle:String, device: MTLDevice)
    {
        if let path = Bundle.main.path(forResource: bundle, ofType: "bundle")
        {
            self.init(bundle: Bundle(path: path), device: device)
        }
        else
        {
            self.init(bundle: nil, device: device)
        }
    }
    
    init(bundle:Bundle?, device: MTLDevice)
    {
        self.bundle = bundle
        self.device = device
    }
    
    func load(name:String, type: String, vertexDescriptor: MTLVertexDescriptor)->MTKMeshModel?
    {
        guard let bundle = self.bundle else {
            return nil
        }
        
        if let path = bundle.path(forResource: name, ofType: type)
        {
            let descriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
            if let attribute = descriptor.attributes[0] as? MDLVertexAttribute
            {
                attribute.name = MDLVertexAttributePosition
            }
            
            if let attribute = descriptor.attributes[1] as? MDLVertexAttribute
            {
                attribute.name = MDLVertexAttributeNormal
            }
            
            if let attribute = descriptor.attributes[2] as? MDLVertexAttribute
            {
                attribute.name = MDLVertexAttributeTextureCoordinate
            }
            
            let allocator = MTKMeshBufferAllocator(device: device)
            let asset = MDLAsset(url: URL(fileURLWithPath: path), vertexDescriptor: descriptor, bufferAllocator: allocator)
            
            if let (mdlMeshes, mtkMeshes) = try? MTKMesh.newMeshes(asset: asset, device: device)
            {
                self.mdlMeshes = mdlMeshes
                self.mtkMeshes = mtkMeshes
                return self
            }
        }
        
        return nil
    }
    
}
