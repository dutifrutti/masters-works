import numpy as np
import matplotlib.pyplot as plt
# ------------------------------------------------------------
# Data: 20 samples X in [0, 1], target y per the given formula
# ------------------------------------------------------------
def make_dataset(n=20, x_start=0.1, x_end=1.0):
    X = np.linspace(x_start, x_end, n).reshape(-1, 1)
    # y = (1 + 0.6*sin(2*pi*x/0.7) + 0.3*sin(2*pi*x)) / 2
    y = (1
         + 0.6 * np.sin(2 * np.pi * X / 0.7)
         + 0.3 * np.sin(2 * np.pi * X)
        ) / 2.0
    return X, y

# ------------------------------------
# Activation functions and derivatives
# ------------------------------------
def act(z, kind="tanh"):
    if kind == "tanh":
        return np.tanh(z)
    elif kind == "sigmoid":
        # Stable-ish sigmoid
        z_clip = np.clip(z, -50, 50)
        return 1.0 / (1.0 + np.exp(-z_clip))
    else:
        raise ValueError("Unsupported activation. Use 'tanh' or 'sigmoid'.")

def act_prime(z, kind="tanh"):
    if kind == "tanh":
        a = np.tanh(z)
        return 1.0 - a**2
    elif kind == "sigmoid":
        s = 1.0 / (1.0 + np.exp(-np.clip(z, -50, 50)))
        return s * s * (1.0 - s) * (1.0 / s)  # equivalent to s*(1-s), but safe if reused
    else:
        raise ValueError("Unsupported activation. Use 'tanh' or 'sigmoid'.")

# ----------------------------
# One-hidden-layer MLP (1→H→1)
# ----------------------------
class MLP:
    def __init__(self, input_dim=1, hidden_dim=6, output_dim=1, activation="tanh", seed=0):
        if hidden_dim < 4 or hidden_dim > 8:
            raise ValueError("hidden_dim should be between 4 and 8 as requested.")
        self.activation = activation
        rng = np.random.default_rng(seed)
        # He/Xavier-ish small random init
        self.W1 = rng.normal(0.0, 0.5, size=(input_dim, hidden_dim))
        self.b1 = np.zeros((hidden_dim,))
        self.W2 = rng.normal(0.0, 0.5, size=(hidden_dim, output_dim))
        self.b2 = np.zeros((output_dim,))  # linear output

    def forward(self, X):
        z1 = X @ self.W1 + self.b1  # (N,H)
        a1 = act(z1, self.activation)
        yhat = a1 @ self.W2 + self.b2  # (N,1)
        return {"z1": z1, "a1": a1, "yhat": yhat}

    @staticmethod
    def mse(yhat, y):
        return np.mean((yhat - y) ** 2)

    def backward(self, X, y, cache):
        N = X.shape[0]
        yhat = cache["yhat"]
        a1 = cache["a1"]
        z1 = cache["z1"]

        # d/dyhat MSE = 2/N * (yhat - y)
        dyhat = (2.0 / N) * (yhat - y)               # (N,1)

        # Output layer grads (linear)
        dW2 = a1.T @ dyhat                            # (H,1)
        db2 = dyhat.sum(axis=0)                       # (1,)

        # Backprop into hidden
        da1 = dyhat @ self.W2.T                       # (N,H)
        dz1 = da1 * act_prime(z1, self.activation)    # (N,H)

        # Hidden layer grads
        dW1 = X.T @ dz1                               # (1,H)
        db1 = dz1.sum(axis=0)                         # (H,)

        grads = {"dW1": dW1, "db1": db1, "dW2": dW2, "db2": db2}
        return grads

    def step(self, grads, lr):
        self.W1 -= lr * grads["dW1"]
        self.b1 -= lr * grads["db1"]
        self.W2 -= lr * grads["dW2"]
        self.b2 -= lr * grads["db2"]

    def fit(self, X, y, lr=0.05, epochs=20000, print_every=2000, tol=1e-10):
        prev_loss = np.inf
        for ep in range(1, epochs + 1):
            cache = self.forward(X)
            loss = self.mse(cache["yhat"], y)
            grads = self.backward(X, y, cache)
            self.step(grads, lr)

            if ep % print_every == 0 or ep == 1 or ep == epochs:
                print(f"Epoch {ep:6d} | MSE: {loss:.8f}")

            # Simple convergence check
            if abs(prev_loss - loss) < tol:
                print(f"Converged at epoch {ep} with MSE: {loss:.8f}")
                break
            prev_loss = loss

    def predict(self, X):
        return self.forward(X)["yhat"]

    def print_coefficients(self, decimals=6):
        np.set_printoptions(precision=decimals, suppress=True)
        print("\nLearned coefficients:")
        print(f"W1 (input->hidden) shape {self.W1.shape}:\n{self.W1}")
        print(f"b1 (hidden biases)  shape {self.b1.shape}:\n{self.b1}")
        print(f"W2 (hidden->output) shape {self.W2.shape}:\n{self.W2}")
        print(f"b2 (output bias)    shape {self.b2.shape}:\n{self.b2}")

# -----------------
# Example execution
# -----------------
if __name__ == "__main__":
    # Build dataset
    X, y = make_dataset(n=20, x_start=0.1, x_end=1.0)

    # Configure model
    hidden_neurons =  8          # choose 4–8
    activation = "tanh"          # or "sigmoid"
    learning_rate = 0.07
    epochs = 20000

    model = MLP(input_dim=1, hidden_dim=hidden_neurons, output_dim=1,
                activation=activation, seed=0)

    # Train with backpropagation (full-batch gradient descent)
    model.fit(X, y, lr=learning_rate, epochs=epochs, print_every=2000)

    # Show learned coefficients
    model.print_coefficients()

    # Optional: evaluate training fit quality
    y_pred = model.predict(X)
    mse = np.mean((y_pred - y) ** 2)
    print(f"\nFinal training MSE: {mse:.8f}")

    #print(f"target: {y} || prediction: {y_pred}")
    print(y)
    print("prediction")
    print(y_pred)
    plt.plot(X, y, label="y", color="red", linestyle="dashed", marker="o")
    plt.plot(X, y_pred, label="y_pred", color="blue", linestyle="-", marker="s")
    plt.show()









#########################################################################################
    def make_surface_dataset(nx=30, ny=30, x_start=0.0, x_end=1.0, y_start=0.0, y_end=1.0):
        xs = np.linspace(x_start, x_end, nx)
        ys = np.linspace(y_start, y_end, ny)
        XX, YY = np.meshgrid(xs, ys, indexing="xy")
        # Example target surface (bounded to ~[0,1]):
        # f(x,y) = 0.5 + 0.25*sin(2πx) + 0.2*cos(2πy) + 0.15*sin(2π(x+y)/0.7)
        ZZ = (0.5
              + 0.25 * np.sin(2 * np.pi * XX)
              + 0.20 * np.cos(2 * np.pi * YY)
              + 0.15 * np.sin(2 * np.pi * (XX + YY) / 0.7))
        # Flatten for training (N, 2) -> (N, 1) 1D
        X2 = np.stack([XX.ravel(), YY.ravel()], axis=1)
        z = ZZ.ravel().reshape(-1, 1)
        return X2, z, XX, YY, ZZ

    # XX = [[0, 0.5, 1],
    #       [0, 0.5, 1],
    #       [0, 0.5, 1]]
    #
    # YY = [[0, 0, 0],
    #       [0.5, 0.5, 0.5],
    #       [1, 1, 1]]
    #ZZ[i, j] = f(XX[i, j], YY[i, j])

    X2, z, XX, YY, ZZ_true = make_surface_dataset(nx=35, ny=35, x_start=0.0, x_end=1.0,
                                                  y_start=0.0, y_end=1.0)

    hidden_neurons_2d = 8        # choose 4–8
    model2d = MLP(input_dim=2, hidden_dim=hidden_neurons_2d, output_dim=1,
                  activation=activation, seed=42)

    print("\nTraining 2D surface approximator...")
    model2d.fit(X2, z, lr=0.05, epochs=30000, print_every=3000)

    z_pred_flat = model2d.predict(X2).reshape(-1)
    ZZ_pred = z_pred_flat.reshape(YY.shape)
    mse2 = np.mean((ZZ_pred - ZZ_true) ** 2)
    print(f"\nFinal training MSE (2D surface): {mse2:.8f}")

    # 3D surface plots: target and prediction
    fig = plt.figure(figsize=(12, 5))

    ax1 = fig.add_subplot(1, 2, 1, projection="3d")
    ax1.plot_surface(XX, YY, ZZ_true, linewidth=0, antialiased=True, alpha=0.9)
    ax1.set_title("Target Surface")
    ax1.set_xlabel("x")
    ax1.set_ylabel("y")
    ax1.set_zlabel("z")

    ax2 = fig.add_subplot(1, 2, 2, projection="3d")
    ax2.plot_surface(XX, YY, ZZ_pred, linewidth=0, antialiased=True, alpha=0.9)
    ax2.set_title("Predicted Surface")
    ax2.set_xlabel("x")
    ax2.set_ylabel("y")
    ax2.set_zlabel("ẑ")

    plt.tight_layout()
    plt.show()

