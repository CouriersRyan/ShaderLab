Shader "examples/week 2/polar"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            #define TAU 6.283185

            float zigzag(float density, float height, float offset, float2 uv)
            {
                float shape = frac(uv.x * density);
                shape = min(shape, 1-shape) * uv.y;
                shape = smoothstep(0, 0.002, shape * height + offset - uv.y);
                return shape;
            }
            
            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;

                float2 polar = float2(atan2(uv.y, uv.x), length(uv));
                polar.y = frac(polar.y * 10);
                polar.x = frac(polar.x * 5);
                polar.x = (polar.x) / TAU + 0.5; // range from -PI to PI to -0.5 to 0.5 and then adding 0.5 to get the range 0 to 1.
                
                float output = 0;
                polar.x = frac(polar.x - _Time.x);
                output = zigzag(40, 0.4, 0.4, polar);
                
                return float4(output.rrr, 1.0);
            }
            ENDCG
        }
    }
}
