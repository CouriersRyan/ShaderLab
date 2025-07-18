﻿Shader "examples/week 7/blinn-phong"
{
    Properties 
    {
        _surfaceColor ("surface color", Color) = (0.4, 0.1, 0.9)
        _ambientColor ("ambient color", Color) = (0.4, 0.1, 0.9)
        _gloss ("gloss", Range(0,1)) = 1
    }
    SubShader
    {
        // this tag is required to use _LightColor0
        Tags { "LightMode"="ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // might be UnityLightingCommon.cginc for later versions of unity
            #include "Lighting.cginc"

            #define MAX_SPECULAR_POWER 512

            float3 _surfaceColor;
            float3 _ambientColor;
            float _gloss;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 posWorld : TEXCOORD1;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.normal = v.normal;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float3 color = 0;

                float3 normal = normalize(i.normal);
                
                float3 lightDirection = _WorldSpaceLightPos0;
                float3 lightColor = _LightColor0; // includes intensity


                float3 viewPosition = _WorldSpaceCameraPos.xyz;
                float3 viewDir = normalize(viewPosition - i.posWorld);
                
                float3 halfDir = normalize(viewDir + lightDirection);
                float specularFalloff = max(0, dot(normal, halfDir));
                specularFalloff = pow(specularFalloff, _gloss * MAX_SPECULAR_POWER + 0.00001) * _gloss;
                float3 specular = lightColor * specularFalloff;

                float diffuseFalloff = max(0, smoothstep(-0.1, 1, dot(normal, lightDirection)));
                float3 diffuse = diffuseFalloff * _surfaceColor * lightColor;

                float ambientFalloff = max(0, dot(normal, -lightDirection));
                float3 ambient = ambientFalloff * _surfaceColor * normal.xyz * 0.2;
                ambient = pow(ambient, 0.5) * 0.4;
                

                color = diffuse + specular + ambient;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
