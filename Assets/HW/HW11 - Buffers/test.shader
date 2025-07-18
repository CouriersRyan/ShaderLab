Shader "Custom/testing"
{
    Properties 
    {
        _surfaceColor ("surface color", Color) = (0.4, 0.1, 0.9)
        _gloss ("gloss", Range(0,1)) = 1
        _ambientColor ("ambient color", Color) = (0.7, 0.05, 0.15)
        
        _albedoTex ("Albedo", 2D) = "white" {}
        
        _worldLightPos ("world light position", Vector) = (0, 0, 0)
        _worldLightColor ("world light color", Color) = (0, 0, 0)
        
        _worldLightPos0 ("world light position without stencil", Vector) = (0, 0, 0)
        _worldLightColor0 ("world light color without stencil", Color) = (0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue" = "Geometry+1" }
        Blend One One
        
        Pass
        {
            Stencil{
            Ref 2
            Comp Equal
            }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // might be UnityLightingCommon.cginc for later versions of unity
            #include "Lighting.cginc"

            #define MAX_SPECULAR_POWER 256
            
            sampler2D _albedoTex;
            float _gloss;
            float3 _ambientColor;
            float3 _worldLightPos;
            float3 _worldLightColor;

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

                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv;

                float3 surface = tex2D(_albedoTex, uv);

                float3 normal = normalize(i.normal);
                
                float3 lightDirection = normalize(_worldLightPos);
                float3 lightColor = _worldLightColor; // includes intensity

                // blinn-phong
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
                float3 halfDirection = normalize(viewDirection + lightDirection);

                float diffuseFalloff = max(0, dot(normal, lightDirection));
                float specularFalloff = max(0, dot(normal, halfDirection));

                float3 specular = pow(specularFalloff, _gloss * MAX_SPECULAR_POWER + 0.0001) * lightColor * _gloss;


                float3 blinnPhong = (diffuseFalloff * surface * lightColor + specular + _ambientColor);

                return float4(blinnPhong, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
