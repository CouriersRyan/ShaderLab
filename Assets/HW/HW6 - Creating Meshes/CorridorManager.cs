using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CorridorManager : MonoBehaviour
{
    [SerializeField] private GameObject corridorStraight;

    [SerializeField] private GameObject corridorTurn;

    [SerializeField] private int corridors = 1;

    // Start is called before the first frame update
    void Start()
    {
        for (int i = 0; i < corridors; i++)
        {
            var straight = Instantiate(corridorStraight);
            straight.GetComponent<MeshRenderer>().material.SetInt("_Iteration", i);
            straight.GetComponent<MeshRenderer>().material.SetInt("_TotalInt", corridors);
        }
    }
}
