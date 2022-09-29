Shader "Unlit/HW2-Shaping"
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
            #define TAU 6.283185

            #include "UnityCG.cginc"

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

            // Outputs a float4, with the first three being color and the last one being the black&white mask.
            float4 rose(float2 uv, float3 coreColor, float3 outlineColor)
            {
                //Create the core shape of a single flower petal with one large sin wave multiplied by many smaller sign waves.
                float shape = sin(TAU * uv.x)*0.5 + 0.5;
                shape = shape * (1-uv.y);
                float wave = sin(TAU * frac(uv.x + _Time.x) * 7)*0.25 + 0.75;
                shape = smoothstep(0.05, 0.1, shape * wave); // Creates a well defined 0 and 1 value area for the base and negative space.

                // Create an outline out of the values between 0 and 1 which appear on the edge of the shape.
                float outline = sin(TAU/2 * shape);
                outline = smoothstep(0, 0.5, outline);
                shape = shape * (1-outline); // Remove the overlap between shape and outline.

                // Apply colors.
                float3 colorShape = shape * coreColor;
                colorShape += outline * outlineColor;

                // Output a mask for the alpha channel represent every color pixel.
                float mask = shape + outline;
                return float4(colorShape, mask);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;


                //Convert to polar coordinates. Implementation from class.
                float2 polar = float2(atan2(uv.y, uv.x), length(uv));
                polar.x = (polar.x) / TAU + 0.5; // range from -PI to PI to -0.5 to 0.5 and then adding 0.5 to get the range 0 to 1.
                //polar.y = frac(polar.y);
                //polar = lerp(polar, uv, polar.y/8 * 0.2);
                polar.y *= 8;
                polar.x = frac(polar.x * 4);

                // The interesting code starts here.
                // The code iterates and runs the same function several times. I chose this over frac() because I wanted to
                // create deliberate overlap, as the visual motif for this was flowers.
                float4 output = 0;
                polar.x = frac(polar.x - _Time.x);
                //output = rose(polar, float3(0.114, 0.608, 0.941), float3(0, 0.984, 1));
                int iterations = 20;

                // Arrays that are used to determine the colors.
                float3 baseColors[3] = {float3(0.91, 0.161, 0.047), float3(1, 0.796, 0.122), float3(1, 0.384, 0)};
                float3 outlineColors[3] = {float3(0.341, 0.161, 0.039), float3(1, 0, 0.251), float3(1, 1, 0)};

                // Increases the size of each ring of petals by distorting the polar coordinates each iteration.
                float distortion = 0.9;
                int j = 0;
                for(j = 0; j < iterations/2; j++)
                {
                    polar.x = frac(polar.x + 1.1 + 0.8*(1.0 - float(j)/float(iterations)));
                    polar.y = polar.y * distortion;
                    int colorIndex = j % 3; // Alternates colors for each iteration.
                    float4 temp = rose(polar, baseColors[colorIndex], outlineColors[colorIndex]) * (1-output.a); // Uses the alpha channel to cut out overlap with petals in the foreground.
                    temp = lerp(float4(outlineColors[colorIndex], 1) * (temp.a), temp, ((float)j/iterations));
                    output += temp;
                }
                polar.x = frac(polar.x * 2); // Splits petals from 4 per set to 8 per set for the second half.
                for(j = iterations/2; j < iterations; j++)
                {
                    polar.x = frac(polar.x + 1.1 + 0.8*(1.0 - float(j)/float(iterations)));
                    polar.y = polar.y * distortion;
                    int colorIndex = j % 3;
                    float4 temp = rose(polar, baseColors[colorIndex], outlineColors[colorIndex]) * (1-output.a);
                    temp = lerp(float4(outlineColors[colorIndex], 1) * (temp.a), temp, ((float)j/iterations));
                    output += temp;
                }
                
                return float4(output.rgb, 1.0);
            }
            ENDCG
        }
    }
}
