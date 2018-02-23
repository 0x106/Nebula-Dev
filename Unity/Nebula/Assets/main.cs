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

		float alpha = 0.001F;
		p.m00 = cameraData.data[counter].intrinsics.m00 * alpha;
		p.m01 = cameraData.data[counter].intrinsics.m01 * alpha;
		p.m02 = cameraData.data[counter].intrinsics.m02 * alpha;
		
		p.m10 = cameraData.data[counter].intrinsics.m10 * alpha;
		p.m11 = cameraData.data[counter].intrinsics.m11 * alpha;
		p.m12 = cameraData.data[counter].intrinsics.m12 * alpha;
		
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

	Matrix4x4 matrix_fromNebula33(NebulaMatrix33 matrix) {
		Matrix4x4 m = new Matrix4x4 ();

		Vector4 r0 = new Vector4 (matrix.m00,matrix.m01,matrix.m02,0.0F);
		Vector4 r1 = new Vector4 (matrix.m10,matrix.m11,matrix.m12,0.0F);
		Vector4 r2 = new Vector4 (matrix.m20,matrix.m21,matrix.m22,0.0F);
		Vector4 r3 = new Vector4 (0.0F, 0.0F, 0.0F, 0.0F);

		m.SetRow (0, r0);
		m.SetRow (1, r1);
		m.SetRow (2, r2);
		m.SetRow (3, r3);

		return m;
	}
		
}

[System.Serializable]
public class Frame {
	public string key;
	public NebulaVector position;
	public NebulaVector rotation;
	public NebulaMatrix projection;
	public NebulaMatrix33 intrinsics;
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
public class NebulaMatrix33 {
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
	