//
//  Renderer.swift
//  HelloTriangle
//
//  Created by LARRYHOU on 2020/2/13.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

import MetalKit
import simd

typealias Float2 = SIMD2<Float>
typealias Float3 = SIMD4<Float>
typealias Float4 = SIMD4<Float>

struct Vertex
{
    var position:Float2
    var color:Float4
}

var vertices:[Vertex] = {
   return [
    Vertex(position: Float2( 250, -250), color: Float4(1, 0, 0, 1)),
    Vertex(position: Float2(-250, -250), color: Float4(0, 1, 0, 1)),
    Vertex(position: Float2(   0,  250), color: Float4(0, 0, 1, 1)),
    Vertex(position: Float2( 250,  250), color: Float4(0, 1, 1, 1)),
    ]
}()

class MetalRenderer: NSObject, MTKViewDelegate
{
    var device: MTLDevice?
    var pipelineState: MTLRenderPipelineState?
    var commandQueue: MTLCommandQueue?
    var model: MeshModel?
    
    var viewport = Float2()
    
    init(view: MTKView)
    {
        device = view.device
        
        let library = device?.makeDefaultLibrary()
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "MTLRenderPipelineDescriptor"
        descriptor.vertexFunction = library?.makeFunction(name: "vert")
        descriptor.fragmentFunction = library?.makeFunction(name: "frag")
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        pipelineState = try? device?.makeRenderPipelineState(descriptor: descriptor)
        commandQueue = device?.makeCommandQueue()
        
        model = MeshModel(bundle: "Piggy", name: "cloth")
        super.init()
        
        assert(pipelineState != nil)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        viewport.x = Float(size.width)
        viewport.y = Float(size.height)
    }
    
    func draw(in view: MTKView)
    {
        guard
            let pipelineState = pipelineState,
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        commandBuffer.label = "MTLCommandBuffer"
        
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        {
            commandEncoder.label = "MTLRenderCommandEncoder"
            commandEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewport.x), height: Double(viewport.y), znear: 0, zfar: 1))
            commandEncoder.setRenderPipelineState(pipelineState)
            
            if let vertices = model?.vertices
            {
                
            }
            
            commandEncoder.setVertexBytes(&vertices, length: MemoryLayout<Vertex>.stride * vertices.count, index: 0)
            commandEncoder.setVertexBytes(&viewport, length: MemoryLayout<Float2>.stride, index: 1)
            
            commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
            commandEncoder.endEncoding()
        }
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
}
