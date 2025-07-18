using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof (MeshFilter))]
[RequireComponent(typeof (MeshRenderer))]
public class BadMinecraft : MonoBehaviour
{
    Mesh mesh;

    void Start()
    {
        MakeCube();
    }

    void MakeCube() {
        Vector3[] c =
        {
            new Vector3(0 , 0, 0), // 0
            new Vector3(1 , 0, 0), // 1
            new Vector3(1 , 1, 0), // 2
            new Vector3(0 , 1, 0), // 3
            new Vector3(0 , 1, 1), // 4
            new Vector3(1 , 1, 1), // 5
            new Vector3(1 , 0, 1), // 6
            new Vector3(0 , 0, 1)  // 7
        };

        Vector3[] vertices = new Vector3[]
        { 
            // South Face
            c[0], c[1], c[2], c[3], // 0-3
            // Up Face
            c[3], c[2], c[5], c[4], // 4-7
            // East Face
            c[1], c[6], c[5], c[2],
            // West Face
            c[7], c[0], c[3], c[4],
            // North Face
            c[6], c[7], c[4], c[5],
            // Down Face
            c[7], c[6], c[1], c[0]
        };

        var south = Vector3.back;
        var up = Vector3.up;
        var right = Vector3.right;
        var left = Vector3.left;
        var north = Vector3.forward;
        var down = Vector3.down;
        Vector3[] normals = new Vector3[]
        {
            south, south, south, south,
            up, up, up, up, 
            right, right, right, right, 
            left, left, left, left, 
            north, north, north, north, 
            down, down, down, down
        };

        Vector2[] uvs = new Vector2[]
        {
            new Vector2(0f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0.5f), new Vector2(0f, 0.5f), //south
            new Vector2(0f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 1f), new Vector2(0f, 1f), //up
            new Vector2(0f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0.5f), new Vector2(0f, 0.5f), //east
            new Vector2(0f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0.5f), new Vector2(0f, 0.5f), //west
            new Vector2(0f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0.5f), new Vector2(0f, 0.5f), //north
            new Vector2(0.5f, 0f), new Vector2(1f, 0f), new Vector2(1f, 0.5f), new Vector2(0.5f, 0.5f), //down
        };
        
        int[] tris =
        {
            // South Face
            0, 3, 2,
            0, 2, 1,
            
            // Up Face
            4, 7, 6,
            4, 6, 5,
            
            // East Face
            8, 11, 10,
            8, 10, 9,
            
            // West Face
            12, 15, 14,
            12, 14, 13,
            
            // North Face
            16, 19, 18,
            16, 18, 17,
            
            // Down Face
            20, 23, 22,
            20, 22, 21
        };
        
        mesh = GetComponent<MeshFilter>().mesh;
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.normals = normals;
        mesh.triangles = tris;
    }

    private void OnDestroy()
    {
        Destroy(mesh);
    }
}
