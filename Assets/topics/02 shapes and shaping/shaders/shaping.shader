Shader "examples/week 2/shaping"
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
                float2 uv = i.uv;

                uv = uv*2 - 1; //expand coordinate space to 0-2 from 0-1 and then shift it over by 1.
                uv *= 4;
                
                float x = uv.x;
                float y = uv.y;

                float c = sin(x);
                c = cos(x);
                c = abs(x);
                c = ceil(x);
                c = floor(x);
                c = frac(x);
                c = smoothstep(0, 1, 1 - abs(min(x, y)));
                c = max(x, y);
                c = sign(x);
                c = step(x, y) * step(x, -2);
                uv.x = sin(uv.x);
                c = step(uv.x, y);
                c = smoothstep(-2, 2, x);

                return float4(c.rrr, 1.0);
            }
            ENDCG
        }
    }
}
