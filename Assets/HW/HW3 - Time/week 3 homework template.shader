Shader "examples/week 3/homework template"
{
    Properties 
    {
        _hour ("hour", Float) = 0
        _minute ("minute", Float) = 0
        _second ("second", Float) = 0
        _sAxis ("second axis", Vector) = (0, 0, 0, 0) // The axis the seconds plane rotates on.
        _sAngle ("second angle", Range(0.0 , 1.0)) = 0.5
        _mAxis ("minute axis", Vector) = (0, 0, 0, 0) // The axis the minutes plane rotates on.
        _mAngle ("minute angle", Range(0.0 , 1.0)) = 0.5
        _hAxis ("hour axis", Vector) = (0, 0, 0, 0) // The axis the hours plane rotates on.
        _hAngle ("hour angle", Range(0.0 , 1.0)) = 0.5
        [NoScaleOffset] _Texture ("Texture", 2D) = "white" {}
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
            #define ACCEL 1 // Set to 1440 to speed up clock cycle so that 30 seconds is 12 hours. Set to 1 for normal.

            
            float _hour;
            float _minute;
            float _second;
            float3 _sAxis;
            float _sAngle;
            float3 _mAxis;
            float _mAngle;
            float3 _hAxis;
            float _hAngle;

            uniform sampler2D _Texture;

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

            // Draws a rectangle in cartesian coordinates.
            float rectangle (float2 uv, float2 scale, float2 offset) {
                float2 s = scale * 0.5;
                float2 shaper = float2(step(offset.x - s.x, uv.x), step(offset.y - s.y, uv.y));
                shaper *= float2(1-step(offset.x + s.x, uv.x), 1-step(offset.y + s.y, uv.y));
                return shaper.x * shaper.y;
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

            // Draws a raw in polar coordinates.
            float radialRay(float2 polarUV, float angle, float thickness)
            {
                float shaper = step(0, (angle - (thickness *0.5)) - polarUV.x);
                float shaper0 = step(0, (angle + (thickness *0.5)) - polarUV.x);
                return shaper0 - shaper;    
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

            
            
            float4 frag (Interpolators i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float oscillate = sin(_Time.x * TAU/2)*0.5;
                oscillate *= 0.05;
                float4 alpha; // mask
                
                //seconds
                float sAngle = TAU * frac(_sAngle + oscillate);
                float3 sAxis = normalize(_sAxis);
                float2 sRotatedPlane = rotatePlaneOnAxis(uv, sAxis, sAngle, 35);
                float2 uvsRotated = float2(sRotatedPlane.x, sRotatedPlane.y);
                
                float sPolar = (atan2(uvsRotated.y, uvsRotated.x) / TAU) + 0.5;
                float sA = frac(sPolar + ((-_second / 60) * ACCEL) + 0.25);
                float4 sColor = circle(uvsRotated, 0.6, 0.05);
                sColor += rectangle(uvsRotated, float2(0.025, 0.7), float2(0, -0.7)) * (1 - sColor);
                sColor += rectangle(uvsRotated, float2(0.5, 0.005), float2(0.8, 0)) * (1 - sColor);
                sColor += rectangle(uvsRotated, float2(0.5, 0.005), float2(-0.8, 0)) * (1 - sColor);
                sColor *= smoothstep(0.2, 1, sA);
                sColor += radialRay(sPolar, 0 + 0.75, 0.003);
                sColor = clamp(0, 1, sColor);
                alpha = sColor;


                //minutes
                float mAngle = TAU * frac(_mAngle + oscillate);
                float3 mAxis = normalize(_mAxis);
                float2 mRotatedPlane = rotatePlaneOnAxis(uv, mAxis, mAngle, 35);
                float2 uvmRotated = float2(mRotatedPlane.x, mRotatedPlane.y);
                
                float mPolar = (atan2(uvmRotated.y, uvmRotated.x) / TAU) + 0.5;
                float mA = frac(mPolar + (-_minute / 60 * ACCEL) + 0.25);
                float4 mColor = circle(uvmRotated, 0.6, 0.05);
                mColor += rectangle(uvmRotated, float2(0.025, 0.6), float2(0, -0.7)) * (1 - mColor);
                mColor += rectangle(uvmRotated, float2(0.4, 0.025), float2(0.8, 0)) * (1 - mColor);
                mColor += rectangle(uvmRotated, float2(0.4, 0.025), float2(-0.8, 0)) * (1 - mColor);
                mColor *= smoothstep(0.2, 1, mA);
                mColor += radialRay(mPolar, 0 + 0.75, 0.003);
                mColor = mColor * (1-alpha);
                mColor = clamp(0, 1, mColor);
                alpha += mColor;

                //hours
                float hAngle = TAU * frac(_hAngle + oscillate);
                float3 hAxis = normalize(_hAxis);
                float2 hRotatedPlane = rotatePlaneOnAxis(uv, hAxis, hAngle, 35);
                float2 uvhRotated = float2(hRotatedPlane.x, hRotatedPlane.y);
                
                float hPolar = (atan2(uvhRotated.y, uvhRotated.x) / TAU) + 0.5;
                float hA = frac(hPolar + (-_hour / 12 * ACCEL) + 0.25);
                float4 hColor = circle(uvhRotated, 0.6, 0.1);
                hColor += rectangle(uvhRotated, float2(0.045, 0.6), float2(0, -0.7)) * (1 - hColor);
                hColor += rectangle(uvhRotated, float2(0.4, 0.045), float2(0.8, 0)) * (1 - hColor);
                hColor += rectangle(uvhRotated, float2(0.4, 0.045), float2(-0.8, 0)) * (1 - hColor);
                hColor *= smoothstep(0.2, 1, hA);
                hColor += radialRay(hPolar, 0 + 0.75, 0.003);
                hColor = hColor * (1-alpha);
                hColor = clamp(0, 1, hColor);
                alpha + hColor;

                //Planet
                float4 planet = circle(uv, 0.007, 0.007);
                alpha += planet;

                // Color in the image.
                float4 color = (1-alpha) * float4(0, 0, 0.3, 1);
                color += hColor * float4(1, 0.67, 0, 1);
                color += mColor * float4(1, 0.8, 0.4, 1);
                color += sColor * float4(1, 1, 0.8, 1);
                color += planet * float4(0.8, 0.4, 0, 1);
                
                return color;
            }
            ENDCG
        }
    }
}
