Shader "examples/week 4/white noise"
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
                float wn = 0;

                uv = floor(uv * 256); // Changes noise resolution.
                float seed = dot(uv, float2(128.3434, -89.56));
                wn = frac(sin(seed) * 90030);

                return float4(wn.rrr, 1.0);
            }
            ENDCG
        }
    }
}
