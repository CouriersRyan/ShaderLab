Shader "Custom/mangaObjectBlinnPhong"
{
    Properties 
    {
        _surfaceColor ("surface color", Color) = (0.4, 0.1, 0.9)
        _gloss ("gloss", Range(0,1)) = 1
        _ambientColor ("ambient color", Color) = (0.1, 0.05, 0.15)
        
        _ScreenTone ("screen tone", Range(0, 9)) = 0
        _ColorIndex ("color index", Range(0, 9)) = 0
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
            #include "Lighting.cginc" // might be UnityLightingCommon.cginc for later versions of unity

            #define MAX_SPECULAR_POWER 256

            float3 _surfaceColor;
            float _gloss;
            float3 _ambientColor;
            float _ScreenTone;
            float _ColorIndex;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 posWorld : TEXCOORD2;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.vertex = UnityObjectToClipPos(v.vertex);

                // how to get the world position
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {

                //modfiy blinn-phong so that grayscale is passed through red channel only.
                //modify blinn-phong so that green channel is uniform and used to select screentone.
                //no use for blue channel for now

                
                float2 uv = i.uv;
                // normalize the normal during specular falloff rendering
                float3 normal = normalize(i.normal);
                
                float3 lightDirection = _WorldSpaceLightPos0;
                float3 lightColor = _LightColor0; // includes intensity

                // blinn-phong
                // calculates "half direction" and compares it to normal 
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
                float3 halfDirection = normalize(viewDirection + lightDirection);

                float diffuseFalloff = max(0, dot(normal, lightDirection));
                float specularFalloff = max(0, dot(normal, halfDirection));

                float3 specular = pow(specularFalloff, _gloss * MAX_SPECULAR_POWER + 0.0001) * lightColor * _gloss;
                float3 blinnphong = diffuseFalloff * _surfaceColor * lightColor + _ambientColor + specular;

                 float3 weight = float3(0.299, 0.587, 0.144);
                float grayscale = dot(blinnphong, weight);
                float screenTone = _ScreenTone * 0.1f + 0.001f;
                float colorIndex = _ColorIndex * 0.1f + 0.001f;

                return float4(grayscale.r, screenTone, colorIndex, 1.0);
            }
            ENDCG
        }
    }
}

