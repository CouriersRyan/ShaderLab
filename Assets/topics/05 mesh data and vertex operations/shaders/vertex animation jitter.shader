Shader "examples/week 5/vertex animation jitter"
{
    Properties
    {
        _displacement ("displacement", Range(0, 0.1)) = 0.05
        _timeScale ("time scale", Float) = 1
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

            float _scale;
            float _displacement;
            float _timeScale;

            float rand (float2 uv) {
                return frac(sin(dot(uv.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }

            float rand_vec(float3 pos)
            {
                float3 r = normalize(float3(
                    rand(pos.xy),
                    rand(pos.yz),
                    rand(pos.zx)
                ) - 0.5);

                return r;
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
                float disp : TEXCOORD1;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;

                v.vertex.xyz += rand_vec(v.vertex.xyz + floor(_Time.y * _timeScale)) * _displacement;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                return float4(i.uv.x, 0, i.uv.y, 1.0);
            }
            ENDCG
        }
    }
}
