// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/SoftOcclusionWind" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {  }
        _Cutoff ("Alpha cutoff", Range(0.25,0.9)) = 0.5
        _BaseLight ("Base Light", Range(0, 1)) = 0.35
        _AO ("Amb. Occlusion", Range(0, 10)) = 2.4
        _Occlusion ("Dir Occlusion", Range(0, 20)) = 7.5
        _MotionPowerWeightMask("MotionPowerWeightMask", 2D) = "white" {}
		_MotionSpeed("MotionSpeed", Range( 0 , 10)) = 1
		_MotionRange("MotionRange", Range( 0 , 10)) = 0.5

        // These are here only to provide default values
        [HideInInspector] _TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
        [HideInInspector] _TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
        [HideInInspector] _SquashAmount ("Squash", Float) = 1
    }

    SubShader {
        Tags {
            "Queue" = "Transparent-99"
            "IgnoreProjector"="True"
            "RenderType" = "TreeTransparentCutout"
            "DisableBatching"="True"
        }
        Cull Off
        ColorMask RGB

        Pass {
            Lighting On

            CGPROGRAM
            #pragma vertex leaves
            #pragma fragment frag
            #pragma multi_compile_fog
            //#pragma multi_compile_instancing
            #include "HLSLSupport.cginc"
            #include "UnityCG.cginc"
            #include "TerrainEngine.cginc"

            float _Occlusion, _AO, _BaseLight;
            fixed4 _Color;

            #ifdef USE_CUSTOM_LIGHT_DIR
            CBUFFER_START(UnityTerrainImposter)
                float3 _TerrainTreeLightDirections[4];
                float4 _TerrainTreeLightColors[4];
            CBUFFER_END
            #endif

            CBUFFER_START(UnityPerCamera2)
            // float4x4 _CameraToWorld;
            CBUFFER_END

            uniform float _MotionSpeed;
		    uniform float _MotionRange;
		    uniform sampler2D _MotionPowerWeightMask; 
            float _HalfOverCutoff;

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                half4 color : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f leaves(appdata_tree v)
            {
                //Vertex displacement part
                float mulTime44 = _Time.y * _MotionSpeed;
                float3 ase_vertexNormal = v.normal.xyz;
                float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
                float2 appendResult24 = float2(v.texcoord.xy.x, v.texcoord.xy.y);
                float4 tex2DNode53 = tex2Dlod(_MotionPowerWeightMask,float4(appendResult24, 0, 0.0));
                v.vertex.xyz += ( ase_vertexNormal * ( ( sin( ( mulTime44 + ( ase_worldPos.x + ase_worldPos.z ) ) ) * _MotionRange ) * tex2DNode53.r * tex2DNode53.g * tex2DNode53.b ) );
                v.vertex.w = 1;
                //
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TerrainAnimateTree(v.vertex, v.color.w);

                float3 viewpos = UnityObjectToViewPos(v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                float4 lightDir = 0;
                float4 lightColor = 0;
                lightDir.w = _AO;

                float4 light = UNITY_LIGHTMODEL_AMBIENT;

                for (int i = 0; i < 4; i++) {
                    float atten = 1.0;
                    #ifdef USE_CUSTOM_LIGHT_DIR
                        lightDir.xyz = _TerrainTreeLightDirections[i];
                        lightColor = _TerrainTreeLightColors[i];
                    #else
                            float3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
                            toLight.z *= -1.0;
                            lightDir.xyz = mul( (float3x3)unity_CameraToWorld, normalize(toLight) );
                            float lengthSq = dot(toLight, toLight);
                            atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);

                            lightColor.rgb = unity_LightColor[i].rgb;
                    #endif

                    lightDir.xyz *= _Occlusion;
                    float occ =  dot (v.tangent, lightDir);
                    occ = max(0, occ);
                    occ += _BaseLight;
                    light += lightColor * (occ * atten);
                }

                o.color = light * _Color * _TreeInstanceColor;
                o.color.a = 0.5 * _HalfOverCutoff;

                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            v2f bark(appdata_tree v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TerrainAnimateTree(v.vertex, v.color.w);

                float3 viewpos = UnityObjectToViewPos(v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                float4 lightDir = 0;
                float4 lightColor = 0;
                lightDir.w = _AO;

                float4 light = UNITY_LIGHTMODEL_AMBIENT;

                for (int i = 0; i < 4; i++) {
                    float atten = 1.0;
                    #ifdef USE_CUSTOM_LIGHT_DIR
                        lightDir.xyz = _TerrainTreeLightDirections[i];
                        lightColor = _TerrainTreeLightColors[i];
                    #else
                            float3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
                            toLight.z *= -1.0;
                            lightDir.xyz = mul( (float3x3)unity_CameraToWorld, normalize(toLight) );
                            float lengthSq = dot(toLight, toLight);
                            atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);

                            lightColor.rgb = unity_LightColor[i].rgb;
                    #endif


                    float diffuse = dot (v.normal, lightDir.xyz);
                    diffuse = max(0, diffuse);
                    diffuse *= _AO * v.tangent.w + _BaseLight;
                    light += lightColor * (diffuse * atten);
                }

                light.a = 1;
                o.color = light * _Color * _TreeInstanceColor;

                #ifdef WRITE_ALPHA_1
                o.color.a = 1;
                #endif

                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
}

            sampler2D _MainTex;
            fixed _Cutoff;

            fixed4 frag(v2f input) : SV_Target
            {
                fixed4 c = tex2D( _MainTex, input.uv.xy);
                c.rgb *= input.color.rgb;

                clip (c.a - _Cutoff);
                UNITY_APPLY_FOG(input.fogCoord, c);
                return c;
            }
            ENDCG
        }

        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
            #include "TerrainEngine.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                fixed4 color : COLOR;
                float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            v2f vert( appdata v )
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TerrainAnimateTree(v.vertex, v.color.w);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = v.texcoord;
                return o;
            }

            sampler2D _MainTex;
            fixed _Cutoff;

            float4 frag( v2f i ) : SV_Target
            {
                fixed4 texcol = tex2D( _MainTex, i.uv );
                clip( texcol.a - _Cutoff );
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }

    // This subshader is never actually used, but is only kept so
    // that the tree mesh still assumes that normals are needed
    // at build time (due to Lighting On in the pass). The subshader
    // above does not actually use normals, so they are stripped out.
    // We want to keep normals for backwards compatibility with Unity 4.2
    // and earlier.
    SubShader {
        Tags {
            "Queue" = "AlphaTest"
            "IgnoreProjector"="True"
            "RenderType" = "TransparentCutout"
        }
        Cull Off
        ColorMask RGB
        Pass {
            Tags { "LightMode" = "Vertex" }
            AlphaTest GEqual [_Cutoff]
            Lighting On
            Material {
                Diffuse [_Color]
                Ambient [_Color]
            }
            SetTexture [_MainTex] { combine primary * texture DOUBLE, texture }
        }
    }

    Dependency "BillboardShader" = "Hidden/Nature/Tree Soft Occlusion Leaves Rendertex"
    Fallback "Daggerfall/Default"
}