Shader "Unlit/LineShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LineWidth ("LineWidth", float) = 1.0
        _LineColor ("LineColor", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    CGINCLUDE
    #include "UnityCG.cginc"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;
        UNITY_FOG_COORDS(1)
        float4 vertex : SV_POSITION;
    };

    uniform float _LineWidth;
    uniform float4 _LineColor;

    sampler2D _MainTex;
    float4 _MainTex_ST;

    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = v.vertex;
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
    }

    v2f geom_biuld(float4 vec, float2 uv)
    {
        v2f ret;
        ret.vertex = UnityObjectToClipPos(vec);
        ret.uv = uv;
        UNITY_TRANSFER_FOG(ret, ret.vertex);
        return ret;
    }

    void geom_append(v2f o0, v2f o1, v2f o2, inout TriangleStream<v2f> outStream)
    {
        outStream.Append(o0);
        outStream.Append(o1);
        outStream.Append(o2);
        outStream.RestartStrip();
    }

    [maxvertexcount(30)]
    void geom (line v2f input[2], inout TriangleStream<v2f> outStream)
    {
        // 線分の長さを求める
        float4 vec_i0 = input[0].vertex, vec_i1 = input[1].vertex;
        float4 vec_d = vec_i1 - vec_i0;
        float len_d = length(vec_d);
        if (len_d == 0) return;

        // 単位ベクトル等を作る
        float4 vec_e0 = vec_d / length(vec_d);
        float4 vec_e1 = float4(-vec_e0.z, vec_e0.y, vec_e0.x, vec_e0.w);
        float4 vec_halfwidth = vec_e1 * _LineWidth * 0.5;
        float4 vec_height = float4(0, 10000.0, 0, 0);

        // 立体の頂点を作る
        float2 uv0 = input[0].uv, uv1 = input[1].uv;
        v2f o000 = geom_biuld(vec_i0 + vec_halfwidth, uv0);
        v2f o001 = geom_biuld(vec_i0 - vec_halfwidth, uv0);
        v2f o010 = geom_biuld(vec_i1 + vec_halfwidth, uv1);
        v2f o011 = geom_biuld(vec_i1 - vec_halfwidth, uv1);
        v2f o100 = geom_biuld(vec_i0 + vec_halfwidth + vec_height, uv0);
        v2f o101 = geom_biuld(vec_i0 - vec_halfwidth + vec_height, uv0);
        v2f o110 = geom_biuld(vec_i1 + vec_halfwidth + vec_height, uv1);
        v2f o111 = geom_biuld(vec_i1 - vec_halfwidth + vec_height, uv1);

        // 立体の面を張る
        geom_append(o000, o010, o011, outStream);
        geom_append(o011, o001, o000, outStream);
        geom_append(o000, o100, o110, outStream);
        geom_append(o110, o010, o000, outStream);
        geom_append(o010, o110, o111, outStream);
        geom_append(o111, o011, o010, outStream);
        geom_append(o011, o111, o101, outStream);
        geom_append(o101, o001, o011, outStream);
        geom_append(o001, o101, o100, outStream);
        geom_append(o100, o000, o001, outStream);
    }

    fixed4 frag (v2f i) : SV_Target
    {
        // sample the texture
        fixed4 col = _LineColor; //tex2D(_MainTex, i.uv);
        // apply fog
        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
    }
    ENDCG

    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "Queue" = "Geometry+1"
            }

        LOD 100

        Pass
        {
            ZWrite Off
            Cull Back
            ZTest GEqual
            ColorMask 0
            Stencil {
                Ref 0
                Comp Always
                Pass IncrSat
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            ZWrite Off
            Cull Front
            ZTest GEqual
            ColorMask 0
            Stencil {
                Ref 0
                Comp Always
                Pass DecrSat
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            ZWrite Off
            Cull Back
            ZTest GEqual
            ColorMask RGBA
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil {
                Ref 1
                Comp Equal
                Pass IncrSat
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            ENDCG
        }
    }
}
