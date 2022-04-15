Shader "Unlit/GlassRefraction"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}  //法线贴图
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}  //环境映射
		_Distortion ("Distortion", Range(0, 100)) = 10  //折射时图像的扭曲程度
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0  //反射和折射的混合，0为反射，1为折射
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Opaque"  }

        GrabPass { "_RefractionTex" }  //把屏幕图像存到这个变量中

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;  //法线方向
				float4 tangent : TANGENT;   //切线方向
				float2 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;  //屏幕图像的采样坐标
				float4 uv : TEXCOORD1;  //xy存储纹理图像的uv坐标，zw存储法线图像的uv坐标
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4;  
            };

            sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
                
                fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 

                //存储TBN矩阵和顶点的世界空间坐标
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                //读取切线空间下的法线坐标
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));	

				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;  //对屏幕图像的采样坐标进行偏移，模拟折射效果
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;  //计算真正的屏幕坐标
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;  //对屏幕图像进行采样

                //把法线从切线空间变换到世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

                return fixed4(finalColor, 1);
            }
            ENDCG
        }
    }
}
