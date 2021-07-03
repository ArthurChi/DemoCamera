//
//  Shaders.metal
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 28/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex vertexShader(const device float4 *pPosition  [[ buffer(0) ]],
                                         const device float2 *tPosition  [[ buffer(1) ]],
                                         constant float4x4 &uniforms [[buffer(2)]],
                                         unsigned int vertex_id [[ vertex_id ]]
                                         ) {
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = uniforms * float4(pPosition[vertex_id]);
    outVertex.textureCoordinate = tPosition[vertex_id];
    
    return outVertex;
}

fragment half4 samplingShader(TextureMappingVertex mappingVertex [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    return half4(texture.sample(s, mappingVertex.textureCoordinate));
}

