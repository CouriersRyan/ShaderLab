Shader "examples/week 3/homework template"
{
    Properties 
    {
        _hour ("hour", Float) = 0
        _minute ("minute", Float) = 0
        _second ("second", Float) = 0
        _hAxis ("hour axis", Vector) = (0, 0, 0, 0) // The axis the hour plane rotates on.
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

            #define TAU 6.28318530718

            float _hour;
            float _minute;
            float _second;
            float3 _hAxis;

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

            float rectangle (float2 uv, float2 scale) {
                float2 s = scale * 0.5;
                float2 shaper = float2(step(-s.x, uv.x), step(-s.y, uv.y));
                shaper *= float2(1-step(s.x, uv.x), 1-step(s.y, uv.y));
                return shaper.x * shaper.y;
            }

            // https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle
            float2 rotatePlaneOnAxis(float2 uv, float3 axis, float angle, float distanceFromCamera)
            {
                float3 uvf3 = float3(uv, 0);

                float3x3 rotationMatrix = float3x3(
                    cos(angle) + pow(axis.x, 2) * (1 - cos(angle)), axis.x * axis.y * (1 - cos(angle)) - axis.z * sin(angle), axis.x * axis.z * (1 - cos(angle)) + axis.y * sin(angle),
                    axis.x * axis.y * (1 - cos(angle)) + axis.z * sin(angle), cos(angle) + pow(axis.y, 2) * (1 - cos(angle)), axis.z * axis.y * (1 - cos(angle)) - axis.x * sin(angle),
                    axis.z * axis.x * (1 - cos(angle)) - axis.y * sin(angle), axis.y * axis.z * (1 - cos(angle)) + axis.x * sin(angle), cos(angle) + pow(axis.z, 2) * (1 - cos(angle))
                );

                uvf3 = mul(uvf3, rotationMatrix);

                float2 output = uvf3.xy;
                output *= distanceFromCamera/uvf3.z;
                
                return output;
            }

            #define TAU 6.28318531
            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;

                float hAngle = TAU * frac(_second/20);
                float3 hAxis = normalize(_hAxis);
                
                uv = rotatePlaneOnAxis(uv, hAxis, hAngle, 1);

                return rectangle(uv, float2(0.5, 0.25));
                //return float4(_hour/24, _minute/60, _second/60, 1.0);
            }
            ENDCG
        }
    }
}
