Shader "examples/week 9/IBL fresnel and roughness"
{
    Properties 
    {
        _albedo ("albedo", 2D) = "white" {}
        [NoScaleOffset] _normalMap ("normal map", 2D) = "bump" {}
        [NoScaleOffset] _displacementMap ("displacement map", 2D) = "gray" {}
        [NoScaleOffset] _roughnessMap ("roughness map", 2D) = "white" {}
        [NoScaleOffset] _rainMap ("rain map", 2D) = "black" {}
        [NoScaleOffset] _rainNormalMap ("rain normal map", 2D) = "black" {}
        [NoScaleOffset] _rainDisplacementMap ("rain displacement map", 2D) = "black" {}

        // brightness of specular reflection - proportion of color contributed by diffuse and specular
        // reflectivity at 1, color is all specular
        _reflectivity ("reflectivity", Range(0,1)) = 0.5

        _fresnelPower ("fresnel power", Range(0, 10)) = 5
        _normalIntensity ("normal intensity", Range(0, 1)) = 1
        _displacementIntensity ("displacement intensity", Range(0, 0.5)) = 0
    }
    SubShader
    {
        // this tag is required to use _LightColor0
        Tags { "LightMode"="ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // might be UnityLightingCommon.cginc for later versions of unity
            #include "Lighting.cginc"

            #define DIFFUSE_MIP_LEVEL 4
            #define SPECULAR_MIP_STEPS 5
            #define MAX_SPECULAR_POWER 256

            sampler2D _albedo; float4 _albedo_ST;
            sampler2D _normalMap;
            sampler2D _displacementMap;
            sampler2D _roughnessMap;
            sampler2D _rainMap;
            sampler2D _rainNormalMap;
            sampler2D _rainDisplacementMap;
            float _reflectivity;
            float _fresnelPower;
            float _normalIntensity;
            float _displacementIntensity;

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

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;

                // xyz is the tangent direction, w is the tangent sign
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 bitangent : TEXCOORD3;
                float3 posWorld : TEXCOORD4;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.uv = TRANSFORM_TEX(v.uv, _albedo);
                
                float height = (tex2Dlod(_displacementMap, float4(o.uv, 0, 0)).r + tex2Dlod(_rainDisplacementMap, float4(o.uv, 0, 0)).r * 0.1f) * 2 - 1;
                v.vertex.xyz += v.normal * height * _displacementIntensity;

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldNormal(v.tangent);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                
                return o;
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float3 color = 0;
                float2 uv = i.uv;

                float2 rainUV = i.posWorld.xy * float2(2, 1);
                float2 rainUVx = i.posWorld.zy * float2(2, 1);
                float rainNoise = noise(rainUV);
                rainUV += lerp(0.001, 0.6, rainNoise);
                rainUVx += lerp(0.001, 0.6, rainNoise);
                rainUV += float2(0, _Time.y * 0.2f);
                rainUVx +=  float2(0, _Time.y * 0.2f);

                float3 tangentSpaceNormal = UnpackNormal(tex2D(_normalMap, uv));
                float3 rainNormal = UnpackNormal(tex2D(_rainNormalMap, rainUV)) + UnpackNormal(tex2D(_rainNormalMap, rainUVx));
                
                tangentSpaceNormal = normalize(lerp(float3(0, 0, 1), tangentSpaceNormal, _normalIntensity));
                rainNormal = normalize(lerp(float3(0, 0, 1), rainNormal, _normalIntensity));
                
                float3x3 tangentToWorld = float3x3 
                (
                    i.tangent.x, i.bitangent.x, i.normal.x,
                    i.tangent.y, i.bitangent.y, i.normal.y,
                    i.tangent.z, i.bitangent.z, i.normal.z
                );

                float3 normal = mul(tangentToWorld, normalize(tangentSpaceNormal + rainNormal)); 

                float3 rainDiffuse = saturate(lerp(0, tex2D(_rainMap, rainUV).r, abs(normal.z) - 0.5)) + saturate(lerp(0, tex2D(_rainMap, rainUVx).r, abs(normal.x) - 0.5));

                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
                float fresnel = 1 - saturate(dot(viewDirection, normal));
                fresnel = pow(fresnel, _fresnelPower);

                // since fresnel affects reflectivity, we'll use it to modify the reflectivity variable
                float reflectivity = _reflectivity * fresnel;

                // since the diffuse and reflective properties of an object are inversely related, we want to set up our surface color to lerp between black and the albedo based on the inverse of reflectivity
                // if 0% reflective -> all diffuse
                float3 surfaceColor = lerp(0, tex2D(_albedo, uv).rgb, 1 - reflectivity);

                float3 lightDirection = _WorldSpaceLightPos0;
                float3 lightColor = _LightColor0; // includes intensity

                // make view direction negative because reflect takes an incidence vector, meaning, it is point toward the surface
                // viewDirection is pointing toward the camera
                float3 viewReflection = reflect(-viewDirection, normal);

                float rainSpecular =  saturate(lerp(0, tex2D(_rainDisplacementMap, rainUV).r, abs(normal.z) - 0.5)) + saturate(lerp(0, tex2D(_rainDisplacementMap, rainUVx).r, abs(normal.x) - 0.5));
                float roughness = saturate(tex2D(_roughnessMap, uv).r - rainSpecular);
                float mip = roughness * SPECULAR_MIP_STEPS;
                float3 indirectSpecular = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, viewReflection, mip) * lerp(_reflectivity, 1, rainSpecular);

                float3 halfDirection = normalize(viewDirection + lightDirection);

                float directDiffuse = max(0, dot(normal, lightDirection));
                float specularFalloff = max(0, dot(normal, halfDirection));
                
                // the specular power, which controls the sharpness of the direct specular light is dependent on the glossiness (smoothness)
                float3 directSpecular = pow(specularFalloff, (1 - roughness) * MAX_SPECULAR_POWER + 0.0001) * lightColor * (1-roughness);

                float3 specular = directSpecular + indirectSpecular * reflectivity;
               
                float3 indirectDiffuse = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normal, DIFFUSE_MIP_LEVEL);
                rainDiffuse *= indirectDiffuse;
                float3 diffuse = surfaceColor * (directDiffuse * lightColor + rainDiffuse);

                color = diffuse + specular;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
