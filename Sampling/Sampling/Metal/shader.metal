//
//  shader.metal
//  HelloTriangle
//
//  Created by LARRYHOU on 2020/2/13.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

#include <metal_stdlib>
#import "common.h"

using namespace metal;

struct Vertex
{
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct VertexOutput
{
    float4 position [[position]];
    float4 worldPosition;
    float4 worldNormal;
    float4 color;
    float2 uv;
};

vertex VertexOutput vert(Vertex data [[stage_in]],
                         constant MetalUniforms &uniforms [[buffer(10)]])
{
    VertexOutput out;
    out.position = uniforms.projection * uniforms.view * uniforms.model * data.position;
    out.worldPosition = uniforms.model * data.position;
    out.worldNormal = uniforms.model * data.normal;
    out.uv = data.uv;
    return out;
}

fragment float4 frag(VertexOutput in [[stage_in]],
                     texture2d<float> texture [[texture(0)]],
                     sampler sampler2d [[sampler(0)]])
{
    return texture.sample(sampler2d, in.uv) * 3;
}
