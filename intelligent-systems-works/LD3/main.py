import numpy as np
import matplotlib.pyplot as plt


x = np.arange(0.1, 1, 1/22)  # 0.1 : 1/22 : 1
y = ((1 + 0.6*np.sin(2*np.pi*x/0.7)) + 0.3*np.sin(2*np.pi*x)) / 2

# Gauso radial basis function
def rbf(x, c, r):
    return np.exp(-((x - c)**2) / (2*r**2))

# centrai ir plociai
c1, r1 = 0.19, 0.2
c2, r2 = 0.9, 0.2

w1 = np.random.random()
w2 = np.random.random()
w0 = np.random.random()

eta = 0.05
epochs = 2000
n = len(x)
# phi3 = rbf(x, c1, r1)
# print("phi3: ", phi3)
phi1 = rbf(x, c1, r1)
phi2 = rbf(x, c2, r2)

for epoch in range(epochs):
    for i in range(n):  # no shuffling, fixed order
        v = w1*phi1[i] + w2*phi2[i] + w0
        e = y[i] - v
        # weight updates
        w1 += eta * e * phi1[i]
        w2 += eta * e * phi2[i]
        w0 += eta * e


v = w1*phi1 + w2*phi2 + w0
mse = np.mean((y - v) ** 2)

print("Centers and widths:")
print(f" c1={c1}, r1={r1}")
print(f" c2={c2}, r2={r2}\n")

print("Learned weights:")
print(f" w1={w1:.6f}, w2={w2:.6f}, w0={w0:.6f}")
print(f"Training MSE: {mse:.8f}")

# ----- Plot results -----
plt.plot(x, y, 'o', label="Target")
plt.plot(x, v, '-', label="Model")
plt.legend()
plt.grid(True)
plt.show()