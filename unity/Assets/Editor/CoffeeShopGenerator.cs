using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;

public class CoffeeShopGenerator
{
    [MenuItem("3Ducate/Generate Coffee Shop Scene")]
    public static void GenerateScene()
    {
        // Create a new scene
        UnityEngine.SceneManagement.Scene newScene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
        
        // Group for shop environment
        GameObject environment = new GameObject("Environment");

        // Floor
        GameObject floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
        floor.name = "Floor";
        floor.transform.localScale = new Vector3(2, 1, 2);
        floor.transform.parent = environment.transform;
        
        // Define some basic colors using primitive materials
        Material woodMaterial = new Material(Shader.Find("Standard")) { color = new Color(0.4f, 0.25f, 0.1f) };
        Material wallMaterial = new Material(Shader.Find("Standard")) { color = new Color(0.9f, 0.9f, 0.85f) };
        Material metalMaterial = new Material(Shader.Find("Standard")) { color = Color.gray };
        metalMaterial.SetFloat("_Metallic", 0.8f);

        floor.GetComponent<Renderer>().sharedMaterial = woodMaterial;

        // Walls
        GameObject wall1 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        wall1.name = "Wall_Back";
        wall1.transform.position = new Vector3(0, 2.5f, 10);
        wall1.transform.localScale = new Vector3(20, 5, 0.5f);
        wall1.GetComponent<Renderer>().sharedMaterial = wallMaterial;
        wall1.transform.parent = environment.transform;

        GameObject wall2 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        wall2.name = "Wall_Left";
        wall2.transform.position = new Vector3(-10, 2.5f, 0);
        wall2.transform.localScale = new Vector3(0.5f, 5, 20);
        wall2.GetComponent<Renderer>().sharedMaterial = wallMaterial;
        wall2.transform.parent = environment.transform;

        GameObject wall3 = GameObject.CreatePrimitive(PrimitiveType.Cube);
        wall3.name = "Wall_Right";
        wall3.transform.position = new Vector3(10, 2.5f, 0);
        wall3.transform.localScale = new Vector3(0.5f, 5, 20);
        wall3.GetComponent<Renderer>().sharedMaterial = wallMaterial;
        wall3.transform.parent = environment.transform;

        // Counter
        GameObject counter = GameObject.CreatePrimitive(PrimitiveType.Cube);
        counter.name = "Counter";
        counter.transform.position = new Vector3(0, 1f, 5f);
        counter.transform.localScale = new Vector3(8, 2, 2);
        counter.GetComponent<Renderer>().sharedMaterial = woodMaterial;
        counter.transform.parent = environment.transform;

        // Coffee Machine on Counter
        GameObject coffeeMachine = GameObject.CreatePrimitive(PrimitiveType.Cube);
        coffeeMachine.name = "Coffee Machine";
        coffeeMachine.transform.position = new Vector3(-2, 2.5f, 5f);
        coffeeMachine.transform.localScale = new Vector3(1.5f, 1, 1);
        coffeeMachine.GetComponent<Renderer>().sharedMaterial = metalMaterial;
        coffeeMachine.transform.parent = environment.transform;

        // Waiter (Behind Counter)
        GameObject waiter = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        waiter.name = "Waiter (Barista)";
        waiter.transform.position = new Vector3(0, 1.5f, 7f);
        waiter.GetComponent<Renderer>().sharedMaterial = new Material(Shader.Find("Standard")) { color = Color.black }; // Uniform
        
        // Waiter head
        GameObject waiterHead = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        waiterHead.name = "Head";
        waiterHead.transform.position = new Vector3(0, 2.7f, 7f);
        waiterHead.transform.localScale = new Vector3(0.8f, 0.8f, 0.8f);
        waiterHead.transform.SetParent(waiter.transform);

        // Person / Customer (In front of Counter)
        GameObject customer = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        customer.name = "Customer";
        customer.transform.position = new Vector3(0, 1.5f, 2f);
        customer.GetComponent<Renderer>().sharedMaterial = new Material(Shader.Find("Standard")) { color = new Color(0.2f, 0.5f, 0.8f) };
        
        // Customer head
        GameObject customerHead = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        customerHead.name = "Head";
        customerHead.transform.position = new Vector3(0, 2.7f, 2f);
        customerHead.transform.localScale = new Vector3(0.8f, 0.8f, 0.8f);
        customerHead.transform.SetParent(customer.transform);

        // Add some tables and chairs
        Vector3[] tablePositions = new Vector3[] {
            new Vector3(-5f, 0.5f, -2f),
            new Vector3(5f, 0.5f, -2f),
            new Vector3(-5f, 0.5f, -6f),
            new Vector3(5f, 0.5f, -6f)
        };

        int count = 1;
        foreach (var pos in tablePositions)
        {
            GameObject table = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            table.name = "Table_" + count;
            table.transform.position = pos;
            table.transform.localScale = new Vector3(2, 0.5f, 2);
            table.GetComponent<Renderer>().sharedMaterial = woodMaterial;
            table.transform.parent = environment.transform;

            count++;
        }

        // Adjust Main Camera and Directional Light
        GameObject mainCam = GameObject.Find("Main Camera");
        if (mainCam != null)
        {
            mainCam.transform.position = new Vector3(0, 6f, -12f);
            mainCam.transform.rotation = Quaternion.Euler(20f, 0, 0);
        }

        Debug.Log("Coffee Shop Scene generated successfully! You can find the layout in the active hierarchy. Don't forget to save the scene.");
    }
}
