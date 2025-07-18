using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof (MeshFilter))]
[RequireComponent(typeof (MeshRenderer))]
public class ProceduralCube : MonoBehaviour
{
    Mesh mesh;

    void Start()
    {
        MakeCube();
    }

    void MakeCube()
    {
        Vector3[] vertices =
        {
            new Vector3(0 , 0, 0),
            new Vector3(1 , 0, 0),
            new Vector3(1 , 1, 0),
            new Vector3(0 , 1, 0),
            new Vector3(0 , 1, 1),
            new Vector3(1 , 1, 1),
            new Vector3(1 , 0, 1),
            new Vector3(0 , 0, 1)
        };

        int[] tris =
        {
            // South Face
            0, 3, 2,
            0, 2, 1,
            
            // Up Face
            3, 4, 5,
            3, 5, 2,
            
            // East Face
            1, 2, 5,
            1, 5, 6,
            
            // West Face
            0, 7, 4,
            0, 4, 3,
            
            // North Face
            7, 6, 5,
            7, 5, 4,
            
            // Down Face
            0, 6, 7,
            0, 1, 6
        };

        mesh = GetComponent<MeshFilter>().mesh;
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = tris;
    }

    private void OnDestroy()
    {
        Destroy(mesh);
    }
}
