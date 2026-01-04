import numpy as np
import matplotlib.pyplot as plt

# ----- Generate training data -----
step = 1/22
x = np.arange(0.1, 1 + 1e-12, step)  # 20 samples
y = ((1 + 0.6*np.sin(2*np.pi*x/0.7)) + 0.3*np.sin(2*np.pi*x)) / 2

# ----- Gaussian RBF -----
def rbf(x, c, r):
    return np.exp(-((x - c)**2) / (2*r**2))

# ----- Initialize parameters -----
w1, w2, w0 = 0.1, 0.1, 0.0
c1, r1 = 0.3, 0.2
c2, r2 = 0.8, 0.2

eta = 0.05
epochs = 300   # reduced so plot is clearer

c1_history, c2_history = [c1], [c2]

# ----- Training loop -----
for epoch in range(epochs):
    for i in range(len(x)):
        phi1 = rbf(x[i], c1, r1)
        phi2 = rbf(x[i], c2, r2)
        y_hat = w1*phi1 + w2*phi2 + w0
        e = y[i] - y_hat

        # Update weights
        w1 += eta * e * phi1
        w2 += eta * e * phi2
        w0 += eta * e

        # Update centers and radii with gradient descent rule
        # θ - eta * dE/dθ
        # basically backpropagation
        c1 += eta * e * w1 * phi1 * (x[i] - c1) / (r1**2)
        c2 += eta * e * w2 * phi2 * (x[i] - c2) / (r2**2)

        r1 += eta * e * w1 * phi1 * ((x[i] - c1)**2) / (r1**3)
        r2 += eta * e * w2 * phi2 * ((x[i] - c2)**2) / (r2**3)

    # record centers every epoch
    c1_history.append(c1)
    c2_history.append(c2)

# ----- Evaluate final model -----
phi1_all = rbf(x, c1, r1)
phi2_all = rbf(x, c2, r2)
y_hat = w1*phi1_all + w2*phi2_all + w0
mse = np.mean((y - y_hat)**2)

print("Final parameters:")
print(f" w1={w1:.4f}, w2={w2:.4f}, w0={w0:.4f}")
print(f" c1={c1:.4f}, r1={r1:.4f}")
print(f" c2={c2:.4f}, r2={r2:.4f}")
print(f"Training MSE = {mse:.6f}")

# ----- Plot fit -----
plt.figure(figsize=(7,4))
plt.title("Trainable RBF Network Approximation")
plt.plot(x, y, 'o', label="Target y")
plt.plot(x, y_hat, '-', label="Model y_hat")
plt.xlabel("x")
plt.ylabel("y")
plt.legend()
plt.grid(True)
plt.show()

# ----- Plot how centers moved -----
plt.figure(figsize=(7,4))
plt.title("Movement of RBF Centers During Training")
plt.plot(range(epochs+1), c1_history, label="Center c1")
plt.plot(range(epochs+1), c2_history, label="Center c2")
plt.xlabel("Epoch")
plt.ylabel("Center position")
plt.legend()
plt.grid(True)
plt.show()
