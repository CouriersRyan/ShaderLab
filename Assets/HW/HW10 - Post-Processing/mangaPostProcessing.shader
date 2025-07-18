Shader "Custom/mangePostProcessing"
{
    Properties
    {
        _MainTex ("render texture", 2D) = "white" {}
        _ScreenTone0 ("screen tone 0", 2D) = "gray" {}
        _ScreenTone1 ("screen tone 1", 2D) = "gray" {}
        _ScreenTone2 ("screen tone 2", 2D) = "gray" {}
        _ScreenTone3 ("screen tone 3", 2D) = "gray" {}
        _ScreenTone4 ("screen tone 4", 2D) = "gray" {}
        _ScreenTone5 ("screen tone 5", 2D) = "gray" {}
        _ScreenTone6 ("screen tone 6", 2D) = "gray" {}
        _ScreenTone7 ("screen tone 7", 2D) = "gray" {}
        _ScreenTone8 ("screen tone 8", 2D) = "gray" {}
        _ScreenTone9 ("screen tone 9", 2D) = "gray" {}
        _Color0 ("color 0", Color) = (1, 1, 1, 1)
        _Color1 ("color 1", Color) = (1, 1, 1, 1)
        _Color2 ("color 2", Color) = (1, 1, 1, 1)
        _Color3 ("color 3", Color) = (1, 1, 1, 1)
        _Color4 ("color 4", Color) = (1, 1, 1, 1)
        _Color5 ("color 5", Color) = (1, 1, 1, 1)
        _Color6 ("color 6", Color) = (1, 1, 1, 1)
        _Color7 ("color 7", Color) = (1, 1, 1, 1)
        _Color8 ("color 8", Color) = (1, 1, 1, 1)
        _Color9 ("color 9", Color) = (1, 1, 1, 1)
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
            sampler2D _ScreenTone1; float4 _ScreenTone1_TexelSize;
            sampler2D _ScreenTone2; float4 _ScreenTone2_TexelSize;
            sampler2D _ScreenTone3; float4 _ScreenTone3_TexelSize;
            sampler2D _ScreenTone4; float4 _ScreenTone4_TexelSize;
            sampler2D _ScreenTone5; float4 _ScreenTone5_TexelSize;
            sampler2D _ScreenTone6; float4 _ScreenTone6_TexelSize;
            sampler2D _ScreenTone7; float4 _ScreenTone7_TexelSize;
            sampler2D _ScreenTone8; float4 _ScreenTone8_TexelSize;
            sampler2D _ScreenTone9; float4 _ScreenTone9_TexelSize;
            float3 _Color0;
            float3 _Color1;
            float3 _Color2;
            float3 _Color3;
            float3 _Color4;
            float3 _Color5;
            float3 _Color6;
            float3 _Color7;
            float3 _Color8;
            float3 _Color9;
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
                float3 color = 0;
                float2 uv = i.uv;

                // (1.0 / 256) * 512
                float2 ditherUV = (uv / _ScreenTone0_TexelSize.zw) * _MainTex_TexelSize.zw;

                float3 sample = tex2D(_MainTex, uv);

                float pattern0 = tex2D(_ScreenTone0, ditherUV);
                float pattern1 = tex2D(_ScreenTone1, ditherUV);
                float pattern2 = tex2D(_ScreenTone2, ditherUV);
                float pattern3 = tex2D(_ScreenTone3, ditherUV);
                float pattern4 = tex2D(_ScreenTone4, ditherUV);
                float pattern5 = tex2D(_ScreenTone5, ditherUV);
                float pattern6 = tex2D(_ScreenTone6, ditherUV);
                float pattern7 = tex2D(_ScreenTone7, ditherUV);
                float pattern8 = tex2D(_ScreenTone8, ditherUV);
                float pattern9 = tex2D(_ScreenTone9, ditherUV);

                
                float pattern = lerp(
                    lerp(
                        lerp(pattern0, pattern1, step(0.1f, sample.g)),
                        lerp(pattern2, lerp(pattern3, pattern4, step(0.4f, sample.g)), step(0.3f, sample.g)),
                        step(0.2f, sample.g)),
                    lerp(
                        lerp(pattern5, pattern6, step(0.6f, sample.g)),
                        lerp(pattern7, lerp(pattern8, pattern9, step(0.9f, sample.g)), step(0.8f, sample.g)),
                        step(0.2f, sample.g)),
                step(0.5f, sample.g));

                float3 mainColor = lerp(
                    lerp(
                        lerp(_Color0, _Color1, step(0.1f, sample.b)),
                        lerp(_Color2, lerp(_Color3, _Color4, step(0.4f, sample.b)), step(0.3f, sample.b)),
                        step(0.2f, sample.b)),
                    lerp(
                        lerp(_Color5, _Color6, step(0.6f, sample.b)),
                        lerp(_Color7, lerp(_Color8, _Color9, step(0.9f, sample.b)), step(0.8f, sample.b)),
                        step(0.7f, sample.b)),
                step(0.5f, sample.b));
                
                color = mainColor * step(pattern, sample.r + _Threshold);
                
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}