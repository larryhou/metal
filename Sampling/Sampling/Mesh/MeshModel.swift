//
//  ModelFile.swift
//  Sampling
//
//  Created by LARRYHOU on 2020/2/17.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

import Foundation
import MetalKit

extension UnsafeRawPointer
{
    static prefix func ++(p: inout UnsafeRawPointer)-> UnsafeRawPointer
    {
        p += 1
        return p
    }
    
    static postfix func ++(p: inout UnsafeRawPointer)-> UnsafeRawPointer
    {
        p += 1
        return p - 1
    }
}

enum MappingMode: UInt8
{
    case none = 0, byControlVertex, byPolygonVertex, byPolygon, byEdge, same
}

class VertexAttribute<T>
{
    let mapping: MappingMode
    private(set) var directs: UnsafeBufferPointer<T>?
    private(set) var indices: UnsafeBufferPointer<Int32>?
    
    // extend for metal
    private(set) var controls: UnsafeMutableBufferPointer<T>?
    
    init(mapping: MappingMode)
    {
        self.mapping = mapping
    }
    
    func set(directs: UnsafeBufferPointer<T>, indices: UnsafeBufferPointer<Int32>?)
    {
        self.directs = directs
        self.indices = indices
    }
    
    func set(controls: UnsafeMutableBufferPointer<T>)
    {
        self.controls = controls
    }
    
    deinit
    {
        controls?.deallocate()
    }
}

struct MeshVertices
{
    let controlVertices: UnsafeBufferPointer<Float4>
    let polygonVertices: UnsafeBufferPointer<Int32>
}

class MeshModel
{
    let name: String
    var bundle: Bundle?
    
    private var data: Data?
    private var address: UnsafeRawPointer?
    
    private(set) var tangents: VertexAttribute<Float4>?
    private(set) var normals: VertexAttribute<Float4>?
    private(set) var colors: VertexAttribute<Float4>?
    private(set) var uvs: VertexAttribute<Float2>?
    
    private(set) var triangles: UnsafeBufferPointer<Int32>?
    private(set) var vertices: MeshVertices?
    
    // extend for metal
    private(set) var indexing: UnsafeMutableBufferPointer<Int16>?
    
    deinit
    {
        indexing?.deallocate()
    }
    
    init(name: String)
    {
        self.name = name
        self.bundle = nil
        if let path = Bundle.main.path(forResource: name, ofType: "mesh")
        {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path))
            {
                self.data = data
                data.withUnsafeBytes { self.address = $0.baseAddress }
            }
        }
        
        load()
    }
    
    init(bundle b: String, name: String)
    {
        self.name = name
        if let path = Bundle.main.path(forResource: b, ofType: "bundle")
        {
            if let target = Bundle(path: path)
            {
                self.bundle = target
                if let asset = target.path(forResource: name, ofType: "mesh")
                {
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: asset))
                    {
                        self.data = data
                        data.withUnsafeBytes { self.address = $0.baseAddress }
                    }
                }
            }
        }
        
        load()
    }
    
    func getAssetURL(name: String, type:String)->URL?
    {
        let bundle: Bundle = self.bundle ?? Bundle.main
        if let asset = bundle.path(forResource: name, ofType: type)
        {
            return URL(fileURLWithPath: asset)
        }
        
        return nil
    }
    
    func loadTexture(device: MTLDevice, name: String)->MTLTexture?
    {
        let loader = MTKTextureLoader(device: device)
        if let url = getAssetURL(name: name, type: "png")
        {
            return try? loader.newTexture(URL: url, options: [:])
        }
        return nil
    }
    
    private func align(_ ptr:inout UnsafeRawPointer, base:UnsafeRawPointer, size: Int = 8)
    {
        let position = ptr - base
        let mode = position % size
        if mode != 0
        {
            ptr += size - mode
        }
    }
    
    private func load()
    {
        guard let data = self.data, let address = self.address else {return}
        
        var ptr = address
        assert(ptr++.load(as: UInt8.self) == 77) // M
        assert(ptr++.load(as: UInt8.self) == 69) // E
        assert(ptr++.load(as: UInt8.self) == 83) // S
        assert(ptr++.load(as: UInt8.self) == 72) // H
        
        // control vertices
        assert(ptr++.load(as: UInt8.self) == 86) // V
        var pti = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numVertices = Int(pti.pointee)
        ptr += 4
        
        align(&ptr, base: address)
        let ptv = ptr.bindMemory(to: Float4.self, capacity: numVertices)
        let controlVertices = UnsafeBufferPointer<Float4>(start: ptv, count: numVertices);
        ptr += MemoryLayout<Float4>.stride * numVertices
        
        // triangles
        assert(ptr++.load(as: UInt8.self) == 84) // T
        pti = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numTriangles = Int(pti.pointee)
        ptr += 4
        
        align(&ptr, base: address)
        pti = ptr.bindMemory(to: Int32.self, capacity: numTriangles * 3)
        self.triangles = UnsafeBufferPointer<Int32>(start: pti, count: numTriangles * 3)
        ptr += MemoryLayout<Int32>.stride * numTriangles * 3
        
        // polygon vertices
        assert(ptr++.load(as: UInt8.self) == 80) // P
        pti = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numPolygonVertices = Int(pti.pointee)
        ptr += 4
        
        align(&ptr, base: address)
        pti = ptr.bindMemory(to: Int32.self, capacity: numPolygonVertices)
        let polygonVertices = UnsafeBufferPointer<Int32>(start: pti, count: numPolygonVertices)
        self.vertices = MeshVertices(controlVertices: controlVertices, polygonVertices: polygonVertices)
        ptr += MemoryLayout<Int32>.stride * numPolygonVertices;
        
        assert(ptr++.load(as: UInt8.self) == 90) // Z
        
        // vertex properties
        let stop = address + data.count
        while ptr < stop
        {
            let type = ptr++.load(as: UInt8.self)
            switch type {
            case 110: self.normals  = load(&ptr, base: address) // n: normals
            case 117: self.uvs      = load(&ptr, base: address) // u: uvs
            case 116: self.tangents = load(&ptr, base: address) // t: tangents
            case  99: self.colors   = load(&ptr, base: address) // c: colors
            default: break
            }
        }
        
        convert(self.vertices!, attribute: self.uvs)
        convert(self.vertices!, attribute: self.colors)
        
        // index buffer
        if let triangles = self.triangles, let polygonVertices = self.vertices?.polygonVertices
        {
            let buffer = UnsafeMutableBufferPointer<Int16>.allocate(capacity: triangles.count)
            for n in 0..<triangles.count
            {
                let index = polygonVertices[Int(triangles[n])]
                buffer[n] = Int16(index)
            }
            self.indexing = buffer
        }
    }
    
    private func convert<T>(_ vertices: MeshVertices, attribute: VertexAttribute<T>?)
    {
        guard let attribute = attribute,
            let indices = attribute.indices,
            let directs = attribute.directs,
            attribute.mapping == .byPolygonVertex else { return }
        let buffer = UnsafeMutableBufferPointer<T>.allocate(capacity: vertices.controlVertices.count)
        attribute.set(controls: buffer)
        for i in 0..<indices.count
        {
            let offset = Int(vertices.polygonVertices[i])
            buffer[offset] = directs[Int(indices[i])]
        }
    }
    
    private func load<T>(_ ptr: inout UnsafeRawPointer, base address: UnsafeRawPointer)->VertexAttribute<T>
    {
        // DirectArray
        assert(ptr++.load(as: UInt8.self) == 100) // d
        let mapping = MappingMode(rawValue: ptr++.load(as: UInt8.self))
        assert(mapping != nil)
        
        let attribute = VertexAttribute<T>(mapping: mapping!)
        
        var pti = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numValues = Int(pti.pointee)
        ptr += 4
        
        align(&ptr, base: address)
        let ptv = ptr.bindMemory(to: T.self, capacity: numValues)
        let directs = UnsafeBufferPointer<T>(start: ptv, count: numValues)
        ptr += MemoryLayout<T>.stride * numValues
        
        var indices: UnsafeBufferPointer<Int32>?
        if (ptr++.load(as: UInt8.self) != 0)
        {
            // IndexArray
            assert(ptr++.load(as: UInt8.self) == 105) // i
            pti = ptr.bindMemory(to: Int32.self, capacity: 1)
            let numIndices = Int(pti.pointee)
            ptr += 4
            
            align(&ptr, base: address)
            pti = ptr.bindMemory(to: Int32.self, capacity: numIndices)
            indices = UnsafeBufferPointer<Int32>(start: pti, count: numIndices)
            ptr += MemoryLayout<Int32>.stride * numIndices
        }
        attribute.set(directs: directs, indices: indices)
        return attribute
    }
    
}
