Shader "SelfProgram/Smile"
{
	Properties
	{
		_Channel0("Channel0 (RGB)", 2D) = "" {}
		_Channel1("Channel1 (RGB)", 2D) = "" {}
		_Channel2("Channel2 (RGB)", 2D) = "" {}
		_Channel3("Channel3 (RGB)", 2D) = "" {}
		[HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)
	}

	SubShader
	{
		Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}

		Pass
		{
			Name "Smile"

			HLSLPROGRAM

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			#pragma multi_compile_instancing

			#pragma vertex vert
			#pragma fragment frag
			
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			float4 _Channel0_ST;
			TEXTURE2D(_Channel0);              SAMPLER(sampler_Channel0);
			float4 _Channel1_ST;
			TEXTURE2D(_Channel1);              SAMPLER(sampler_Channel1);
			float4 _Channel2_ST;
			TEXTURE2D(_Channel2);              SAMPLER(sampler_Channel2);
			float4 _Channel3_ST;
			TEXTURE2D(_Channel3);              SAMPLER(sampler_Channel3);

			float4 iMouse;

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv :TEXCOORD0;
			};

			struct Varyings
			{
				float2 uv :TEXCOORD0;
				float4 positionCS : SV_POSITION;
				float4 screenPos : TEXCOORD1;	
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.uv = TRANSFORM_TEX(input.uv, _Channel0);

                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
			}

			#define FLT_MAX 3.402823466e+38
            #define FLT_MIN 1.175494351e-38
            #define DBL_MAX 1.7976931348623158e+308
            #define DBL_MIN 2.2250738585072014e-308

			// 将a-b范围的t重新映射到0-1范围
			float remap01(float a, float b, float t)
			{
				return clamp((t-a)/(b-a),0,1);    
			}

			// 将a-b范围的t重新映射到c-d范围
			float remap(float a, float b, float c, float d, float t)
			{
				return clamp(((t-a)/(b-a))*(d-c) + c,0,1);
    
			}

			
			// 用于将uv坐标进行转换至一个自定义矩形中，0——1范围。注意：rect是一个自定义的矩形范围，xy表示矩形的横纵坐标最小的坐标值（一般是左下角），zw表示矩形的横纵坐标最大的坐标值（一般是右上角），而不是矩形的width和height。之所以自定义一个这样的矩形范围，是为了方便各个子模块（眼睛、嘴巴）里面的绘制，因为在这个自定义矩形里坐标范围是0——1的。
			float2 within(float2 uv, half4 rect)
			{
				return (uv-rect.xy)/(rect.zw - rect.xy);    
			}

			// 嘴巴渲染
			half4 Mouth(float2 uv)
			{
				uv -= 0.5; // 将uv范围0到1变为-0.5到0.5，从而(0,0)点在自定义矩形的中心
    
 				half4 col = half4(0.5, 0.18, 0.05, 1.0); // 口腔底色，暗红色
    
    
				uv.y *= 1.5; // 确定嘴型，控制张开程度。
				uv.y -= uv.x*uv.x*2.0; // 确定嘴型，使嘴角上扬。正常情况下，x值不同，y如果相同，则是一条平行于水平坐标轴的线。所以，y = y-x*x，x*x越大，y如果相同，则是一条微笑曲线。*2.是为了控制上扬程度。
    
				float d = length(uv); // 嘴巴的圆心(0,0)
    
				// 牙齿
				float td = length(uv-float2(0.0,0.6)); // 牙齿的圆心(0.,.6)
				float3 toothCol = float3(1,1,1)*smoothstep(0.6,0.35, d);// 确定牙齿的上沿，不能超出嘴巴    
				col.rgb = lerp(col.rgb, toothCol, smoothstep(0.4, 0.37, td)); // 加入牙齿
				// 舌头
				td = length(uv+float2(0.0,0.5));  // 舌头的圆心(0.0,-0.5)
				col.rgb = lerp(col.rgb, float3(1.0, 0.5, 0.5), smoothstep(0.5, 0.2, td)); // 加入舌头
    
				col.a = smoothstep(0.5, 0.48, d); // 确定整个嘴巴的范围
    
				return col;
    
			}



			// 眼睛渲染
			half4 Eye(float2 uv)
			{
				uv -= 0.5;  // 将uv范围0到1变为-0.5到0.5，从而(0,0)点在自定义矩形的中心
    
				float d = length(uv);
    
				half4 irisColor = half4(0.3, 0.5, 1.0, 1.0); //虹膜的颜色，蓝色
				half4 col = half4(1,1,1,1); // 巩膜的颜色，白色
				col = lerp(col, irisColor, smoothstep(0.1, 0.7, d)*0.5);
    
				// 眼角的阴影
				col.rgb *= 1.0 - smoothstep(0.45, 0.5, d)* 0.5 * clamp(-uv.y-uv.x, 0, 1);
				// 眼珠的描边，黑色
				col.rgb = lerp(col.rgb, float3(0,0,0), smoothstep(0.3, 0.28, d));
				// 虹膜
				irisColor.rgb *= 1.0 + smoothstep(0.3, 0.05, d); // 使虹膜的蓝色由外向内有个渐变的效果    
				col.rgb = lerp(col.rgb, irisColor.rgb, smoothstep(0.28, 0.25, d)); //加入虹膜，半径为0.28
				// 瞳孔
				col.rgb = lerp(col.rgb, float3(0,0,0), smoothstep(0.16, 0.14, d)); // 加入瞳孔，半径为0.16，黑色
    
				// 眼球上的高光
				float highlight = smoothstep(0.1, 0.09, length(uv-float2(-0.15, 0.15)));//大高光，右眼大高光圆心(-0.15,0.15),半径为0.1；左眼对称。    
				highlight += smoothstep(0.07, 0.05, length(uv+float2(-0.08, 0.08)));//小高光，右眼小高光圆心(0.08,-0.08),半径为0.07；左眼对称。    
				col.rgb = lerp(col.rgb, float3(1,1,1), highlight);// 加入高光，白色
    
				col.a = smoothstep(0.5, 0.48, d); // 设置眼球的alpha通道，将眼球的半径限制在0.5
    
				return col;
    
			}


			// 头部渲染
			half4 Head(float2 uv)
			{
 				half4 col = half4(0.9, 0.65, 0.1, 1.0); //整张脸的皮肤底色，黄色
    
				float d = length(uv); // 整张脸的圆心为(0,0)
    
				col.a = smoothstep(0.5, 0.49, d); //脸的半径为0.5
				// 脸的边缘（边缘暗色+边缘描边）
				//// 边缘暗色
				float edgeshade = remap01(0.35, 0.5, d);      
				edgeshade *= edgeshade; // 让边缘暗色稍微亮一点
				col.rgb *= 1.0 - edgeshade* 0.5;
				//// 边缘描边
				col.rgb = lerp(col.rgb, float3(0.6, 0.3, 0.1), smoothstep(0.47, 0.48, d)); // 边的颜色为暗黄色
    
				// 额头的高光
				float highlight = smoothstep(0.41, 0.405, d);    
				highlight *= remap(0.41, 0.0, 0.75, 0.0, uv.y); // 确定额头高光的位置，使得uv.y在小于0的时候，remap返回值是负数，从而使高光下半部消失了，只保留上半部，且由下至上渐变亮。
				highlight *= smoothstep(0.18, 0.19, length(uv-float2(0.21, 0.08))); // 眼睛最底下的黄色，右边的眼睛以(0.21,0.08)为圆心，左边的眼睛是以(0.21,-0.08)为圆心。    
				col.rgb = lerp(col.rgb, float3(1,1,1), highlight); //额头的高光为白色
    
				//腮cheek    
				d = length(uv - float2(0.25, -0.2)); // 右边的腮以(0.25,-0.2)为圆心，左边的腮以(-0.25,-0.2)为圆心    
				float cheek = smoothstep(0.2, 0.01, d) * 0.4; // 腮的半径为0.2，从边缘向内红色渐变深。*0.4是让腮红整体变淡。    
				cheek *= smoothstep(0.18,0.17, d); // 这个效果太细微了
				col.rgb = lerp(col.rgb, float3(1.0, 0.1, 0.1), cheek); //腮为红色
    
				return col;
    
			}

			//整个场景渲染（笑脸+背景）
			half4 smiley(float2 uv)
			{
 				half4 col = half4(0.5,1,1,0); // 背景，青色
    
				uv.x = abs(uv.x); // 脸（眼睛、腮对称）的左右两边对称绘制
    
				half4 head = Head(uv); // 头部
				half4 eye = Eye(within(uv, half4(0.03, -0.1, 0.37, 0.25))); // 眼睛，右眼自定义矩形左下角坐标(.03, -.1)右上角坐标(.37, .25)，左眼自定义矩形对称分布。
				half4 mouth = Mouth(within(uv, half4(-0.3, -0.4, 0.3, -0.1))); // 嘴巴，自定义矩形左下角坐标(-.3, -.4)右上角坐标(.3, -.1)。
            
    
				col = lerp(col, head, head.a); // 加入头部
				col = lerp(col, eye, eye.a); // 加入眼睛
				col = lerp(col, mouth, mouth.a); // 加入嘴巴
    
				return col;
    
			}

			half4 frag(Varyings input) : SV_Target {
				half4 fragColor = half4(1, 1, 1, 1);
				float2 uv = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)); // 屏幕空间归一化至0——1范围。
				uv -= 0.5;// 从0——1范围变为-0.5——0.5范围，坐标(0,0)由左下角移到矩形中心，便于后面绘制。
				uv.x *= _ScreenParams.x / _ScreenParams.y;// 将矩形屏幕变为正方形屏幕。由于屏幕是个800*450的矩形，如果不处理，画出的圆会是椭圆。用x*(screenwidth/screenheight)能得到按屏幕宽高比例缩小的x坐标。				
				return smiley(uv);
			}

			ENDHLSL
		}
	}
}
