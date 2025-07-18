Shader "Unlit/fun sky box"
{
    Properties 
    {
        [NoScaleOffset] _TexCube ("tex cube", Cube) = "black" {}
        _colorHigh ("color high", Color) = (1, 1, 1, 1)
        _colorLow ("color low", Color) = (0, 0, 0, 1)
        _colorHorizon ("color horizon", Color) = (1, 1, 1, 1)
        _contrast ("contrast", Float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off
        ZWrite Off
    

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            samplerCUBE _TexCube;
            float3 _colorHigh;
            float3 _colorLow;
            float3 _colorHorizon;
            float _contrast;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float3 objPos : TEXCOORD0;
                float3 uv : TEXCOORD1;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.objPos = v.vertex.xyz;
                o.uv = v.uv;

                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float3 color = 0;
                float3 uv = normalize(i.uv) * 0.5f + 0.5f;
                float time = frac(_Time.y) * 2 - 1;
                float3 gradient = lerp (_colorLow, _colorHigh, smoothstep(-1 , 1, pow(uv.x + time, _contrast)));
                float3 horizon = (1 - (2 * abs(0.5 - smoothstep(-1 , 1, pow(uv.x + time, _contrast))))) * _colorHorizon;

                float verticalMask = step(0.65f, uv.y) * step (uv.y, 0.66f);
                horizon *= verticalMask;
                

                color = texCUBElod(_TexCube, float4(i.objPos, 0));
                color *= gradient / ( 1 - horizon);

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
