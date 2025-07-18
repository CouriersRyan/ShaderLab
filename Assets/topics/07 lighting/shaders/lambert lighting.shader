Shader "examples/week 7/lambert"
{
    Properties 
    {
        _surfaceColor ("surface color", Color) = (0.8, 0.1, 0.4)
    }
    SubShader
    {
        Tags {
            "LightMode" = "ForwardBase"
            }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXTCOORD0;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.normal = v.normal;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 _surfaceColor;

            float4 frag (Interpolators i) : SV_Target
            {
                float3 color = 0;
                
                float3 lightColor = _LightColor0;
                float3 lightDirection = _WorldSpaceLightPos0;

                float diffuseFallOff = max(dot(lightDirection, normalize(i.normal)), 0.0f);
                
                color = diffuseFallOff * _surfaceColor * lightColor;
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
