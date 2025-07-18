Shader "examples/week 10/dither"
{
    Properties
    {
        _MainTex ("render texture", 2D) = "white" {}
        _DitherPattern ("dither pattern", 2D) = "gray" {}
        _Threshold ("threshold", Range(-0.5, 0.5)) = 0
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

            sampler2D _MainTex; float4 _MainTex_TexelSize;
            sampler2D _ScreenTone0; float4 _ScreenTone0_TexelSize;
            float _Threshold;

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
                float color = 0;
                float2 uv = i.uv;

                // (1.0 / 256) * 512
                float2 ditherUV = (uv / _ScreenTone0_TexelSize.zw) * _MainTex_TexelSize.zw;

                float pattern = tex2D(_ScreenTone0, ditherUV);

                float3 weight = float3(0.299, 0.587, 0.144);
                float grayscale = dot(tex2D(_MainTex, uv), weight);
                
                color = step(pattern, grayscale + _Threshold);
                
                return float4(color.rrr, 1.0);
            }
            ENDCG
        }
    }
}
