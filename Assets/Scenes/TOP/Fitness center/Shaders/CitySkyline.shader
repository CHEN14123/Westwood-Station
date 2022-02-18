// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "CitySkyline"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
		_AtlasDiffuse("Atlas Diffuse", 2D) = "white" {}
		_cubemap("cubemap", CUBE) = "white" {}
		_Atlas_Reflectivitymask("Atlas_Reflectivitymask", 2D) = "white" {}
		_cubemapblurriness("cubemap blurriness", Range( 0 , 1)) = 0
		_Fresnelpower("Fresnel power", Range( 0 , 5)) = 0
		_Fresnelintensity("Fresnel intensity", Range( 0 , 5)) = 0
		_Fresnelcolor("Fresnel color", Color) = (1,1,1,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldRefl;
			INTERNAL_DATA
			float3 worldPos;
			float3 worldNormal;
		};

		uniform sampler2D _AtlasDiffuse;
		uniform float4 _AtlasDiffuse_ST;
		uniform samplerCUBE _cubemap;
		uniform float _cubemapblurriness;
		uniform float _Fresnelintensity;
		uniform float _Fresnelpower;
		uniform float4 _Fresnelcolor;
		uniform sampler2D _Atlas_Reflectivitymask;
		uniform float4 _Atlas_Reflectivitymask_ST;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float2 uv_AtlasDiffuse = i.uv_texcoord * _AtlasDiffuse_ST.xy + _AtlasDiffuse_ST.zw;
			float4 tex2DNode1 = tex2D( _AtlasDiffuse,uv_AtlasDiffuse);
			float3 worldrefVec9 = i.worldRefl;
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float3 worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float fresnelFinalVal4 = (0.0 + _Fresnelintensity*pow( 1.0 - dot( worldNormal, worldViewDir ) , _Fresnelpower));
			float2 uv_Atlas_Reflectivitymask = i.uv_texcoord * _Atlas_Reflectivitymask_ST.xy + _Atlas_Reflectivitymask_ST.zw;
			o.Albedo = lerp( tex2DNode1 , ( tex2DNode1 * ( texCUBElod( _cubemap,float4( worldrefVec9, _cubemapblurriness)) + ( fresnelFinalVal4 * _Fresnelcolor ) ) ) , tex2D( _Atlas_Reflectivitymask,uv_Atlas_Reflectivitymask).x ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			# include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD6;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				float4 texcoords01 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				fixed3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.texcoords01 = float4( v.texcoord.xy, v.texcoord1.xy );
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			fixed4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.texcoords01.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				fixed3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.worldRefl = -worldViewDir;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=5105
2567;29;1666;974;1991.116;822.6951;2.087912;True;True
Node;AmplifyShaderEditor.SamplerNode;3;-587,312;Float;True;Property;_Atlas_Reflectivitymask;Atlas_Reflectivitymask;2;0;Assets/Fitness center/Textures/Atlas_Reflectivitymask.tga;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False
Node;AmplifyShaderEditor.WorldReflectionVector;9;-1026.698,-266.3997;Float;False;0;FLOAT3;0,0,0;False
Node;AmplifyShaderEditor.RangedFloatNode;10;-903.6,105.9002;Float;False;Property;_cubemapblurriness;cubemap blurriness;3;0;0;0;1
Node;AmplifyShaderEditor.SamplerNode;2;-578,109;Float;True;Property;_cubemap;cubemap;1;0;Assets/Fitness center/Textures/cubemap.png;True;0;False;white;Auto;False;Object;-1;MipLevel;Cube;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;1.0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1.0;False
Node;AmplifyShaderEditor.SamplerNode;1;-568,-316;Float;True;Property;_AtlasDiffuse;Atlas Diffuse;0;0;Assets/Fitness center/Textures/Atlas Diffuse.tga;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False
Node;AmplifyShaderEditor.LerpOp;5;-60.29849,74.50026;Float;False;0;FLOAT4;0.0;False;1;COLOR;0,0,0,0;False;2;FLOAT4;0.0;False
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-248.7999,80.70026;Float;False;0;FLOAT4;0.0,0,0,0;False;1;COLOR;0.0,0,0,0;False
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;573.6997,53.69999;Float;False;True;2;Float;ASEMaterialInspector;Standard;CitySkyline;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;0;False;0;0;Opaque;0.5;True;True;0;False;Opaque;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;False;0;255;255;0;0;0;0;False;0;4;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;Add;Add;0;False;0;0,0,0,0;VertexOffset;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0.0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;OBJECT;0.0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;13;OBJECT;0.0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False
Node;AmplifyShaderEditor.FresnelNode;4;2.700134,222.6006;Float;False;0;FLOAT3;0,0,0;False;1;FLOAT;0.0;False;2;FLOAT;1.0;False;3;FLOAT;5.0;False
Node;AmplifyShaderEditor.RangedFloatNode;13;-300.9302,362.2112;Float;False;Property;_Fresnelintensity;Fresnel intensity;4;0;0;0;5
Node;AmplifyShaderEditor.RangedFloatNode;14;-293.9302,449.2112;Float;False;Property;_Fresnelpower;Fresnel power;4;0;0;0;5
Node;AmplifyShaderEditor.SimpleAddOpNode;12;343.7695,294.4112;Float;False;0;FLOAT4;0.0;False;1;COLOR;0.0,0,0,0;False
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;16;232.0694,499.2112;Float;False;0;FLOAT;0.0,0,0,0;False;1;COLOR;0.0;False
Node;AmplifyShaderEditor.ColorNode;15;-1.930365,498.2112;Float;False;Property;_Fresnelcolor;Fresnel color;6;0;1,1,1,0
WireConnection;2;1;9;0
WireConnection;2;2;10;0
WireConnection;5;0;1;0
WireConnection;5;1;11;0
WireConnection;5;2;3;0
WireConnection;11;0;1;0
WireConnection;11;1;12;0
WireConnection;0;0;5;0
WireConnection;4;2;13;0
WireConnection;4;3;14;0
WireConnection;12;0;2;0
WireConnection;12;1;16;0
WireConnection;16;0;4;0
WireConnection;16;1;15;0
ASEEND*/
//CHKSM=40BC18842827DB359A497EF9ECCBA724DAA027FA