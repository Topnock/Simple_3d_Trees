Shader "Billboard" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        //_Glossiness ("Smoothness", Range(0,1)) = 0.5
        //_Metallic ("Metallic", Range(0,1)) = 0.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        }
    SubShader {
        Tags {"RenderType"="Opaque" "DisableBatching"="True" "ForceNoShadowCasting"="True"}
        LOD 200
        CGPROGRAM
        #pragma surface surf Standard vertex:vert alphatest:_Cutoff noshadow
        sampler2D _MainTex;
        struct Input {
            float2 uv_MainTex;
        };

        //half _Glossiness;
        //half _Metallic;
        fixed4 _Color;

        void vert(inout appdata_full v, out Input o){
            UNITY_INITIALIZE_OUTPUT(Input, o);
            // apply object scale
            v.vertex.xy *= float2(length(unity_ObjectToWorld._m00_m10_m20), length(unity_ObjectToWorld._m01_m11_m21));
            // get the camera basis vectors
            float3 forward = -normalize(UNITY_MATRIX_V._m20_m21_m22);
            float3 up = float3(0, 1, 0);
            float3 right = normalize(UNITY_MATRIX_V._m00_m01_m02);
            // rotate to face camera
            float4x4 rotationMatrix = float4x4(right, 0, up, 0, forward, 0, 0, 0, 0, 1);
            v.vertex = mul(v.vertex, rotationMatrix);
            v.normal = mul(v.normal, rotationMatrix);
            // undo object to world transform surface shader will apply
            v.vertex.xyz = mul((float3x3)unity_WorldToObject, v.vertex.xyz);
            v.normal = mul(v.normal, (float3x3)unity_ObjectToWorld);
        }
        void surf (Input IN, inout SurfaceOutputStandard o) {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            //o.Metallic = _Metallic;
            //o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Transparent/VertexLit"
}