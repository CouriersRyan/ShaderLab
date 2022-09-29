Shader "examples/week 1/gradient exercise"
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
                float3 color = 0;

                // add your code here
                float3 colorA = float3(0.1, 0.8, 0.9);
                float3 colorB = float3(1, 0.3, 0.8);
                float3 colorC = float3(0.1, 0.8, 0.1);
                float3 colorD = float3(1, 1, 0);

                float radial = ((0.5 * 0.5) - abs((0.5 - uv.x)) * abs((0.5 - uv.y))) / (0.5 * 0.5);
                
                color = colorC * (uv.x * uv.y);
                color += colorA * ((1 - uv.x) * uv.y);
                color += colorB * (uv.x * (1 - uv.y));
                color += colorD * ((1 - uv.x) * (1 - uv.y));

                color = colorA * radial;
                color += colorB * (1 - radial);
                color = color + (uv.x + uv.y) * colorC / 4 - 1;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
