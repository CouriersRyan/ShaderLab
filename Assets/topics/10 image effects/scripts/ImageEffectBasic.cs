using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ImageEffectBasic : MonoBehaviour
{
    public Material effectMat;

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        
        Graphics.Blit(src, dest, effectMat);
    }
}
