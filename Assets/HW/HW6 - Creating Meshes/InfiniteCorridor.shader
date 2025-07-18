Shader "Unlit/InfiniteCorridor"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Iteration ("Iteration", Int) = 0
        _TotalInt ("Total Iterations", Int) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define TAU 6.28318530718
            #define BLENDER_UNIT_MULTIPLIER 100

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float4 color : COLOR;
            };

            float rand (float2 uv) {
                return frac(sin(dot(uv.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }

            float noise (float2 uv) {
                float2 ipos = floor(uv);
                float2 fpos = frac(uv); 
                
                float o  = rand(ipos);
                float x  = rand(ipos + float2(1, 0));
                float y  = rand(ipos + float2(0, 1));
                float xy = rand(ipos + float2(1, 1));

                float2 smooth = smoothstep(0, 1, fpos);
                return lerp( lerp(o,  x, smooth.x), 
                             lerp(y, xy, smooth.x), smooth.y);
            }
            
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
            int _Iteration;
            int _TotalInt;

            Interpolators vert (MeshData v)
            {
                // Use frac() and floor() to distinguish between various corridor segments.
                // floor() is used to differentiate between corridor segments, only when the whole corridor has passed does it render ahead.
                // frac() is used to make individual rotations to each vertex based on our given sin waves.
                // Corridors rotate slightly along xyz according to a smooth noise function.
                // Function gets the current rotation and uses pluses to increment in the future, doing so we can have the rotation
                // be offset by the difference between the current rotation and future rotation.
                // Visual Example: We are drawing a line forward dependent on a bunch of sin waves for rotations.
                // Each vertex on that line must obey its rotation.
                // Each vertex rotates independently of the mesh, so previous mesh rotations have no bearing on the current.
                // So future meshes should not be impacted either.

                //Implement with a simple sin wave first and see how it goes.
                float time = _Time.y;
                int currCorridor = ceil(time);
                float t = frac(time);
                int thisRender = currCorridor + _Iteration;
                v.vertex.z += (thisRender - time) * 2; // For some reason times 2 is needed, not sure why since the corridor is a unit cube in Blender.
                float4x4 yRot = rotation_matrix(float3(0, 1 ,0), 0.5f *
                    (
                        (noise(float2((thisRender + v.color.r) * 0.3f, 0))
                        + step(9, fmod(thisRender, 10)) * v.color.r * TAU*0.25f + ceil(thisRender/10) * TAU*0.25f)
                        - (noise(float2 (time * 0.3f, 0))
                        + step(9, fmod(currCorridor, 10)) * t * TAU*0.25f + ceil(currCorridor/10) * TAU*0.25f)
                    ));
                float4x4 xRot = rotation_matrix(float3(1, 0 ,0), 0.5f *
                    (
                        (noise(float2((thisRender + v.color.r) * 0.3f, 1)))
                        - (noise(float2 (time * 0.3f, 1)))
                    ));
                float4x4 zRot = rotation_matrix(float3(0, 0 ,1), 0.2f *
                    (
                        (noise(float2((thisRender + v.color.r) * 0.3f, 1)))
                        - (noise(float2 (time * 0.3f, 1)))
                    ));
                
                v.vertex = mul(v.vertex, mul(zRot, mul(yRot, xRot)));
                
                
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                float d = (10.0f - i.worldPos.z)*0.1f;
                return col * float4(pow(d, 3), 0.1 * d, 0.3 * d, 1.0);
            }
            ENDCG
        }
    }
}
