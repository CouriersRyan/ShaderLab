Shader "examples/week 2/pattern"
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
                float output = 0;
                int gridSize = 40;
                float2 uv = i.uv * gridSize;

                float time = _Time.y;
                
                float2 gridUV = frac(uv) * 2 - 1;

                float index = floor(uv.x) + floor(uv.y);
                gridUV.x += sin(time + index/3) * 0.5;
                gridUV.y += cos(time + index/3) * 0.5;
                output = step(0.7, 1-length(gridUV));
                //lerp(0.1, 0.6, sin(time)*0.5 + 0.5)
                
                
                //output = gridUV.x * gridUV.y;

                return float4(output.rrr, 1.0);
            }
            ENDCG
        }
    }
}
