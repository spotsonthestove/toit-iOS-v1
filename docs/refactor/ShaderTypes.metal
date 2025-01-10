#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4 color;
};

#endif /* ShaderTypes_h */ 