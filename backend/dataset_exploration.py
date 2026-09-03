import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt

def inspect_dataset(data_dir: str):
    """
    Step 1 - Inspect the IO-VNBD Dataset.
    This script is designed to load and explore the IO-VNBD dataset.
    You will need to download the dataset and place it in the 'data_dir'.
    """
    print(f"--- Inspecting IO-VNBD Dataset in {data_dir} ---")
    
    if not os.path.exists(data_dir):
        print(f"Error: Directory {data_dir} not found. Please download the dataset.")
        print("Creating placeholder directory. Place your CSV files here.")
        os.makedirs(data_dir)
        return

    # List available files
    files = [f for f in os.listdir(data_dir) if f.endswith('.csv')]
    if not files:
        print("No CSV files found in the dataset directory.")
        return
        
    print(f"Found {len(files)} files: {files[:5]}...")

    # Load a sample file
    sample_file = os.path.join(data_dir, files[0])
    df = pd.read_csv(sample_file)

    print("\n--- Dataset Structure ---")
    print(f"Shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    
    print("\n--- Missing Values ---")
    print(df.isnull().sum()[df.isnull().sum() > 0])

    print("\n--- Sampling Rate Estimation ---")
    # Assuming there's a timestamp column, calculate dt
    if 'timestamp' in df.columns:
        dt = df['timestamp'].diff().mean()
        print(f"Average time between samples: {dt:.4f}s (Approx {1/dt:.1f} Hz)")
    else:
        print("No 'timestamp' column found. Ensure timestamps are aligned.")

    print("\n--- Sensor Types & Features ---")
    print("Expected IMU features: Accel X/Y/Z, Gyro X/Y/Z, Mag X/Y/Z")
    print("Expected Target features: GPS Lat/Lon, GPS Speed, Wheel Speed (OBD/CAN)")
    
    # Plotting distributions to check for noise
    if 'accel_x' in df.columns: # Adjust column names based on actual dataset
        df[['accel_x', 'accel_y', 'accel_z']].hist(bins=50, figsize=(10, 6))
        plt.suptitle("Accelerometer Distributions")
        plt.show()

def explain_prediction_task():
    """
    Explains the exact prediction task based on the dataset and SIH problem statement.
    """
    explanation = """
================================================================================
                    IO-VNBD PREDICTION TASK DEFINITION
================================================================================

Based on the SIH Problem Statement, our system must:
"employ AI/ML models trained on vehicle kinematics to accurately predict vehicle 
speed and acceleration profiles solely from the smartphone’s noisy inputs."

1. The Features (Inputs):
   - We must ONLY use the smartphone's raw sensors (Accel X, Y, Z and Gyro X, Y, Z).
   - Because single-point acceleration is too noisy (potholes, vibrations), the 
     input must be a TIME-SERIES WINDOW (e.g., the last 1.0 second of IMU data 
     sampled at 10Hz = shape of [10, 6]).

2. The Target Variable (Label):
   - The dataset contains "ground truth" vehicle dynamics, specifically 
     'Wheel Speed' or 'GPS Velocity'. 
   - Our target variable is the **Forward Vehicle Speed (m/s)**.

3. The Prediction Task:
   - This is a Sequence-to-Value Regression task.
   - f(IMU_Window) -> Current_Speed
   
4. Why this matters:
   - Without an AI predicting speed directly, standard Dead Reckoning requires
     double-integrating acceleration (a -> v -> p).
   - Double integration of noisy smartphone IMU data causes quadratic drift 
     (flying off the map in seconds).
   - By predicting speed directly using AI, we reduce the drift from quadratic 
     to linear, making lane-level Dead Reckoning possible during GNSS blackouts.
================================================================================
    """
    print(explanation)


if __name__ == "__main__":
    explain_prediction_task()
    
    # Update this path to where you extract the IO-VNBD dataset
    DATASET_PATH = "./dataset"
    inspect_dataset(DATASET_PATH)
