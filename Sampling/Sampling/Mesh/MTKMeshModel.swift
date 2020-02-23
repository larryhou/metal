//
//  MTKMeshModel.swift
//  Sampling
//
//  Created by LARRYHOU on 2020/2/22.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

import Foundation
import MetalKit

class MTKMeshModel: MeshModel
{
    var mdlMeshes: [MDLMesh] = []
    var mtkMeshes: [MTKMesh] = []
    
    func load(name:String, type: String, vertexDescriptor: MTLVertexDescriptor)
    {
        guard let bundle = self.bundle else {
            return
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
                return
            }
        }
    }
    
}
