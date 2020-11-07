Shader "SelfProgram/ShadertoyTemplate"
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
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float2 uv :TEXCOORD0;
				float4 positionCS : SV_POSITION;
				float4 screenPos : TEXCOORD1;				
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

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

			half4 frag(Varyings input) : SV_Target {
				half4 fragColor = half4(1, 1, 1, 1);
				float2 uv = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN));

				return half4(uv, 1, 1);
			}

			ENDHLSL
		}
	}
}
