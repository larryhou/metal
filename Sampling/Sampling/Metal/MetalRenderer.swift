//
//  Renderer.swift
//  HelloTriangle
//
//  Created by LARRYHOU on 2020/2/13.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//
import Foundation
import MetalKit
import simd

typealias Float2 = SIMD2<Float>
typealias Float3 = SIMD3<Float>
typealias Float4 = SIMD4<Float>

protocol MetalRendererDelegate
{
    func prepare(_ r: MetalRenderer)
    func createVertexDescriptor(_ r: MetalRenderer)->MTLVertexDescriptor
    func createDepthStencilState(_ r: MetalRenderer)->MTLDepthStencilState?
    func encodeCommands(_ r: MetalRenderer, encoder:MTLRenderCommandEncoder);
}

class MetalRenderer: NSObject
{
    var device: MTLDevice
    var pipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    var samplerState: MTLSamplerState?
    var commandQueue: MTLCommandQueue?
    var model: MeshModel?
    var mtkModel: MTKMeshModel?
    var texture: MTLTexture?
    
    var delegate: MetalRendererDelegate?
    
    let camera = ArcballCamera()
    var uniforms = MetalUniforms()
    
    var viewport = Float2()
    
    init(device: MTLDevice, view:MTKView)
    {
        self.device = device
        self.delegate = RenderCase1()
        super.init()
        
        if let library = device.makeDefaultLibrary()
        {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.label = "MTLRenderPipelineDescriptor"
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.vertexFunction = library.makeFunction(name: "vert")
            descriptor.fragmentFunction = library.makeFunction(name: "frag")
            descriptor.vertexDescriptor = delegate?.createVertexDescriptor(self)
            descriptor.depthAttachmentPixelFormat = .depth32Float
            pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor)
        }
        
        view.depthStencilPixelFormat = .depth32Float
        
        commandQueue = device.makeCommandQueue()
        
        camera.target = [0, 0.8, 0]
        camera.distance = 4
        
        model = MeshModel(bundle: "Punching", name: "body")
        mtkModel = MTKMeshModel(bundle:"Punching", device: device).load(name: "body", type: "obj", vertexDescriptor: delegate!.createVertexDescriptor(self))
        texture = model?.loadTexture(device: device, name: "diffuse")
        
        samplerState = createSamplerState()
        depthStencilState = delegate?.createDepthStencilState(self)
        
        assert(pipelineState != nil)
        self.delegate?.prepare(self)
    }
    
    func createSamplerState()->MTLSamplerState?
    {
        let descriptor = MTLSamplerDescriptor()
        descriptor.magFilter = .nearest
        descriptor.minFilter = .nearest
        return device.makeSamplerState(descriptor: descriptor)
    }
}

extension MTLRenderCommandEncoder
{
    func setVertexBuffer<T>(_ data: UnsafeBufferPointer<T>?, offset:Int, index:Int)
    {
        var buffer: MTLBuffer?
        if let data = data
        {
            buffer = device.makeBuffer(bytes: data.baseAddress!, length: MemoryLayout<T>.stride * data.count, options: [])
        }
        
        setVertexBuffer(buffer, offset: offset, index: index)
    }
    
    func setVertexBuffer<T>(_ data: UnsafeMutableBufferPointer<T>?, offset:Int, index:Int)
    {
        var buffer:MTLBuffer?
        if let data = data
        {
            buffer = device.makeBuffer(bytes: data.baseAddress!, length: MemoryLayout<T>.stride * data.count, options: [])
        }
        setVertexBuffer(buffer, offset: offset, index: index)
    }
}

class RenderCase2: MetalRendererDelegate
{
    func prepare(_ r: MetalRenderer)
    {
        
    }
    
    func createVertexDescriptor(_ r: MetalRenderer) -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[0].offset = 0
        
        descriptor.attributes[1].format = .float3
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[1].offset = MemoryLayout<Float3>.stride
        
        descriptor.attributes[2].format = .float2
        descriptor.attributes[2].bufferIndex = 0
        descriptor.attributes[2].offset = MemoryLayout<Float3>.stride * 2
        
        descriptor.layouts[0].stride = MemoryLayout<Float3>.stride * 2 + MemoryLayout<Float2>.stride
        
        return descriptor
    }
    
    func createDepthStencilState(_ r: MetalRenderer)->MTLDepthStencilState?
    {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return r.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    func encodeCommands(_ r: MetalRenderer, encoder: MTLRenderCommandEncoder)
    {
        if let mtkMesh = r.mtkModel?.mtkMeshes.first,
            let vertices = mtkMesh.vertexBuffers.first?.buffer,
            let submesh = mtkMesh.submeshes.first
        {
            var transform = Transform()
            transform.rotation.y = Float.pi
            
            r.uniforms.model = transform.matrix
            r.uniforms.view = r.camera.viewMatrix
            r.uniforms.projection = r.camera.projectionMatrix
            
            encoder.setVertexBuffer(vertices, offset: 0, index: 0)
            encoder.setVertexBytes(&r.uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 10)
            
            encoder.setFragmentTexture(r.texture, index: 0)
            encoder.setFragmentSamplerState(r.samplerState, index: 0)
            
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
    }
}

class RenderCase1: MetalRendererDelegate
{
    func prepare(_ r: MetalRenderer)
    {
        if let uvs = r.model?.uvs?.controls, var iter = uvs.baseAddress
        {
            for _ in 0..<uvs.count
            {
                iter.pointee.y = 1 - iter.pointee.y
                iter += 1
            }
        }
    }
    
    func createVertexDescriptor(_ r: MetalRenderer) -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[0].offset = 0
        
        descriptor.attributes[1].format = .float3
        descriptor.attributes[1].bufferIndex = 1
        descriptor.attributes[1].offset = 0
        
        descriptor.attributes[2].format = .float2
        descriptor.attributes[2].bufferIndex = 2
        descriptor.attributes[2].offset = 0
        
        descriptor.layouts[0].stride = MemoryLayout<Float3>.stride
        descriptor.layouts[1].stride = MemoryLayout<Float3>.stride
        descriptor.layouts[2].stride = MemoryLayout<Float2>.stride
        
        return descriptor
    }
    
    func createDepthStencilState(_ renderer: MetalRenderer)->MTLDepthStencilState?
    {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    func encodeCommands(_ r: MetalRenderer, encoder: MTLRenderCommandEncoder)
    {
        if let model = r.model, let vertices = model.vertices?.controlVertices, let indices = model.indexing
        {
            var transform = Transform()
            transform.rotation.y = Float.pi
            
            r.uniforms.model = transform.matrix
            r.uniforms.view = r.camera.viewMatrix
            r.uniforms.projection = r.camera.projectionMatrix
            
            encoder.setVertexBuffer(vertices, offset: 0, index: 0)
            encoder.setVertexBuffer(model.normals?.directs, offset: 0, index: 1)
            encoder.setVertexBuffer(model.uvs?.controls, offset: 0, index: 2)
            encoder.setVertexBytes(&r.uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 10)
            
            encoder.setFragmentTexture(r.texture, index: 0)
            encoder.setFragmentSamplerState(r.samplerState, index: 0)
            
            if let buffer = r.device.makeBuffer(bytes: indices.baseAddress!, length: MemoryLayout<Int16>.stride * indices.count)
            {
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: buffer, indexBufferOffset: 0)
            }
        }
    }
}

extension MetalRenderer : MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        camera.aspect = Float(size.width / size.height)
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
        
        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        {
            encoder.label = "MTLRenderCommandEncoder"
            encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewport.x), height: Double(viewport.y), znear: 0, zfar: 1))
            encoder.setRenderPipelineState(pipelineState)
            encoder.setDepthStencilState(depthStencilState)
            delegate?.encodeCommands(self, encoder: encoder)
            encoder.endEncoding()
        }
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
