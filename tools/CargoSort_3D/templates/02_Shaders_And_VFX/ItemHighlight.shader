Shader "CargoSort/ItemHighlight"
{
    Properties
    {
        _BaseMap("Base Map",2D)="white"{}
        _BaseColor("Base Color",Color)=(1,1,1,1)
        _HighlightColor("Highlight Color",Color)=(0.2,0.85,1,1)
        _HighlightStrength("Highlight Strength",Range(0,3))=0
        _RimPower("Rim Power",Range(0.5,8))=3
        _RimIntensity("Rim Intensity",Range(0,5))=1.5
        _PulseSpeed("Pulse Speed",Range(0,10))=3
        _Smoothness("Smoothness",Range(0,1))=0.55
        _Metallic("Metallic",Range(0,1))=0.05
    }
    SubShader
    {
        Tags{"RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalPipeline"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST,_BaseColor,_HighlightColor;
            float _HighlightStrength,_RimPower,_RimIntensity,_PulseSpeed,_Smoothness,_Metallic;
            CBUFFER_END
            struct A{float4 p:POSITION;float3 n:NORMAL;float2 uv:TEXCOORD0;};
            struct V{float4 p:SV_POSITION;float3 w:TEXCOORD0;float3 n:TEXCOORD1;float2 uv:TEXCOORD2;float fog:TEXCOORD3;};
            V vert(A i){V o;VertexPositionInputs p=GetVertexPositionInputs(i.p.xyz);VertexNormalInputs n=GetVertexNormalInputs(i.n);o.p=p.positionCS;o.w=p.positionWS;o.n=NormalizeNormalPerVertex(n.normalWS);o.uv=TRANSFORM_TEX(i.uv,_BaseMap);o.fog=ComputeFogFactor(p.positionCS.z);return o;}
            half4 frag(V i):SV_Target
            {
                half4 t=SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);half3 b=t.rgb*_BaseColor.rgb;float3 n=normalize(i.n),v=SafeNormalize(GetWorldSpaceViewDir(i.w));Light l=GetMainLight(TransformWorldToShadowCoord(i.w));
                float ndl=saturate(dot(n,l.direction));float3 diffuse=b*l.color*(0.36+ndl*l.shadowAttenuation);float3 h=SafeNormalize(l.direction+v);float spec=pow(saturate(dot(n,h)),lerp(16,128,_Smoothness));float3 specular=spec*lerp(0.04.xxx,b,_Metallic)*l.color;
                float rim=pow(1-saturate(dot(n,v)),_RimPower);float pulse=0.72+0.28*sin(_Time.y*_PulseSpeed);float3 glow=_HighlightColor.rgb*rim*_RimIntensity*_HighlightStrength*pulse;
                return half4(MixFog(diffuse+specular+SampleSH(n)*b+glow,i.fog),t.a*_BaseColor.a);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
