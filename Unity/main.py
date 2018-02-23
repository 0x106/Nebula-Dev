import os, sys, math, time, cv2, json

import numpy as np

__render, __write = False, False
if len(sys.argv )== 1:
    __render, __write = False, True
elif len(sys.argv) == 2:
    if sys.argv[1] == 'write':
        __write = True
    if sys.argv[1] == 'draw':
        __render = True
elif len(sys.argv) == 3:
    __render, __write = True, True
else:
    pass

def process(image):
    cols, rows = image.shape[1], image.shape[0]
    M = cv2.getRotationMatrix2D((cols/2,rows/2),-90,1)
    image = cv2.warpAffine(image,M,(cols,rows))
    image = cv2.resize(image, (640,480), interpolation=cv2.INTER_LINEAR)
    return image

def load(path):
    path += "/"
    files = os.listdir(path)
    jsonfile = files[files[-4:] == 'json']
    print("jsonfile: " + path+jsonfile)
    data = json.loads(open(path+jsonfile,'r').read())
    index = 0
    if __render:
        images = [(fname, (cv2.imread(path+fname))) for fname in files if fname[-4:] == '.jpg']
        return images, data
    return data

def rotx(x):
    R = np.eye(3, 3)
    R[1,1] = np.cos(x)
    R[2,2] = np.cos(x)
    R[1,2] = np.sin(x)
    R[2,1] = -np.sin(x)
    return R

def roty(y):
    R = np.eye(3, 3)
    R[0,0] = np.cos(y)
    R[2,2] = np.cos(y)
    R[0,2] = -np.sin(y)
    R[2,0] = np.sin(y)
    return R

def rotz(z):
    R = np.eye(3, 3)
    R[0,0] = np.cos(z)
    R[1,1] = np.cos(z)
    R[0,1] = np.sin(z)
    R[1,0] = -np.sin(z)
    return R

def rotation(euler):
    rx = rotx(euler[0])
    ry = roty(euler[0])
    rz = rotz(euler[0])

    return np.dot(rz, np.dot(ry, rx))

def translation(T):
    output = np.eye(4)
    output[0, 3] = T[0]
    output[1, 3] = T[1]
    output[2, 3] = T[2]
    return output

def construct_extrinsic(T, euler):
    R = rotation(euler)
    output = np.eye(4)
    output[:3,:3] = np.copy(R.T)
    output[:3, 3] = -np.dot(R.T, T)

    return output

def project(points, intrinsics, T, euler, cameraTransform):
    extrinsic = construct_extrinsic(T, euler)
    perspective = np.eye(3,4)

    output = np.zeros((points.shape[0], 3))
    for index, point in enumerate(points):
        output[index] = np.dot(intrinsics, np.dot(perspective, np.dot(np.linalg.inv(cameraTransform), point)) )
        output[index] /= output[index,2]

    return output

def array_from_dict(x):
    output = np.zeros(3)
    output[0] = x["x"]
    output[1] = x["y"]
    output[2] = x["z"]
    return output

def homogeneous(points):
    output = np.ones((points.shape[0], 4))
    output[:,:3] = np.copy(points)
    return output

def matrix_to_jsonstring(name, data):
    m44 = ["m00", "m01", "m02", "m03",
           "m10", "m11", "m12", "m13",
           "m20", "m21", "m22", "m23",
           "m30", "m31", "m32", "m33"]

    m33 = ["m00", "m01", "m02",
           "m10", "m11", "m12",
           "m20", "m21", "m22"]

    output = ""
    output += "\t\t\"" + name + "\": {"
    idx = 0
    if data.shape[0] == 4:
        for i in range(data.shape[0]):
            for k in range(data.shape[1]):
                if m44[idx] == "m33":
                    output +=  "\"" + m44[idx] + "\": "  + str(data[i,k]) + "}"
                else:
                    output +=  "\"" + m44[idx] + "\": "  + str(data[i,k]) + ', '
                idx += 1
    elif data.shape[0] == 3:
        for i in range(data.shape[0]):
            for k in range(data.shape[1]):
                if m33[idx] == "m22":
                    output +=  "\"" + m33[idx] + "\": "  + str(data[i,k]) + "}"
                else:
                    output +=  "\"" + m33[idx] + "\": "  + str(data[i,k]) + ', '
                idx += 1
    else:
        pass
    return output

def render(intrinsics, transform, image):
    root = np.zeros((4, 4))
    root[:,3] = 1

    root[1,:3] = np.asarray([0.1,0,0])
    root[2,:3] = np.asarray([0,0.1,0])
    root[3,:3] = np.asarray([0,0,0.1])

    perspective = np.eye(3,4)

    output = np.zeros((root.shape[0], 3))
    for index, point in enumerate(root):
        output[index] = np.dot(intrinsics, np.dot(perspective, np.dot(np.linalg.inv(transform), point)) )
        output[index] /= output[index,2]

    cv2.line(image, (image.shape[1]-int(output[0,0]), int(output[0,1])), (image.shape[1]-int(output[1,0]), int(output[1,1])), (255, 0,0), 2)
    cv2.line(image, (image.shape[1]-int(output[0,0]), int(output[0,1])), (image.shape[1]-int(output[2,0]), int(output[2,1])), (255, 0,0), 2)
    cv2.line(image, (image.shape[1]-int(output[0,0]), int(output[0,1])), (image.shape[1]-int(output[3,0]), int(output[3,1])), (255, 0,0), 2)

    return image

if __name__ == '__main__':

    data_path = "/Users/jordancampbell/helix/Atlas/Nebula/data"
    paths = [fname for fname in os.listdir(data_path) if fname != 'main.py']
    path = data_path+"/"+paths[-2]

    print(path)

    if __write:
        datafile = open(path+"/data.json", 'w+')

    if __render:
        images, data = load(path)
    else:
        data = load(path)

    if __write:
        datafile.write("{\n\t\"data\": [\n")
    #
    num_images = len(data)
    keys = []

    if __render:
        # while(True):
        for fname, image in images:
            frame = data[fname]
            cameraPoints = np.asarray(frame["pointcloud"]["points"])

            if cameraPoints.shape[0] > 0:
                image  = render(np.asarray(frame["intrinsics"]), np.asarray(frame["transform"]), image)

                cv2.imwrite(path + "/" + fname, image)
                print(path+"/"+fname)
                cv2.imshow("Nebula", image)
                cv2.waitKey(1)

    if __write:
        for idx, item in enumerate(data):

            frame = data[item]
            cameraPoints = np.asarray(frame["pointcloud"]["points"])

            if cameraPoints.shape[0] > 0:
                keys.append(str(frame["imagename"][:-4]))

                datafile.write("\t{\n")
                datafile.write("\t\t\"key\": \"" + str(frame["imagename"][:-4])+ "\",\n")
                datafile.write("\t\t\"position\": { \"x\": " + str(frame["position"]['x']) + ", \"y\": " + str(frame["position"]['y']) + ", \"z\": " + str(frame["position"]['z']) + "},\n")
                datafile.write("\t\t\"rotation\": { \"x\": " + str(frame["rotation"]['x']) + ", \"y\": " + str(frame["rotation"]['y']) + ", \"z\": " + str(frame["rotation"]['z']) + "},\n")

                datafile.write( matrix_to_jsonstring("projection", np.asarray(frame["projection"])) + ",\n")
                datafile.write( matrix_to_jsonstring("intrinsics", np.asarray(frame["intrinsics"])) + "\n")

                if idx < num_images-1:
                    datafile.write("\t},\n")
                else:
                    datafile.write("\t}\n")

    if __write:
        datafile.write("\t],\n\"keys\":\t[\n")

        sorted_keys = sorted(keys)
        for idx, key in enumerate(sorted_keys):
            if idx < len(sorted_keys)-1:
                datafile.write("\"" + key + "\", ")
            else:
                datafile.write("\"" + key + "\"]\n")

        datafile.write("\n}")
        datafile.close()






#
