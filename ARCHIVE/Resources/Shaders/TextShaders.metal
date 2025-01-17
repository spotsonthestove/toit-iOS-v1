#include <metal_stdlib>
using namespace metal;

struct TextVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct TextUniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4 color;
};

vertex TextVertexOut text_vertex_main(const device float3* vertices [[buffer(0)]],
                                    constant TextUniforms& uniforms [[buffer(1)]],
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

fragment float4 text_fragment_main(TextVertexOut in [[stage_in]],
                                 texture2d<float> texture [[texture(0)]],
                                 constant TextUniforms& uniforms [[buffer(1)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = texture.sample(textureSampler, in.texCoord);
    return color * uniforms.color;
} 