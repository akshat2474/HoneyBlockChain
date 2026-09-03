import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error

def generate_mock_data(n_samples=5000):
    """
    Generates synthetic IO-VNBD style data if the real dataset isn't downloaded yet,
    so the script can be tested and demonstrated to judges immediately.
    """
    print("WARNING: Real dataset not found. Generating mock vehicle data for demonstration.")
    np.random.seed(42)
    
    # Simulate a vehicle accelerating, cruising, and braking
    time = np.linspace(0, n_samples/10, n_samples)
    base_speed = np.sin(time * 0.1) * 10 + 10 # speed from 0 to 20 m/s
    base_speed = np.maximum(base_speed, 0)
    
    # Simulate noisy IMU readings correlated with speed and acceleration
    acceleration = np.gradient(base_speed)
    
    df = pd.DataFrame({
        'timestamp': time,
        'accel_x': np.random.normal(0, 0.5, n_samples),
        'accel_y': acceleration * 10 + np.random.normal(0, 1.0, n_samples), # Forward accel
        'accel_z': np.random.normal(9.8, 1.0, n_samples) + (base_speed * 0.05), # Vibration increases with speed
        'gyro_x': np.random.normal(0, 0.1, n_samples),
        'gyro_y': np.random.normal(0, 0.1, n_samples),
        'gyro_z': np.random.normal(0, 0.2, n_samples),
        'speed': base_speed # Target
    })
    return df

def load_data(data_path):
    # Try to load real data, fallback to mock data
    if os.path.exists(data_path) and os.listdir(data_path):
        # Load the first CSV found
        file = [f for f in os.listdir(data_path) if f.endswith('.csv')][0]
        print(f"Loading real dataset: {file}")
        df = pd.read_csv(os.path.join(data_path, file))
        # Ensure necessary columns exist or map them
        return df
    else:
        return generate_mock_data()

def create_windows(df, window_size=10):
    """
    Creates sliding windows of IMU data to capture temporal vehicle kinematics.
    Input: DataFrame with IMU columns
    Output: X (windows flattened), y (speed at the end of the window)
    """
    features = ['accel_x', 'accel_y', 'accel_z', 'gyro_x', 'gyro_y', 'gyro_z']
    target = 'speed'
    
    data_x = df[features].values
    data_y = df[target].values
    
    X, y = [], []
    for i in range(len(df) - window_size):
        # Extract window
        window = data_x[i : i + window_size]
        # Flatten the window (e.g. 10 time steps * 6 features = 60 features)
        X.append(window.flatten())
        # The target is the speed at the CURRENT time (end of window)
        y.append(data_y[i + window_size])
        
    return np.array(X), np.array(y)

def main():
    print("--- Phase 5: IO-VNBD Baseline AI Model ---")
    
    # 1. Load Data
    df = load_data("./dataset")
    
    # 2. Preprocessing & Windowing
    # Window size of 10 samples (e.g., 1.0 second at 10Hz)
    WINDOW_SIZE = 10
    print(f"Creating sliding windows of size {WINDOW_SIZE}...")
    X, y = create_windows(df, WINDOW_SIZE)
    
    # 3. Train / Test Split
    # CRITICAL: Do NOT use random train_test_split for sequential trajectory data! 
    # Random splitting causes extreme data leakage. We split by time (first 80% train, last 20% test).
    split_idx = int(len(X) * 0.8)
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]
    
    print(f"Training samples: {len(X_train)} | Testing samples: {len(X_test)}")
    
    # 4. Train Baseline Model (Random Forest)
    print("Training Random Forest Regressor baseline...")
    # Limiting depth and estimators for fast hackathon iteration
    model = RandomForestRegressor(n_estimators=50, max_depth=10, random_state=42, n_jobs=1)
    model.fit(X_train, y_train)
    
    # 5. Evaluate
    print("Evaluating model...")
    y_pred = model.predict(X_test)
    
    mae = mean_absolute_error(y_test, y_pred)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    
    print("-" * 30)
    print(f"Test MAE:  {mae:.2f} m/s")
    print(f"Test RMSE: {rmse:.2f} m/s")
    print("-" * 30)
    
    # 6. Generate Plots for Judges
    plt.figure(figsize=(14, 5))
    
    # Plot 1: Prediction vs Ground Truth Trajectory
    plt.subplot(1, 2, 1)
    # Plot a segment to make it visible
    segment = 500
    plt.plot(y_test[:segment], label='Ground Truth Speed', color='blue', alpha=0.7)
    plt.plot(y_pred[:segment], label='AI Predicted Speed', color='red', alpha=0.7, linestyle='dashed')
    plt.title('Vehicle Speed: Ground Truth vs Prediction')
    plt.xlabel('Time (samples)')
    plt.ylabel('Speed (m/s)')
    plt.legend()
    
    # Plot 2: Error Distribution
    plt.subplot(1, 2, 2)
    errors = y_pred - y_test
    plt.hist(errors, bins=50, color='orange', edgecolor='black')
    plt.title('Prediction Error Distribution')
    plt.xlabel('Error (m/s)')
    plt.ylabel('Frequency')
    
    plt.tight_layout()
    plt.savefig('ai_evaluation_results.png')
    print("Saved evaluation plots to 'ai_evaluation_results.png'")
    
    print("\nNext Steps for Final Integration:")
    print("1. Export this model using joblib/pickle.")
    print("2. Load it into backend/main.py.")
    print("3. When GNSS is lost, feed the Flutter IMU data into model.predict() instead of the heuristic.")

if __name__ == "__main__":
    main()
