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

class ModelFile
{
    let name: String
    
    private var data: Data?
    private var address: UnsafeRawPointer?
    
    private(set) var tangents: (UnsafeBufferPointer<Double4>, UnsafeBufferPointer<Int32>?)?
    private(set) var normals: (UnsafeBufferPointer<Double4>, UnsafeBufferPointer<Int32>?)?
    private(set) var colors: (UnsafeBufferPointer<Double4>, UnsafeBufferPointer<Int32>?)?
    private(set) var uvs: (UnsafeBufferPointer<Double2>, UnsafeBufferPointer<Int32>?)?
    
    private(set) var triangles: UnsafeBufferPointer<Int32>?
    private(set) var vertices: (UnsafeBufferPointer<Double4>, UnsafeBufferPointer<Int32>)?
    
    init(name: String)
    {
        self.name = name
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
        var pi = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numVertices = Int(pi.pointee)
        ptr += 4
        
        let pv = ptr.bindMemory(to: Double4.self, capacity: numVertices)
        let controlVertices = UnsafeBufferPointer<Double4>(start: pv, count: numVertices);
        ptr += MemoryLayout<Double4>.stride * numVertices
        
        // triangles
        assert(ptr++.load(as: UInt8.self) == 84) // T
        pi = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numTriangles = Int(pi.pointee)
        ptr += 4
        
        self.triangles = UnsafeBufferPointer<Int32>(start: pi + 1, count: numTriangles * 3)
        ptr += MemoryLayout<Int32>.stride * numTriangles * 3
        
        // polygon vertices
        assert(ptr++.load(as: UInt8.self) == 80) // P
        pi = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numPolygonVertices = Int(pi.pointee)
        ptr += 4
        
        pi = ptr.bindMemory(to: Int32.self, capacity: numPolygonVertices)
        let polygonVertices = UnsafeBufferPointer<Int32>(start: pi, count: numPolygonVertices)
        self.vertices = (controlVertices, polygonVertices)
        ptr += MemoryLayout<Int32>.stride * numPolygonVertices;
        
        assert(ptr++.load(as: UInt8.self) == 90) // Z
        
        // vertex properties
        let stop = address + data.count
        while ptr < stop
        {
            let code = ptr++.load(as: UInt8.self)
            switch code {
            case 110: self.normals  = load(&ptr) // n: normals
            case 117: self.uvs      = load(&ptr) // u: uvs
            case 116: self.tangents = load(&ptr) // t: tangents
            case  99: self.colors   = load(&ptr) // c: colors
            default: break
            }
        }
    }
    
    private func load<T>(_ ptr: inout UnsafeRawPointer)->(UnsafeBufferPointer<T>, UnsafeBufferPointer<Int32>?)
    {
        // DirectArray
        assert(ptr++.load(as: UInt8.self) == 100) // d
        
        var pi = ptr.bindMemory(to: Int32.self, capacity: 1)
        let numValues = Int(pi.pointee)
        ptr += 4
        
        let pv = ptr.bindMemory(to: T.self, capacity: numValues)
        let values = UnsafeBufferPointer<T>(start: pv, count: numValues)
        ptr += MemoryLayout<T>.stride * numValues
        
        var indices: UnsafeBufferPointer<Int32>?
        if (ptr++.load(as: UInt8.self) != 0)
        {
            // IndexArray
            assert(ptr++.load(as: UInt8.self) == 105) // i
            pi = ptr.bindMemory(to: Int32.self, capacity: 1)
            let numIndices = Int(pi.pointee)
            ptr += 4
            
            pi = ptr.bindMemory(to: Int32.self, capacity: numIndices)
            indices = UnsafeBufferPointer<Int32>(start: pi, count: numIndices)
            ptr += MemoryLayout<Int32>.stride * numIndices
        }
        
        return (values, indices)
    }
    
}
