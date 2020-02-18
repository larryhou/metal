//
//  ModelFile.swift
//  Sampling
//
//  Created by LARRYHOU on 2020/2/17.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

import Foundation

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
    var directs: UnsafeBufferPointer<T>?
    var indices: UnsafeBufferPointer<Int32>?
    
    init(mapping: MappingMode)
    {
        self.mapping = mapping
    }
    
    func set(directs: UnsafeBufferPointer<T>, indices: UnsafeBufferPointer<Int32>?)
    {
        self.directs = directs
        self.indices = indices
    }
}

struct MeshVertices
{
    let controlVertices: UnsafeBufferPointer<Float4>
    let polygonVertices: UnsafeBufferPointer<Int32>
}

class MeshFile
{
    let name: String
    let bundle: String?
    
    private var data: Data?
    private var address: UnsafeRawPointer?
    
    private(set) var tangents: VertexAttribute<Float4>?
    private(set) var normals: VertexAttribute<Float4>?
    private(set) var colors: VertexAttribute<Float4>?
    private(set) var uvs: VertexAttribute<Float2>?
    
    private(set) var triangles: UnsafeBufferPointer<Int32>?
    private(set) var vertices: MeshVertices?
    
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
        self.bundle = b
        self.name = name
        
        if let path = Bundle.main.path(forResource: b, ofType: "bundle")
        {
            if let target = Bundle(path: path)
            {
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
        
        let ptv = ptr.bindMemory(to: Float4.self, capacity: numVertices)
        let controlVertices = UnsafeBufferPointer<Float4>(start: ptv, count: numVertices);
        ptr += MemoryLayout<Float4>.stride * numVertices
        
        // triangles
        assert(ptr++.load(as: UInt8.self) == 84) // T
        pti = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numTriangles = Int(pti.pointee)
        ptr += 4
        
        self.triangles = UnsafeBufferPointer<Int32>(start: pti + 1, count: numTriangles * 3)
        ptr += MemoryLayout<Int32>.stride * numTriangles * 3
        
        // polygon vertices
        assert(ptr++.load(as: UInt8.self) == 80) // P
        pti = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numPolygonVertices = Int(pti.pointee)
        ptr += 4
        
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
            case 110: self.normals  = load(&ptr) // n: normals
            case 117: self.uvs      = load(&ptr) // u: uvs
            case 116: self.tangents = load(&ptr) // t: tangents
            case  99: self.colors   = load(&ptr) // c: colors
            default: break
            }
        }
    }
    
    private func load<T>(_ ptr: inout UnsafeRawPointer)->VertexAttribute<T>
    {
        // DirectArray
        assert(ptr++.load(as: UInt8.self) == 100) // d
        
        let mapping = MappingMode(rawValue: ptr++.load(as: UInt8.self))
        assert(mapping != nil)
        
        let attribute = VertexAttribute<T>(mapping: mapping!)
        
        var pti = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numValues = Int(pti.pointee)
        ptr += 4
        
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
            
            pti = ptr.bindMemory(to: Int32.self, capacity: numIndices)
            indices = UnsafeBufferPointer<Int32>(start: pti, count: numIndices)
            ptr += MemoryLayout<Int32>.stride * numIndices
        }
        attribute.set(directs: directs, indices: indices)
        return attribute
    }
    
}
