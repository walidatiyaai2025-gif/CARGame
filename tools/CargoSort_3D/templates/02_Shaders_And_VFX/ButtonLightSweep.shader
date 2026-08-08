Shader "CargoSort/UI/ButtonLightSweep"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture",2D)="white"{}
        _Color("Tint",Color)=(1,1,1,1)
        _SweepColor("Sweep Color",Color)=(1,1,1,0.8)
        _SweepWidth("Sweep Width",Range(0.02,0.5))=0.16
        _SweepSoftness("Sweep Softness",Range(0.005,0.5))=0.10
        _SweepSpeed("Sweep Speed",Range(0,4))=0.7
        _SweepAngle("Sweep Angle",Range(-2,2))=0.35
        _PulseAmount("Pulse Amount",Range(0,0.5))=0.08
        _PulseSpeed("Pulse Speed",Range(0,10))=2.5
        [HideInInspector]_StencilComp("Stencil Comparison",Float)=8
        [HideInInspector]_Stencil("Stencil ID",Float)=0
        [HideInInspector]_StencilOp("Stencil Operation",Float)=0
        [HideInInspector]_StencilWriteMask("Stencil Write Mask",Float)=255
        [HideInInspector]_StencilReadMask("Stencil Read Mask",Float)=255
        [HideInInspector]_ColorMask("Color Mask",Float)=15
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True"}
        Stencil {Ref[_Stencil] Comp[_StencilComp] Pass[_StencilOp] ReadMask[_StencilReadMask] WriteMask[_StencilWriteMask]}
        Cull Off Lighting Off ZWrite Off ZTest[unity_GUIZTestMode] Blend SrcAlpha OneMinusSrcAlpha ColorMask[_ColorMask]
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            sampler2D _MainTex; float4 _MainTex_ST; fixed4 _Color,_SweepColor; float _SweepWidth,_SweepSoftness,_SweepSpeed,_SweepAngle,_PulseAmount,_PulseSpeed;
            struct appdata_t{float4 vertex:POSITION;float4 color:COLOR;float2 texcoord:TEXCOORD0;};
            struct v2f{float4 vertex:SV_POSITION;fixed4 color:COLOR;float2 uv:TEXCOORD0;};
            v2f vert(appdata_t i){v2f o;o.vertex=UnityObjectToClipPos(i.vertex);o.uv=TRANSFORM_TEX(i.texcoord,_MainTex);o.color=i.color*_Color;return o;}
            fixed4 frag(v2f i):SV_Target{fixed4 b=tex2D(_MainTex,i.uv)*i.color;float p=frac(_Time.y*_SweepSpeed)*1.8-0.4;float d=abs(i.uv.x+i.uv.y*_SweepAngle-p);float s=1.0-smoothstep(_SweepWidth,_SweepWidth+_SweepSoftness,d);float pulse=1.0+sin(_Time.y*_PulseSpeed)*_PulseAmount;return fixed4(b.rgb*pulse+_SweepColor.rgb*s*_SweepColor.a*b.a,b.a);}
            ENDHLSL
        }
    }
}
