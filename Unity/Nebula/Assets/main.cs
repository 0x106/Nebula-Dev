using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class main : MonoBehaviour {

	GameObject quad;
	Material quadMaterial;
	Texture2D nebulaTexture;
	string[] filenames;
	string[] sorted_keys;
	int counter = 1;
	CameraData cameraData;


	// Use this for initialization
	void Start () {
		print ("Running Nebula script.");

		quad = GameObject.CreatePrimitive( PrimitiveType.Quad );
		quadMaterial = (Material)Resources.Load( "NebulaMaterial" );
		quad.GetComponent<Renderer>().material = quadMaterial;

		float aspect = 1.77778F;
		float scale = 5.0F;//20.0F;
		quad.transform.eulerAngles = new Vector3(0.0F, 0, -90);
		quad.transform.position = new Vector3(0.0F, 0.0F, 8.0F);
		quad.transform.localScale = new Vector3(aspect * scale, scale, 1.0F);

		quad.transform.parent = Camera.main.transform;

		readData ();

		Frame[] sortedData = new Frame[cameraData.data.Length];

		int index = 0;
		foreach (string key in cameraData.keys) {
			foreach (Frame item in cameraData.data) {
				if (item.key == key) {
					sortedData [index] = item;
					index += 1;
				}
			}
		}

		cameraData.data = sortedData;
	}
	
	// Update is called once per frame
	void Update () {

		string currentKey = cameraData.keys [counter];

		string texturePath = "NebulaTextures/" + currentKey;

		nebulaTexture = Resources.Load( texturePath ) as Texture2D;
		quad.GetComponent<Renderer>().material.mainTexture = nebulaTexture;

		Camera.main.transform.position = new Vector3 (
			cameraData.data[counter].position.x,
			cameraData.data[counter].position.y,
			-cameraData.data[counter].position.z
		);

		float omega = 180.0F / Mathf.PI;
		Camera.main.transform.eulerAngles = new Vector3 (
			-cameraData.data[counter].rotation.x * omega,
			-cameraData.data[counter].rotation.y * omega,
			 cameraData.data[counter].rotation.z * omega + 90.0F
		);

		Matrix4x4 p = Camera.main.projectionMatrix;

		float gamma = 0.38F;
		float deltaX = -0.6F;
		float deltaY = -0.4F;

		float alpha = 0.001F;
		p.m00 = cameraData.data[counter].intrinsics.m00 * alpha + gamma;
		p.m01 = cameraData.data[counter].intrinsics.m01 * alpha;
		p.m02 = cameraData.data[counter].intrinsics.m02 * alpha + deltaX;
		
		p.m10 = cameraData.data[counter].intrinsics.m10 * alpha;
		p.m11 = cameraData.data[counter].intrinsics.m11 * alpha + gamma;
		p.m12 = cameraData.data[counter].intrinsics.m12 * alpha + deltaY;
		
		p.m20 = cameraData.data[counter].intrinsics.m20 * alpha;
		p.m21 = cameraData.data[counter].intrinsics.m21 * alpha;
		p.m22 = cameraData.data[counter].intrinsics.m22 * alpha;

		Camera.main.projectionMatrix = p;

		counter += 1;
		if (counter >= cameraData.data.Length) {
			counter = 1;
		}
	}

	void readData() {
		string _data = ((TextAsset)Resources.Load ("data")).text;
		cameraData = JsonUtility.FromJson<CameraData> (_data);
	}

}

[System.Serializable]
public class Frame {
	public string key;
	public Vector3 position;
	public Vector3 rotation;
	public Matrix4x4 projection;

//	use a custom matrix to account for col-major vs row-major differences.
//	Probably not the most effective method but robust for now.
	public NebulaMatrix3x3 intrinsics;
}

[System.Serializable]
public class NebulaMatrix3x3 {
	public float m00;
	public float m01;
	public float m02;

	public float m10;
	public float m11;
	public float m12;

	public float m20;
	public float m21;
	public float m22;
}

[System.Serializable]
public class CameraData {
	public Frame[] data;
	public string[] keys;
}
	