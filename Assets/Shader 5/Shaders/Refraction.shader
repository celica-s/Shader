﻿Shader "Custom/Refraction"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _RefractColor ("Refraction Color", Color) = (1,1,1,1)
        _RefractAmount ("Refract Amount", Range(0,1)) = 1
        _RefractRatio ("Refracttion Ratio", Range(0,1)) = 0.5
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
            float4 _RefractColor;
            float _RefractAmount;
            float _RefractRatio;
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
                float3 worldRrac : TEXCOORD3;

                SHADOW_COORDS(4)
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRrac = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

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

                fixed3 refraction = texCUBE(_CubeMap, i.worldRrac).rgb * _RefractColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

    }
    FallBack "Diffuse"
}