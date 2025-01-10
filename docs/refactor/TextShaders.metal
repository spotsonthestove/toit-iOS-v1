#include "ShaderTypes.metal"
using namespace metal;

// Text shader output structure
struct TextVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Text vertex shader
vertex TextVertexOut texturedTextVertexShader(const device float3* vertices [[buffer(0)]],
                                    constant Uniforms& uniforms [[buffer(1)]],
                                    uint vid [[vertex_id]]) {
    TextVertexOut out;
    float4 position = float4(vertices[vid], 1.0);
    float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
    out.position = mvp * position;
    
    // Calculate texture coordinates
    out.texCoord = float2((vertices[vid].x + 1.0) * 0.5,
                         (1.0 - vertices[vid].y) * 0.5);
    return out;
}

// Text fragment shader
fragment float4 texturedTextFragmentShader(TextVertexOut in [[stage_in]],
                                 texture2d<float> texture [[texture(0)]],
                                 constant Uniforms& uniforms [[buffer(1)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = texture.sample(textureSampler, in.texCoord);
    return color * uniforms.color;
} 