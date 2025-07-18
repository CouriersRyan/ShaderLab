Shader "Buffers/dimensionalGlass1"
{
    Properties {
        _color ("color", Color) = (0, 0, 0.8, 1)
        _depth ("depth", Range(0, 500)) = 10
        _opacity ("opacity", Range(0,1)) = 0.8
    }
    
    SubShader
    {
        Tags{
            "RenderType"="Opaque" "Queue" = "Geometry+1"
        }
        
        GrabPass{
            "_BackgroundTex"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;
            sampler2D _BackgroundTex;

            float3 _color;
            float _opacity;
            float _depth;

            struct MeshData
            {
                float4 vertex : POSITION;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float4 posScreen : TEXCOORD0;
                float surfZ : TEXCOORD1;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posScreen = ComputeScreenPos(o.vertex);
                o.surfZ = -UnityObjectToViewPos(v.vertex).z;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float2 screenUV = i.posScreen.xy / i.posScreen.w;
                float depth = Linear01Depth(tex2D(_CameraDepthTexture, screenUV));
                float depthDiff = abs(depth/_ProjectionParams.w - i.surfZ);
                depthDiff = pow(depthDiff, 0.9f);
                float fog = 1-smoothstep(0, _depth, depthDiff);

                float3 background = tex2D(_BackgroundTex, screenUV);
                background *= fog;

                float3 color = saturate(_color * _opacity + background);
                
                return float4(color, 1);
            }
            ENDCG
        }
    }
}
