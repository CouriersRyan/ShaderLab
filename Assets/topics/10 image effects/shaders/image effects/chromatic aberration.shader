﻿Shader "examples/week 10/chromatic aberration"
{
    Properties
    {
        _MainTex ("render texture", 2D) = "white"{}
        _Intensity("intensity", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #define MAX_OFFSET 0.15

            sampler2D _MainTex;
            float _Intensity;

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
                float3 color = 0;
                float2 uv = i.uv;
                float offset = _Intensity * MAX_OFFSET;

                float r = tex2D(_MainTex, uv + offset).r;
                float g = tex2D(_MainTex, uv).g;
                float b = tex2D(_MainTex, uv  - offset).b;

                return float4(r, g, b, 1.0);
            }
            ENDCG
        }
    }
}
