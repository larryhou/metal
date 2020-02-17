//
//  shader.metal
//  HelloTriangle
//
//  Created by LARRYHOU on 2020/2/13.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float2 position;
    float4 color;
};

struct VertexOutput
{
    float4 position [[position]];
    float4 color;
};

vertex VertexOutput vert(uint vertex_id [[vertex_id]],
                         constant Vertex *vertices [[buffer(0)]],
                         constant float2 *viewport [[buffer(1)]])
{
    float2 position = vertices[vertex_id].position.xy;
    float2 vp = float2(*viewport);
    
    VertexOutput out;
    out.position = float4(0, 0, 0, 1);
    out.position.xy = position / (vp / 2.0);
    out.color = vertices[vertex_id].color;
    return out;
}

fragment float4 frag(VertexOutput in [[stage_in]])
{
    return in.color;
}
