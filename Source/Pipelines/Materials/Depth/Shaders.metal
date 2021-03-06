#include "../../Library/Map.metal"
#include "../../Library/Colors.metal"
#include "../../Library/Dither.metal"

typedef struct {
    float4 position [[position]];
    float depth;
} DepthVertexData;

vertex DepthVertexData depthVertex(Vertex v [[stage_in]],
                                   constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]],
                                   constant DepthUniforms &uniforms [[buffer(VertexBufferMaterialUniforms)]]) {
    const float4 position = vertexUniforms.modelViewMatrix * v.position;
    const float z = position.z;
    
    const float4x4 projection = vertexUniforms.projectionMatrix;
    const float a = projection[2].z;
    const float b = projection[3].z;
    
    const float aMinusOne = a - 1.0;
    const float aPlueOne = a + 1.0;
    const float n = ( b * aPlueOne / aMinusOne - b ) * 0.5;
    const float f = aMinusOne * n / aPlueOne;
    
    float near = uniforms.near;
    float far = uniforms.far;

    near = mix(n, near, saturate(sign(near)));
    far = mix(f, far, saturate(sign(far)));
        
    const float depth = map(-z, near, far, 1.0, 0.0);
    DepthVertexData out;
    out.position = projection * position;
    out.depth = depth;
    return out;
}

fragment float4 depthFragment(DepthVertexData in [[stage_in]],
                              constant DepthUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]]) {
    const float depth = uniforms.invert ? 1.0 - in.depth : in.depth;
    float3 color = uniforms.color ? turbo(depth) : float3(depth);
    color = dither8x8(in.position.xy, color);
    return float4(color, 1.0);
}
