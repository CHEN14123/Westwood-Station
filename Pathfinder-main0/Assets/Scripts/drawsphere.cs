using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class drawsphere : MonoBehaviour
{
    private GameObject[] agent;
    public float scale;
   


    // Update is called once per frame
    void Update()
    {
        agent = GameObject.FindGameObjectsWithTag("Agent");
        Vector3 agentposition = transform.position;
        foreach (GameObject go in agent)
        {
            agentposition = go.transform.position;
        }
        
    }

    void LateUpdate()
    {

        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.position = this.transform.position;
        sphere.transform.localScale = new Vector3(scale, scale, scale);

        var cubeRenderer = sphere.GetComponent<Renderer>();

        //Call SetColor using the shader property name "_Color" and setting the color to red
        cubeRenderer.material.SetColor("_Color", Color.blue);


    }
}
