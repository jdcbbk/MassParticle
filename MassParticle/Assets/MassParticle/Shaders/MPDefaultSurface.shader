﻿Shader "MassParticle/Lambert" {

Properties {
    _ParticleSize ("Particle Size", Float) = 0.08
    _Color ("Color", Color) = (0.8, 0.8, 0.8, 1.0)
    _FadeTime ("Fade Time", Float) = 0.3
    _MainTex ("Base (RGB)", 2D) = "white" {}
}
SubShader {
    Tags { "RenderType"="Opaque" }
        
    CGPROGRAM
    #pragma surface surf Lambert vertex:vert
    #pragma glsl

    sampler2D _MainTex;
    sampler2D _DataTex;
    float _ParticleSize;
    float _DataTexPitch;
    float4 _Color;
    float _FadeTime;

    struct Input {
        float4 color : COLOR;
        float2 uv_MainTex;
        float4 speed_lifetime;
    };

    void vert (inout appdata_full v, out Input data)
    {
        UNITY_INITIALIZE_OUTPUT(Input,data);

        float4 pitch = float4(_DataTexPitch, 0.0, 0.0, 0.0);
        float4 position = tex2Dlod(_DataTex, v.texcoord);
        float4 velocity = tex2Dlod(_DataTex, v.texcoord+pitch);
        float4 params = tex2Dlod(_DataTex, v.texcoord+pitch*2.0);
        float lifetime = params.y;

        v.vertex.xyz *= _ParticleSize * 100.0;
        v.vertex.xyz *= min(1.0, lifetime/_FadeTime);
        v.vertex.xyz += position.xyz;
        data.speed_lifetime = float4(velocity.w, lifetime, 0.0, 0.0);
    }

    void surf (Input data, inout SurfaceOutput o)
    {
        float speed = data.speed_lifetime.x;
        float lifetime = data.speed_lifetime.y;
        if(lifetime<=0.0f) {
            discard;
        }
        o.Albedo = (_Color * tex2D(_MainTex, data.uv_MainTex)).xyz;
        o.Alpha = 1.0f;

        float ei = max(speed-2.0, 0.0) * 1.0;
        o.Emission = float3(0.25, 0.05, 0.025)*ei;
    }
    ENDCG


    Pass {
        Name "ShadowCaster"
        Tags { "LightMode" = "ShadowCaster" }
        
        Fog {Mode Off}
        ZWrite On ZTest LEqual Cull Off
        Offset 1, 1

    CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_shadowcaster
        #pragma glsl
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _DataTex;
        float _ParticleSize;
        float _DataTexPitch;
        float4 _Color;
        float _FadeTime;

        struct v2f { 
            V2F_SHADOW_CASTER;
        };

        v2f vert( appdata_base v )
        {
            float4 pitch = float4(_DataTexPitch, 0.0, 0.0, 0.0);
            float4 position = tex2Dlod(_DataTex, v.texcoord);
            float4 params = tex2Dlod(_DataTex, v.texcoord+pitch*2.0);
            float lifetime = params.y;
            v.vertex.xyz *= (_ParticleSize*100.0);
            v.vertex.xyz *= min(1.0, lifetime/_FadeTime);
            v.vertex.xyz += position.xyz;

            v2f o;
            TRANSFER_SHADOW_CASTER(o)
            return o;
        }

        float4 frag( v2f i ) : SV_Target
        {
            SHADOW_CASTER_FRAGMENT(i)
        }
    ENDCG
    }

    Pass {
        Name "ShadowCollector"
        Tags { "LightMode" = "ShadowCollector" }
        
        Fog {Mode Off}
        ZWrite On ZTest LEqual

    CGPROGRAM
        #pragma target 4.0
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_shadowcollector
        #pragma glsl
        #define SHADOW_COLLECTOR_PASS
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _DataTex;
        float _ParticleSize;
        float _DataTexPitch;
        float4 _Color;
        float _FadeTime;

        struct v2f { 
            V2F_SHADOW_COLLECTOR;
        };

        v2f vert( appdata_base v )
        {
            float4 pitch = float4(_DataTexPitch, 0.0, 0.0, 0.0);
            float4 position = tex2Dlod(_DataTex, v.texcoord);
            float4 params = tex2Dlod(_DataTex, v.texcoord+pitch*2.0);
            float lifetime = params.y;
            v.vertex.xyz *= (_ParticleSize*100.0);
            v.vertex.xyz *= min(1.0, lifetime/_FadeTime);
            v.vertex.xyz += position.xyz;
            
            v2f o;
            TRANSFER_SHADOW_COLLECTOR(o)
            return o;
        }
        
        fixed4 frag (v2f i) : SV_Target
        {
            SHADOW_COLLECTOR_FRAGMENT(i)
        }
    ENDCG
    }
}
FallBack Off

}