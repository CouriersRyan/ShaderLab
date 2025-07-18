﻿Shader "examples/week 12/ray marching"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #define MAX_STEPS 100
            #define MAX_DIST 10
            #define MIN_DIST 0.001

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 hitPos : TEXCOORD1;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float get_dist(float3 pos)
            {
                float radius = 0.5;
                float radiusCompressed = 0.01;
                float bounceTime = pow((sin(_Time.y * 3) + 1)*0.5, 0.5);
                radiusCompressed = lerp(radiusCompressed, radius, bounceTime);
                float height = 2*bounceTime - 1;
                
                float3 spherePos = float3(0, height, 0);
                float3 sphereDir = normalize(spherePos - pos);
                
                float dSphere = distance(spherePos, pos) - lerp(radiusCompressed, radius, 1 - sphereDir.y);

                float planeYPos = -0.5;
                float dPlane = abs(pos.y - planeYPos);

                
                return min(dSphere, dPlane);
            }

            float ray_march(float3 rayOrigin, float3 rayDir)
            {
                float marchDist = 0;

                for(int i = 0; i < MAX_STEPS; i++)
                {
                    float3 pos = rayOrigin + rayDir * marchDist;
                    float distToSurf = get_dist(pos);

                    marchDist += distToSurf;

                    if(distToSurf < MIN_DIST || marchDist > MAX_DIST) break;
                }

                return marchDist;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float3 color = 0;
                float3 camPos = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.hitPos - camPos);

                float d = ray_march(camPos, rayDir);

                float depth = 1 - d / MAX_DIST;

                color = depth.rrr;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
