Shader "Unlit/ImageSequenceAnimation"
{
    Properties
    {
        _MainTex ("Image Sequence", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1,1,1,1)
        _HorizontalAmount ("Horizontal Amount", Float) = 4  //关键帧图像的个数
        _VerticalAmount ("Vertical Amount", Float) = 4
        _Speed("Speed", Range(1, 100)) = 30
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }  //序列帧图像的背景通常是透明的

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //计算关键帧的行列
                float time = floor(_Time.y * _Speed);
                float row = floor(time / _HorizontalAmount);
                float column = time - row * _VerticalAmount;

                //构建采样坐标
                half2 uv = i.uv + half2(column, -row);  //对采样坐标进行偏移
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                fixed4 color = tex2D(_MainTex, uv);
                color.rgb *= _Color;

                return color;
            }
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
