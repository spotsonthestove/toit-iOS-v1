#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
};

struct TestUniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 normalMatrix;
    float4 color;
    float3 lightPosition;
};

vertex VertexOut vertex_main(Vertex in [[stage_in]],
                           constant TestUniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    
    // Calculate world position
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
    out.worldPosition = worldPosition.xyz;
    
    // Calculate final position
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition;
    
    // Transform normal to world space
    float3x3 normalMatrix = float3x3(uniforms.modelMatrix[0].xyz,
                                   uniforms.modelMatrix[1].xyz,
                                   uniforms.modelMatrix[2].xyz);
    out.normal = normalize(normalMatrix * in.normal);
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                            constant TestUniforms &uniforms [[buffer(1)]]) {
    // Lighting calculations
    float3 normal = normalize(in.normal);
    float3 lightDirection = normalize(uniforms.lightPosition - in.worldPosition);
    
    // Ambient lighting
    float3 ambient = float3(0.2);
    
    // Diffuse lighting
    float diffuseStrength = max(dot(normal, lightDirection), 0.0);
    float3 diffuse = float3(diffuseStrength);
    
    // Combine lighting
    float3 lighting = ambient + diffuse;
    float3 color = uniforms.color.rgb * lighting;
    
    return float4(color, uniforms.color.a);
} 