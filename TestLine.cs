using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class TestLine : MonoBehaviour
{
    // 平面上の頂点座標（５頂点に固定）
    [SerializeField]
    Vector2 vertex0, vertex1, vertex2, vertex3, vertex4;

    // 線の幅
    float _lineWidth; public float lineWidth
    {
        set
        {
            _lineWidth = value;
            GetComponent<Renderer>().sharedMaterial.SetFloat("_LineWidth", _lineWidth);
        }
        get { return _lineWidth; }
    }

    // 線の色
    Color _lineColor; public Color lineColor
    {
        set
        {
            _lineColor = value;
            GetComponent<Renderer>().sharedMaterial.SetColor("_LineColor", lineColor);
        }
        get { return _lineColor; }
    }

    // 地形のスケール
    float _terrainScale; public float terrainScale
    {
        set
        {
            _terrainScale = value;
            if (terrainData == null) return;
            terrainData.size = new Vector3(
                terrainOriginalSize.x,
                terrainOriginalSize.y * _terrainScale,
                terrainOriginalSize.z);
        }
        get { return _terrainScale; }
    }

    TerrainData terrainData;
    Vector3 terrainOriginalSize = new Vector3(1000f, 600f, 1000f);

    void Awake()
    {
        terrainData = GameObject.Find("Terrain")?.GetComponent<Terrain>()?.terrainData;
        if (terrainData != null) terrainData.size = terrainOriginalSize;
    }

    // Start is called before the first frame update
    void Start()
    {

        vertex0 = new Vector2(150, 150);
        vertex1 = new Vector2(850, 150);
        vertex2 = new Vector2(850, 850);
        vertex3 = new Vector2(150, 850);
        vertex4 = new Vector2(150, 150);
        lineWidth = 5;
        _lineColor.a = 1;
        SetLineMesh();
    }

    // Update is called once per frame
    void Update()
    {
    }

    public void SetLineMesh()
    {
        Mesh mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;
        mesh.vertices = new Vector3[] {
                new Vector3(vertex0.x, 0, vertex0.y),
                new Vector3(vertex1.x, 0, vertex1.y),
                new Vector3(vertex2.x, 0, vertex2.y),
                new Vector3(vertex3.x, 0, vertex3.y),
                new Vector3(vertex4.x, 0, vertex4.y),
            };
        mesh.SetIndices(new int[] { 0, 1, 2, 3, 4 }, MeshTopology.LineStrip, 0);
    }
}

[CustomEditor(typeof(TestLine))]
public class TestLineUI : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        TestLine testLine = target as TestLine;

        if (GUILayout.Button("頂点情報の更新"))
        {
            testLine.SetLineMesh();
        }

        GUILayout.Box("", GUILayout.ExpandWidth(true), GUILayout.Height(10));

        testLine.lineColor = EditorGUILayout.ColorField("線の色", testLine.lineColor);
        testLine.lineWidth = EditorGUILayout.Slider("線の幅", testLine.lineWidth, 1f, 20f);
        testLine.terrainScale = EditorGUILayout.Slider("地形のスケール", testLine.terrainScale, 0.1f, 1f);
    }
}
