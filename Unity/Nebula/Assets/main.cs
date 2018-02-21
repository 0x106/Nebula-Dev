using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class main : MonoBehaviour {

	GameObject quad;
	Material quadMaterial;
	Texture2D nebulaTexture;
	string[] filenames;
	int counter = 1;
	CameraData cameraData;

	// Use this for initialization
	void Start () {
		print ("Running Nebula script.");

//		quad = GameObject.CreatePrimitive( PrimitiveType.Quad );
//		quadMaterial = (Material)Resources.Load( "NebulaMaterial" );
//		quad.GetComponent<Renderer>().material = quadMaterial;
//
//		float aspect = 1.77778F;
//		float scale = 20.0F;
//		quad.transform.eulerAngles = new Vector3(0.0F, 0, -90);
//		quad.transform.position = new Vector3(0.0F, 0.0F, 20.0F);
//		quad.transform.localScale = new Vector3(aspect * scale, scale, 1.0F);

//		filenames = ((TextAsset)Resources.Load ("filenames")).text.Split( '\n' );

		readData ();
		print (cameraData.data.Length);
	}
	
	// Update is called once per frame
	void Update () {

//		nebulaTexture = Resources.Load( cameraData.data[counter].timestamp ) as Texture2D;
//		quad.GetComponent<Renderer>().material.mainTexture = nebulaTexture;

		print (cameraData.data [counter].rotation);

		Camera.main.transform.position = new Vector3 (
			cameraData.data[counter].position.x,
			cameraData.data[counter].position.y,
			-cameraData.data[counter].position.z -1
		);

//		Camera.main.transform.eulerAngles = new Vector3 (
//			cameraData.data[counter].rotation.x,
//			cameraData.data[counter].rotation.y,
//			cameraData.data[counter].rotation.z
//		);

		counter += 1;
		if (counter >= cameraData.data.Length) {
			counter = 1;
		}
	}

	void readData() {
		string _data = ((TextAsset)Resources.Load ("data")).text;
		cameraData = JsonUtility.FromJson<CameraData> (_data);
	}


	Matrix4x4 matrix_fromNebula(NebulaMatrix matrix) {
		Matrix4x4 m = new Matrix4x4 ();

		Vector4 r0 = new Vector4 (matrix.m00,matrix.m01,matrix.m02,matrix.m03);
		Vector4 r1 = new Vector4 (matrix.m10,matrix.m11,matrix.m12,matrix.m13);
		Vector4 r2 = new Vector4 (matrix.m20,matrix.m21,matrix.m22,matrix.m23);
		Vector4 r3 = new Vector4 (matrix.m30,matrix.m31,matrix.m32,matrix.m33);

		m.SetRow (0, r0);
		m.SetRow (1, r1);
		m.SetRow (2, r2);
		m.SetRow (3, r3);

		return m;
	}
}

[System.Serializable]
public class Frame {
	public string timestamp;
	public NebulaVector position;
	public NebulaVector rotation;
	public NebulaMatrix projection;
}

[System.Serializable]
public class NebulaVector {
	public float x;
	public float y;
	public float z;
}

[System.Serializable]
public class NebulaMatrix {
	public float m00;
	public float m01;
	public float m02;
	public float m03;

	public float m10;
	public float m11;
	public float m12;
	public float m13;

	public float m20;
	public float m21;
	public float m22;
	public float m23;

	public float m30;
	public float m31;
	public float m32;
	public float m33;
}

[System.Serializable]
public class CameraData {
	public Frame[] data;
}