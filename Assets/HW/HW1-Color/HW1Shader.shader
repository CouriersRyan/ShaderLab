Shader "Unlit/HW1Shader"
{
    Properties
    {
        [NoScaleOffset] _tex1 ("texture one", 2D) = "white" {}
        [NoScaleOffset] _tex2 ("texture two", 2D) = "white" {}
        [NoScaleOffset] _mask ("mask", 2D) = "white" {}
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
            uniform sampler2D _tex1;
            uniform sampler2D _tex2;
            uniform sampler2D _mask;
            
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
                // sample the color data from each of the three textures and store them in float3 variables
                float3 t1 = tex2D(_tex1, uv).rgb;
                float3 t2 = tex2D(_tex2, uv).rgb;
                float3 mask = tex2D(_mask, uv).rgb;
                float3 color = 0;
                
                // add your code here
                //t2 = t2 * mask;
                //mask = smoothstep(0, 1, mask);
                //color = smoothstep(0, 1, t1);
                float3 t2cos = smoothstep(0.1, 1, (-cos(t2 * 3.141592653) + 1) / 1.5);
                float3 mask2 = -cos((uv.x - 0.2)* 1.2 * 3.141592653) / 2 + 0.5;
                float3 maskedt2 = t2cos * mask * mask2;
                color = lerp(t1 * 1.1   / (1 - maskedt2), t1 + t2 - 0.8, mask);
                //color += (1 - mask) * uv.x * (1 - uv.y);
                //color = lerp(t1, t1 + t2 - 1, mask);
                
                //color = -cos((uv.x) * 3.141592653) / 2 + 0.5;
                
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
