Shader "examples/week 1/color blending"
{
    Properties
    {
        _color1 ("color one", Color) = (1, 0, 0, 1)
        _color2 ("color two", Color) = (0, 0, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform float3 _color1;
            uniform float3 _color2;
            
            float circle (float2 uv, float2 offset, float size) {
                return smoothstep(0.0, 0.005, 1 - length(uv - offset) / size);
            }

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

            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float3 base  = circle(uv, float2(0.0, -0.3), 0.5) * _color1;
                float3 blend = circle(uv, float2(0.0,  0.3), 0.5) * _color2;

                // commutative - order does not matter
                // non-commutative - order matters
                
                float3 color = 0.0;
                color = base + blend; // commutative / add
                color = blend - base; // non-commutative / subtract
                color = base * blend; // commutative / multiply
                color = base / blend; // non-commutative / divide
                color = min(base, blend); // commutative / darken
                color = 1 - (1-base) / blend; // non-commutative / color burn
                color = max(base, blend); // commutative / lighten
                color = abs(base - blend); // commutative / difference
                color = base <= 0.5 ? 2 * base * blend : 1 - 2 * (1 - base) * (1 - blend); // non-commutative / overlay
                color = lerp(base, blend, 0.5);
                color = base + blend - 1; // commutative / linear burn

                color = max((base + blend) * uv.x / 2, (1 - (1-base) / blend) * uv.x);
                color = color.r * color.g * color.b >= 1 ? 0 : color;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
