Shader "examples/week 2/shapes"
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

            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float shape = 0;
                float cutoff = 0.1;
                float edge = 0.01;  
                shape = step(cutoff, 1-length(uv));
                shape = smoothstep(cutoff - edge, cutoff + edge, 1-length(uv));

                float time = _Time.y;
                
                float2 size1 = float2(0.3, 0.7);
                float2 size0 = float2(0.9, 0.1);
                float2 size = lerp(size0, size1, sin(time)*0.5 + 0.5);
                float2 translate = float2(-0.5, 0);
                float2 center = lerp(float2(0, 0), translate, sin(time)*0.5 + 0.5);
                
                float2 shaper = float2(step(-size.x + center.x, uv.x), step(-size.y + center.y, uv.y));
                shaper *= float2(1-step(size.x + center.x, uv.x), 1-step(size.y + center.y, uv.y));
                shape = shaper.x * shaper.y;
                float b = shape * step(uv.y, sin((uv.x * 4) + time));
                float g =  shape * step(cutoff, 1-length(uv - sin((uv.x * 4) + time * 4)));

                return float4(shape.r, g, b, 1.0);
            }
            ENDCG
        }
    }
}
