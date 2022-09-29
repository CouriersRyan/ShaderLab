Shader "Unlit/NoiseShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            
            float rectangle (float2 uv, float2 scale) {
                float2 s = scale * 0.5;
                float2 shaper = float2(step(-s.x, uv.x), step(-s.y, uv.y));
                shaper *= float2(1-step(s.x, uv.x), 1-step(s.y, uv.y));
                return shaper.x * shaper.y;
            }
            
            float rand (float2 uv) {
                return frac(sin(dot(uv.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }

            float rand3D (float3 uv3)
            {
                return frac(sin(dot(uv3.xyz, float3(12.9898, 78.233, 84.394))) * 43758.5453123);
            }

            // modified to take in an extra coordinate z, representing time
            float noise (float2 uv, float z) {
                float2 ipos = floor(uv);
                float2 fpos = frac(uv);
                float iz = floor(z);
                float fz = frac(z);
                
                float o  = rand3D(float3(ipos, iz));
                float x  = rand3D(float3(ipos, iz) + float3(1, 0, 0));
                float y  = rand3D(float3(ipos, iz) + float3(0, 1, 0));
                float xy = rand3D(float3(ipos, iz) + float3(1, 1, 0));
                float oz  = rand3D(float3(ipos, iz) + float3(0, 0, 1));
                float xz  = rand3D(float3(ipos, iz) + float3(1, 0, 1));
                float yz  = rand3D(float3(ipos, iz) + float3(0, 1, 1));
                float xyz = rand3D(float3(ipos, iz) + float3(1, 1, 1));

                float2 smooth = smoothstep(0, 1, fpos);
                float smoothz = smoothstep(0, 1, fz);
                
                return lerp (
                    lerp(
                        lerp(o,  x, smooth.x),
                        lerp(y, xy, smooth.x), smooth.y),
                    lerp(
                        lerp(oz, xz, smooth.x),
                        lerp(yz, xyz, smooth.x), smooth.y),
                smoothz);
            }

            float fractal_noise (float2 uv, int n, float time) {
                float fn = 0;
                // fractal noise is created by adding together "octaves" of a noise
                // an octave is another noise value that is half the amplitude and double the frequency of the previously added noise
                // below the uv is multiplied by a value double the previous. multiplying the uv changes the "frequency" or scale of the noise becuase it scales the underlying grid that is used to create the value noise
                // the noise result from each line is multiplied by a value half of the previous value to change the "amplitude" or intensity or just how much that noise contributes to the overall resulting fractal noise.

                for(int j = 0; j < n; j++)
                {
                    fn += (1.0 / pow(2, j + 1)) * noise(uv * pow(2, j), time * pow(2, j));
                }
                
                return fn;
            }

             // https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle
            // Uses the 3D rotation on an axis at a certain angle from Wikipedia.
            float3x3 createRotationMatrix(float3 axis, float angle)
            {
                float cos1 = cos(-angle);
                float cosInverse = (1 - cos1);
                float sin1 = sin(-angle);
                return float3x3(
                    cos1 + axis.x * axis.x * cosInverse, axis.x * axis.y * cosInverse - axis.z * sin1, axis.x * axis.z * cosInverse + axis.y * sin1,
                    axis.x * axis.y * cosInverse + axis.z * sin1, cos1 + axis.y * axis.y * cosInverse, axis.z * axis.y * cosInverse - axis.x * sin1,
                    axis.z * axis.x * cosInverse - axis.y * sin1, axis.y * axis.z * cosInverse + axis.x * sin1, cos1 + axis.z * axis.z * cosInverse
                );
            }
            
           // Rotates the plane to be perpendicular to axis, then rotates it along the axis. 
            float2 rotatePlaneOnAxis(float2 uv, float3 axis, float angle, float distanceFromCamera)
            {
                float3 uvf3 = float3(uv, 0);

                float3x3 perpendicularToAxis = createRotationMatrix(
                    normalize(cross(float3(0, 0, 1), axis)),
                    acos(dot(float3(0, 0, 1), axis)/(length(float3(0, 0, 1)*length(axis))))
                    );

                float3x3 rotationMatrix = createRotationMatrix(axis, angle);
                
                uvf3 = mul(uvf3, perpendicularToAxis);
                uvf3 = mul(rotationMatrix, uvf3);

                // Rescales XY so that it looks good. I don't really know how, I just punched in random equations until one worked here.
                float3 i = mul(rotationMatrix, float3(1, 1, 1));
                i = 1/i;
                float2 output = uvf3.xy * i;

                // Adjusts XY using Z as depth to give the illusion of depth.
                uvf3.z += 30;
                output *= distanceFromCamera/uvf3.z;
                
                return output;
            }

            // Draws a circle in cartesian coordinates.
            float circle(float2 uv, float radius, float radiusDiff)
            {
                float dist = pow(uv.x, 2) + pow(uv.y, 2);
                float shaper0 = step(0, radius - dist);
                float shaper1 = step(0, radius-radiusDiff - dist);
                float shaper2 = step(uv.y, 0.5 - abs(uv.x));
                return shaper0 - shaper1;
            }
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = (i.uv * 2 - 1);
                float time = _Time.y * 0.1;
                
                
                float3 splash = 0;
                float3 rain = 0;

                for(int j = 0; j < 100; j++)
                {
                    float2 offUv;
                    float offTime = 3 * time + j*(10 + rand(float2(-j, j)));
                    float fade = 1 - smoothstep(0, 0.8, frac(offTime));
                    float x = 2 * (rand(float2(floor(offTime), 0)) - 0.5);
                    float y = 2 * (rand(float2(0, floor(offTime))) - 0.5);
                    offUv = uv + float2(x, y);
                    offUv *= 4 - 4*log2(1 + frac(offTime));
                    offUv = rotatePlaneOnAxis(offUv, float3(0.3, 0.7, 1), 2, 35);

                    //raindrops
                    // take next position but shift y up.
                    float2 rainUv = uv + float2(
                        2 * (rand(float2(floor(offTime + 1), 0)) - 0.5) - 5*(rand(float2(0, floor(offTime)))-0.5)*(1 - frac(offTime)),
                        2 * (rand(float2(0, floor(offTime + 1))) - 0.5) - 20*(1 - frac(offTime))
                    );
                    rainUv *= float2(5, 0.1);
                    rainUv = rotatePlaneOnAxis(rainUv, float3(0.3, 0.7, 1), 2, 35);
                    float3 rainColor = float3(
                        rand(float2(j * floor(offTime + 1), 0)),
                        rand(float2(0, j * floor(offTime + 1))),
                        lerp(0.8, 1, rand(float2(1 - floor(offTime + 1), 1)))
                    );
                    rain += rainColor * circle(rainUv, 0.0001f, 0.0001f) * 0.5f;
                    
                    //ripple
                    fixed4 tex = tex2D(_MainTex, offUv - 0.5);
                    tex *= rectangle(offUv, float2(1, 1));
                    
                    float fn = pow(fractal_noise(offUv, 4, offTime), 2);
                    fn *= fade;
                    float3 color = float3(
                        rand(float2(j * floor(offTime), 0)),
                        rand(float2(0, j * floor(offTime))),
                        lerp(0.8, 1, rand(float2(1 - floor(offTime), 1)))
                    );
                    splash += fn * color * tex;
                }

                
                fixed4 col = float4(splash.rgb, 1) + float4(rain.rgb, 1);
                
                return col;
            }
            ENDCG
        }
    }
}
