import os
import time

from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score, classification_report

print("Starting AI model training", flush=True)
print("Slurm job ID:", os.environ.get("SLURM_JOB_ID", "Local run"), flush=True)

# Load the built-in handwritten digits dataset.
digits = load_digits()
X, y = digits.data, digits.target

# Keep the same test data and split on every run.
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# A small neural network with two hidden layers.
model = make_pipeline(
    StandardScaler(),
    MLPClassifier(
        hidden_layer_sizes=(64, 32),
        max_iter=100,
        early_stopping=True,
        random_state=42
    )
)

start = time.time()
model.fit(X_train, y_train)
elapsed = time.time() - start

# Evaluate on data the model did not train on.
predictions = model.predict(X_test)
accuracy = accuracy_score(y_test, predictions)

print(f"Training samples: {len(X_train)}", flush=True)
print(f"Test samples: {len(X_test)}", flush=True)
print(f"Training time: {elapsed:.2f} seconds", flush=True)
print(f"Test accuracy: {accuracy:.2%}", flush=True)
print("\nClassification report:", flush=True)
print(classification_report(y_test, predictions), flush=True)