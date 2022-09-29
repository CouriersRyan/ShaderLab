Shader "examples/week 4/texture mapping"
{
    Properties
    {
        _tex ("texture", 2D) = "white" {}
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

            sampler2D _tex; float4 _tex_ST;
            
            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.screenPos = ComputeScreenPos(o.vertex);
                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv;
                float3 color = 0;

                uv = i.worldPos.xy * (1/i.worldPos.z);

                uv = i.screenPos.xy / i.screenPos.w;
                float aspect = _ScreenParams.x / _ScreenParams.y;
                uv.x *= aspect;
                
                color = tex2D(_tex, TRANSFORM_TEX(uv, _tex)).rgb;
                
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
