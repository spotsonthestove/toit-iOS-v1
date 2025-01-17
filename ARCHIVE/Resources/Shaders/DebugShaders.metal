#include <metal_stdlib>
using namespace metal;

struct DebugLineVertex {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct DebugLineOut {
    float4 position [[position]];
    float4 color;
};

vertex DebugLineOut debug_line_vertex(DebugLineVertex in [[stage_in]],
                                    constant float4x4 &viewMatrix [[buffer(1)]],
                                    constant float4x4 &projectionMatrix [[buffer(2)]]) {
    DebugLineOut out;
    
    float4 worldPosition = float4(in.position, 1.0);
    float4 viewPosition = viewMatrix * worldPosition;
    out.position = projectionMatrix * viewPosition;
    out.color = in.color;
    
    return out;
}

fragment float4 debug_line_fragment(DebugLineOut in [[stage_in]]) {
    return in.color;
} 