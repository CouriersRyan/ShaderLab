Shader "Unlit/CageVertexShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _rot ("Rotation", float) = 0
        _incrementFactor ("Increment", int) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define TAU 6.28318530718

            #include "UnityCG.cginc"

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
            };

            float4x4 rotation_matrix (float3 axis, float angle) {
                axis = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float oc = 1.0 - c;
                
                return float4x4(
                    oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                    0.0,                                0.0,                                0.0,                                1.0);
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _OffsetTex;
            float _rot;
            int _incrementFactor;

            Interpolators vert (MeshData v)
            {
                Interpolators o;

                tex2D(_MainTex, v.uv);
                
                v.vertex.y += 0.5f;
                float yGradient = (1-v.vertex.y);

                float4x4 scaleMatrix = float4x4(
                    1, 0, 0, 0,
                    0, 20, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                );
                float4x4 x = rotation_matrix(float3(1, 0 ,0), TAU * sin(TAU * (0.25f - v.vertex.y * 0.25f)) * _rot);
                float4x4 y = rotation_matrix(float3(0, 1 ,0), TAU * (yGradient + -_Time.x) *2.0f);
                float4x4 z = rotation_matrix(float3(0, 0 ,1),  0);
                float4x4 rot = mul(mul(y, z), x);

                v.vertex.xz = pow((sin(_Time.y + yGradient * (_incrementFactor * (1+yGradient)) * TAU) + 1) * 0.5f, 4 * (1+yGradient)) * v.vertex.xz * lerp(0, pow(v.vertex.xz, 2) * 4 * (1 + yGradient), (pow(0.5f, 2) - length(v.vertex.xz))/pow(0.5f, 2));
                
                v.vertex = mul(v.vertex, scaleMatrix);
                //v.vertex.z += 5 * sin(_Time.y + v.vertex.y * 2) * v.vertex.y;
                v.vertex = mul(v.vertex, rot);
                float4x4 y2 = rotation_matrix(float3(0, 1 ,0), TAU * (yGradient + -_Time.x) * 0.5f);
                v.vertex = mul(v.vertex, y2);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                
                fixed4 col = tex2D(_MainTex, i.uv);
                
                return col;
            }
            ENDCG
        }
    }
}
