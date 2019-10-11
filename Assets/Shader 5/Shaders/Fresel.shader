﻿Shader "Custom/Fresel"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _FresnelScale("Fresnel Scale", Range(0,1)) = 0.5
        _CubeMap ("Refraction Cube", Cube) = "_Skybox" {}
    }
    SubShader
    {
       Pass{
            Tags { "RenderType"="Opaque" }

            CGPROGRAM
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma vertex vert
            #pragma fragment frag

            float4 _Color;
            float _FresnelScale;
            samplerCUBE _CubeMap;

            struct a2v
            {
                float3 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                fixed4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefl : TEXCOORD3;

                SHADOW_COORDS(4)
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 reflection = texCUBE(_CubeMap, i.worldRefl).rgb;

                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow((1 - dot(worldViewDir, worldNormal)), 5);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

    }
    FallBack "Diffuse"
}
