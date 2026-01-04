import cv2
import os
import numpy as np
from skimage.measure import label, regionprops
from scipy.ndimage import binary_fill_holes
from dataclasses import dataclass
from sklearn.naive_bayes import GaussianNB
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

image_dir = os.getcwd()
apple_images = []
pear_images = []
apple_hsv = []
apple_round = []
pear_hsv = []
pear_round = []

@dataclass
class Apple:
    x1: float
    x2: float
    T: int
@dataclass
class Pear:
    x1: float
    x2: float
    T: int

apples = []
pears = []

for image in os.listdir(image_dir):
    if image.startswith("apple") and image.endswith(".jpg"):
        apple_images.append(image)
    if image.startswith("pear") and image.endswith(".jpg"):
        pear_images.append(image)

for apple in apple_images:
    img = cv2.imread(apple)
    BW = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#binarine nuotrauka su reiksmes x,y 0 arba 255 priklausant nuo nustatytos ribos
    _, BW = cv2.threshold(BW, 0.95 * 255, 255, cv2.THRESH_BINARY)
    #is juodo i balta
    BW = cv2.bitwise_not(BW)
    # cv2.imshow("",BW)
    # cv2.waitKey(0)
    BW = binary_fill_holes(BW).astype(np.uint8) * 255
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25)) #12px spindulys
    BW = cv2.morphologyEx(BW, cv2.MORPH_OPEN, kernel)

    #rgb i hsv
    hsv_img = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    hue_channel = hsv_img[:, :, 0] / 180.0
    binary_mask = BW > 0
    hsv_value = np.mean(hue_channel[binary_mask])
    apple_hsv.append(hsv_value)



    BWpr = regionprops(BW)
    area = BWpr[0].area
    perimeter = BWpr[0].perimeter
    circularity = (4 * np.pi * area) / (perimeter ** 2)
    apple_round.append(circularity)

    apple_instance = Apple(x1=hsv_value,x2=circularity,T=1)
    apples.append(apple_instance)

for pear in pear_images:
    img = cv2.imread(pear)
    BW = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#binarine nuotrauka su reiksmes x,y 0 arba 255 priklausant nuo nustatytos ribos
    _, BW = cv2.threshold(BW, 0.95 * 255, 255, cv2.THRESH_BINARY)
    BW = cv2.bitwise_not(BW)
    BW = binary_fill_holes(BW).astype(np.uint8) * 255
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25))
    BW = cv2.morphologyEx(BW, cv2.MORPH_OPEN, kernel)
    hsv_img = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    hsv = hsv_img[:, :, 0] / 180.0
    binary_mask = BW > 0
    hsv_value = np.mean(hsv[binary_mask])
    pear_hsv.append(hsv_value)

    BWpr = regionprops(BW)
    area = BWpr[0].area
    perimeter = BWpr[0].perimeter
    circularity = (4 * np.pi * area) / (perimeter ** 2)
    pear_round.append(circularity)

    pear_instance=Pear(x1=hsv_value,x2=circularity,T=-1)
    pears.append(pear_instance)

x1 = []
x2 = []
# 3 apples
for i in range (3):
    x1.append(apple_hsv[i])
    x2.append(apple_round[i])
# 2 pears
for i in range (2):
    x1.append(pear_hsv[i])
    x2.append(pear_round[i])

#x1,x2 parametrai

P = np.array([x1, x2])
T = np.array([1,1,1,-1,-1])

w = np.random.rand(2)  # [w1, w2]
b = np.random.rand(1)

eta = 0.1           # learning rate
epochs = 100         # kiek kartu perceptronas mato duomenu seta, su 100 gerai veikia
print(P)
# Training loop
for ep in range(epochs):
    errors = 0
    for n in range(P.shape[1]):
        x = P[:, n]                      # feature vector [x1, x2]
        v = np.dot(w, x) + b
        y = 1 if v > 0 else -1           # activation function
        e = T[n] - y                     # error

        if e != 0:                       # update rule
            w = w + eta * e * x
            b = b + eta * e
            errors += 1

    if errors == 0:                      # stop early if no errors
        print(f"Training converged after {ep+1} epochs")
        break

v_all = np.dot(w, P) + b
print(v_all)
Y = np.where(v_all > 0, 1, -1) # performs activation function

print("Predictions:", Y)
print("Targets    :", T)
print("Final weights:", w, "Bias:", b)

###########################################################################
X = P.T  # shape (N, 2)
y = T    # shape (N,)

nb = GaussianNB()
nb.fit(X, y)

Y_nb = nb.predict(X)

print("Naive Bayes predictions:", Y_nb)
print("Targets               :", y)
print("Naive Bayes accuracy  :", accuracy_score(y, Y_nb))
print("Naive Bayes confusion matrix:\n", confusion_matrix(y, Y_nb))
print("Naive Bayes report:\n", classification_report(y, Y_nb, digits=3))







