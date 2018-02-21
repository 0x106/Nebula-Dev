using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class main : MonoBehaviour {

	GameObject quad;
	GameObject cube;
	Material quadMaterial;
	Texture2D nebulaTexture;
	string[] filenames;
	int counter = 1;
	CameraData cameraData;

	// Use this for initialization
	void Start () {
		print ("Running Nebula script.");

		cube = GameObject.Find ("Cube");

		quad = GameObject.CreatePrimitive( PrimitiveType.Quad );
		quadMaterial = (Material)Resources.Load( "NebulaMaterial" );
		quad.GetComponent<Renderer>().material = quadMaterial;

		float aspect = 1.77778F;
		float scale = 20.0F;
		quad.transform.eulerAngles = new Vector3(0.0F, 0, -90);
		quad.transform.position = new Vector3(0.0F, 0.0F, 20.0F);
		quad.transform.localScale = new Vector3(aspect * scale, scale, 1.0F);

		cube.transform.position = new Vector3(0.0F, 0.0F, 0.0F);
		cube.transform.localScale = new Vector3(0.1F, 0.1F, 0.1F);

		filenames = ((TextAsset)Resources.Load ("filenames")).text.Split( '\n' );

		readData ();
	}
	
	// Update is called once per frame
	void Update () {

		nebulaTexture = Resources.Load( filenames[counter] ) as Texture2D;
		quad.GetComponent<Renderer>().material.mainTexture = nebulaTexture;


		float theta = 1.0F;
		float omega = 1.0F;

		float rx = -(cameraData.data [counter].rotation.x - cameraData.data [counter - 1].rotation.x)* 180.0F / Mathf.PI * theta;
		float ry = -(cameraData.data [counter].rotation.y - cameraData.data [counter - 1].rotation.y)* 180.0F / Mathf.PI * theta;
		float rz = -(cameraData.data [counter].rotation.z - cameraData.data [counter - 1].rotation.z)* 180.0F / Mathf.PI * theta;
		cube.transform.eulerAngles += new Vector3 (rx, ry, rz);
//
		float dx = -(cameraData.data [counter].position.x) * omega;
		float dy = -(cameraData.data [counter].position.y) * omega;
		float dz = (cameraData.data [counter].position.z) * omega;
		cube.transform.position = new Vector3 ( dx, dy, dz );
//		print (dx);
//		print (cube.transform.position.x);
//		print ("======================");
//		
		counter += 1;
		if (counter >= filenames.Length) {
			counter = 1;
		}
	}

	void readData() {
		string _data = ((TextAsset)Resources.Load ("data2")).text;
		cameraData = JsonUtility.FromJson<CameraData> (_data);
	}


	Matrix4x4 matrix(NebulaMatrix extrinsic) {
		Matrix4x4 m = new Matrix4x4 ();

		Vector4 r0 = new Vector4 (extrinsic.m00,extrinsic.m01,extrinsic.m02,extrinsic.m03);
		Vector4 r1 = new Vector4 (extrinsic.m10,extrinsic.m11,extrinsic.m12,extrinsic.m13);
		Vector4 r2 = new Vector4 (extrinsic.m20,extrinsic.m21,extrinsic.m22,extrinsic.m23);
		Vector4 r3 = new Vector4 (extrinsic.m30,extrinsic.m31,extrinsic.m32,extrinsic.m33);

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
	