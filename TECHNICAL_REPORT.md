# Intelligent Dead Reckoning (IDR) System
## Technical Report: Mathematics, Implementation & ML Roadmap

**SIH Problem Statement ID:** PS-1788  
**Team Focus:** Smartphone-based GNSS-denied navigation using INS + AI/ML fusion  
**Dataset:** IO-VNBD (Inertial and Odometry Vehicle Navigation Benchmark Dataset)

---

## Table of Contents

1. [Problem Statement Analysis](#1-problem-statement-analysis)
2. [Why GNSS Fails](#2-why-gnss-fails)
3. [System Architecture](#3-system-architecture)
4. [Phase 1: Classical Dead Reckoning — The Math](#4-phase-1-classical-dead-reckoning--the-math)
5. [Phase 2: Sensor Noise — Sources and Mitigations](#5-phase-2-sensor-noise--sources-and-mitigations)
6. [Phase 3: ML Enhancement Roadmap](#6-phase-3-ml-enhancement-roadmap)
7. [IO-VNBD Dataset — What It Provides and How to Use It](#7-io-vnbd-dataset--what-it-provides-and-how-to-use-it)
8. [Performance Benchmarks and Target Metrics](#8-performance-benchmarks-and-target-metrics)
9. [On-Device Deployment Strategy](#9-on-device-deployment-strategy)
10. [Current Prototype Status](#10-current-prototype-status)
11. [References](#11-references)

---

## 1. Problem Statement Analysis

The problem targets a critical gap in last-mile logistics, emergency response, and ride-hailing across India:

> **"A vehicle enters a tunnel, an urban canyon, or a dense forest — GPS drops. What happens next?"**

Modern navigation apps freeze, snap to the last known position, or make wild trajectory guesses. The consequence is not just inconvenience: a delivery van misses an exit in a tunnel, an ambulance navigation fails in a metro underpass, or a truck driver is misdirected into a wrong lane at 60 kmph.

The SIH benchmark is demanding:
- Drift ≤ **5 metres** over 50 m of GNSS denial
- Drift ≤ **100 metres** over 1 km at 60 kmph in tunnels
- Position update rate: **10 Hz** on smartphone, **200 Hz** on edge hardware
- **No OBD-II connection, no external hardware** — smartphone only

The key insight of the problem: a consumer MEMS IMU alone **cannot** achieve this via classical dead reckoning due to deterministic bias and thermo-mechanical noise. The solution requires **AI/ML to replace what physics cannot give us for free** — specifically, a direct velocity estimate from noisy acceleration data without double integration.

---

## 2. Why GNSS Fails

GNSS (GPS, Galileo, NavIC, GLONASS) works by trilateration: the receiver computes its position by measuring time-of-flight of signals from at least 4 satellites simultaneously.

**Signal power is vanishingly small.** A GPS signal arriving at Earth is roughly **−130 dBm** — roughly 10 quadrillion times weaker than a typical Wi-Fi signal. This makes it trivially easy to block or corrupt.

| Environment | Failure Mode |
|---|---|
| Underground tunnel / metro | Complete structural blockage — zero line-of-sight to satellites |
| Urban canyon (skyscrapers) | Multipath: signals reflect off buildings, arriving with wrong delay → phantom positions |
| Dense forest | Foliage attenuates signal, causes multipath from canopy reflection |
| Multi-level parking lot | Signal blocked by concrete floors, reflected by steel beams |
| Electromagnetic interference | Engine harmonics, HV power lines, jamming devices corrupt carrier frequency |

NavIC (India's own GNSS) improves availability over the Indian subcontinent but is subject to the same physics. **No satellite navigation system can see through concrete.**

---

## 3. System Architecture

Our IDR system follows a **hybrid edge architecture** where complex model training happens offline on a PC or cloud, and only the lightweight inference model is deployed on the smartphone.

```
┌────────────────────────────────────────────────────┐
│                    SMARTPHONE                       │
│                                                     │
│  ┌──────────┐   ┌──────────────┐   ┌────────────┐  │
│  │ GNSS Rx  │   │   MEMS IMU   │   │ Magneto-   │  │
│  │(GPS/NavIC│   │ Accel + Gyro │   │   meter    │  │
│  └────┬─────┘   └──────┬───────┘   └─────┬──────┘  │
│       └────────────────┼─────────────────┘          │
│                        ▼                            │
│            ┌───────────────────────┐                │
│            │  Sensor Fusion Layer  │                │
│            │ (Complementary Filter │                │
│            │  / Kalman Filter)     │                │
│            └───────────┬───────────┘                │
│                        │                            │
│           ┌────────────┴─────────────┐              │
│           │                          │              │
│     ┌─────▼──────┐         ┌─────────▼──────┐      │
│     │  GNSS Mode │         │  AI Dead Reck. │      │
│     │  (accurate)│         │  Engine        │      │
│     └─────┬──────┘         └─────────┬──────┘      │
│           └────────────┬─────────────┘              │
│                        ▼                            │
│            ┌───────────────────────┐                │
│            │  Map-Matching Engine  │                │
│            │  (OSM + NHC)         │                │
│            └───────────┬───────────┘                │
│                        ▼                            │
│            ┌───────────────────────┐                │
│            │   Flutter Navigation  │                │
│            │   UI                  │                │
│            └───────────────────────┘                │
└────────────────────────────────────────────────────┘
          ▲ Offline Training (IO-VNBD on PC) ▲
          Exported TFLite / ONNX → deployed in app
```

**GNSS Blackout Detection:** The system monitors `location.accuracy` from the GNSS receiver. If accuracy exceeds a threshold (e.g., > 50 m) or the fix is lost entirely, the system instantly switches to the DR engine within milliseconds. The last valid GNSS fix seeds the starting position of the DR engine.

---

## 4. Phase 1: Classical Dead Reckoning — The Math

Dead Reckoning estimates current position from a previously known position by integrating velocity over time. It requires two estimates at every time step: **heading** and **speed**.

### 4.1 Coordinate Frames

**Navigation Frame (n-frame):** East-North-Up (ENU). Latitude, Longitude, Altitude live here.

**Body Frame (b-frame):** Fixed to the smartphone. X = right edge, Y = top edge, Z = out of screen.

The critical challenge: the phone can be mounted in any orientation on the dashboard. The rotation matrix `R` from body to vehicle frame is unknown and must be estimated (see Section 6.3).

### 4.2 Heading Estimation — Gyroscope Integration

A gyroscope measures angular rate in rad/s. For a phone held flat, the Z-axis gyroscope measures yaw rate (turning left/right):

```
ψ_k = ψ_(k-1) - ω_z · Δt
```

where `ψ` = heading (radians), `ω_z` = gyro Z reading (rad/s), `Δt` = time step (s).

The negative sign: positive gyro-Z is CCW in body frame = turning left = decreasing compass heading.

**Deadband Filter:**

```
ω_z_filtered = 0       if |ω_z| < 0.05 rad/s
             = ω_z      otherwise
```

This suppresses the sensor noise floor (0.05 rad/s ≈ 3°/s) without affecting real turns (typically > 0.2 rad/s).

**Why pure gyro integration fails — gyroscope bias:**

A constant hardware offset `b_g` contaminates every reading. After time T:

```
Δψ_error = b_g · T
```

For a consumer MEMS gyro with `b_g = 0.01 rad/s`, after 60 seconds: `Δψ = 34°`. The vehicle would appear to be turning in a circle while driving straight.

### 4.3 The Complementary Filter

The gyroscope and magnetometer have complementary error profiles:

| Sensor | Short-term | Long-term |
|---|---|---|
| Gyroscope | Accurate, smooth | Drifts from bias |
| Magnetometer | Noisy per-sample | Zero drift (always North) |

**Magnetometer heading:**

```
ψ_mag = atan2(-m_x, m_y)
```

From raw readings `(m_x, m_y, m_z)`. This is gravity-independent for a flat-held phone.

**Complementary filter equation:**

```
ψ_k = α · (ψ_(k-1) - ω_z · Δt)  +  (1 - α) · ψ_mag
```

With `α = 0.96` in our implementation. At each step:
- **96%** comes from the gyro prediction (fast, smooth, accurate for real turns)
- **4%** is pulled toward the magnetometer (corrects drift over time)

After ~25 steps at 5 Hz (~5 seconds), the magnetometer has fully corrected accumulated gyro drift.

This is mathematically equivalent to: high-pass filter on gyro + low-pass filter on magnetometer, then summed. The crossover frequency is determined by `α` and `Δt`.

**Wraparound problem:** When crossing 0°/360°, naive interpolation causes wrong-direction spin. Fixed with:

```python
def angle_lerp(a, b, t):
    diff = (b - a + π) % (2π) - π    # shortest path in [-π, π]
    return a + t * diff
```

**Flutter display smoothing:** A second-stage exponential filter at 20 fps prevents jitter on the displayed arrow:

```
displayed_ψ_k = displayed_ψ_(k-1)  +  0.15 × Δψ   (with wraparound correction)
```

The arrow reaches 63% of a new heading in ~3 frames (150 ms) — smooth, not laggy.

### 4.4 Speed and Step Detection

**Why double-integration of acceleration is catastrophically wrong:**

```
v_k = v_(k-1) + a · Δt            (first integration)
p_k = p_(k-1) + v_k · Δt          (second integration)
```

With accelerometer bias `b_a`, even while completely stationary:

```
v(T) = b_a · T                     (linear velocity error)
p(T) = ½ · b_a · T²               (quadratic position error)
```

For `b_a = 0.01 m/s²`, after 60 seconds: **18 metres of drift while standing still**.
The SIH benchmark requires < 5 m over 50 m. Double integration fails before the demo starts.

**Our current heuristic — gravity-isolated variance:**

The 3D acceleration magnitude is independent of phone orientation (gravity always contributes 9.81 m/s² regardless of tilt):

```
a_mag = sqrt(a_x² + a_y² + a_z²)
```

Variance from gravity = indicator of movement:

```
variance_k = |a_mag_k - 9.81|
```

Rolling 5-sample mean (1 second at 5 Hz) for spike suppression:

```
mean_var = (1/5) × Σ variance_i   for last 5 samples
```

Binary speed model:
```
v = 1.3 m/s   if mean_var > 0.2 m/s²
v = 0.0 m/s   otherwise
```

1.3 m/s = average walking pace. Works for pedestrian demo. Completely inadequate for a vehicle — this is the primary ML target.

### 4.5 Position Update — Spherical Dead Reckoning

Distance moved in one step:

```
d = v · Δt
```

Position update using spherical trigonometry (WGS-84 Earth model):

```
Δφ = (d · cos ψ) / R_⊕

Δλ = (d · sin ψ) / (R_⊕ · cos φ)
```

Where `R_⊕ = 6,378,137 m` (Earth's equatorial radius), `φ` = current latitude (radians), `ψ` = heading (North = 0, East = π/2). The `cos(φ)` term is critical — it accounts for longitude lines converging toward the poles.

```
φ_(k+1) = φ_k + Δφ
λ_(k+1) = λ_k + Δλ
```

Accurate to < 1 mm for distances under 10 km. For tunnels longer than 10 km, the Vincenty formula should be substituted.

### 4.6 Error Growth Analysis

| Error Source | Growth Rate | Mitigated By |
|---|---|---|
| Gyro bias | Position ∝ `b_g · T²` (quadratic) | Complementary filter |
| Accel bias (double integration) | Position ∝ `½·b_a·T²` (quadratic) | ML speed model bypasses integration entirely |
| Speed model error `Δv` | Position ∝ `Δv · T` (linear) | ML speed model reduces `Δv` from 15 m/s to < 1 m/s |
| Mag noise | Bounded by filter weight | Complementary filter (4% weight) |

After the complementary filter eliminates quadratic gyro drift, the **dominant remaining error is speed model error**. At 60 kmph, our heuristic is 15.4 m/s off from reality, producing ~924 m of drift per minute. The ML speed model reduces this to < 0.5 m/s error, bringing drift under 30 m per minute — within the SIH benchmark.

---

## 5. Phase 2: Sensor Noise — Sources and Mitigations

### 5.1 White Noise (Thermal Random Walk)
Zero-mean, high-frequency. Position error grows as √T. **Mitigation:** Rolling window averaging.

### 5.2 Gyroscope In-Run Bias
Temperature-dependent constant offset. Changes over minutes. **Mitigation:** Complementary filter continuously corrects via magnetometer. For highest accuracy: EKF estimates `b_g` as an explicit state variable.

### 5.3 Vehicle Vibration
Engine harmonics at 25–100 Hz; road surface broadband noise 1–500 Hz. Contaminates accelerometer continuously. **Mitigation:** Notch filter at engine harmonic. For ML: 1D-CNN convolutional kernels learn to separate navigation-relevant low-frequency signals from high-frequency vibration noise.

### 5.4 Pothole and Bump Shock
Single spike of 5–20 m/s² lasting 50–200 ms. Without filtering, triggers false high-speed detection. **Mitigation:** Rolling-window mean — a spike must sustain for ~1 second to cross threshold. For ML: explicitly classify shock events and suppress them.

### 5.5 Phone Misalignment
Phone tilted 30° on mount or placed portrait-up. Lateral road vibration bleeds into the forward channel. **Mitigation:** Automatic alignment calibration (Section 6.3) estimates and corrects the rotation matrix `R`.

### 5.6 Magnetic Hard-Iron Interference
Car engine, dashboard electronics create a constant local magnetic field that offsets the magnetometer reading by 10–40°. **Mitigation:** Hard-iron calibration from a slow 360° turn. The locus of magnetometer readings forms an ellipse; the centre offset is the correction vector.

---

## 6. Phase 3: ML Enhancement Roadmap

### 6.1 Why Classical DR is Not Enough

| Capability | Classical DR | After ML |
|---|---|---|
| Heading (direction) | ✅ Complementary filter | ✅ EKF + mag calibration |
| Speed (magnitude) | ❌ Binary heuristic ±40% | ✅ 1D-CNN ±5–10% |
| Vibration filtering | ❌ None | ✅ Learned by CNN |
| Phone alignment | ❌ Assumed flat | ✅ SVD/PCA calibration |
| Road constraint | ❌ Flies through walls | ✅ HMM map-matching + NHC |

---

### 6.2 Module A: AI Speed and Vibration Filter

**Goal:** Directly predict instantaneous forward speed (m/s) from a time window of raw IMU data, bypassing double integration entirely.

**Input:** Last 50 IMU samples at 10 Hz (= 5 seconds).  
**Features per sample:** `[a_x, a_y, a_z, ω_x, ω_y, ω_z]`  
**Input tensor shape:** `(50, 6)`  
**Target:** Forward vehicle speed from wheel odometry in IO-VNBD (not GPS — more accurate).

**Recommended Architecture — 1D-CNN:**

```
Input (50, 6)
  → Conv1D(32 filters, kernel=5) + ReLU + BatchNorm
  → Conv1D(64 filters, kernel=3) + ReLU + BatchNorm
  → MaxPooling1D(2)
  → Conv1D(128 filters, kernel=3) + ReLU + BatchNorm
  → GlobalAveragePooling1D()
  → Dense(64) + ReLU + Dropout(0.2)
  → Dense(1)   ← scalar m/s output
```

~50K parameters. Inference < 1 ms on a modern smartphone via TFLite NNAPI delegate.
Small kernels detect vibration spikes; larger effective receptive field detects cornering patterns.

**Alternative — TCN (Temporal Convolutional Network):**

Uses dilated causal convolutions to capture patterns at multiple scales simultaneously:
- Dilation 1: captures 50 ms patterns (vibration, potholes)
- Dilation 4: captures 200 ms patterns (bump recovery)
- Dilation 16: captures 800 ms patterns (acceleration/braking)

No data leakage (causal), parallelisable (faster than LSTM), ~5 ms inference.

**Alternative — Bi-LSTM (accuracy upper bound):**

```
Input (50, 6) → Bi-LSTM(64) → Bi-LSTM(32) → Dense(32) → Dense(1)
```

Best modelling quality at ~8 ms inference. Acceptable at 10 Hz, too slow for 200 Hz edge deployment. Use as reference to measure accuracy ceiling.

**Training on IO-VNBD:**

```
1. Load all CSVs, align S-Dataset + V-Dataset by timestamp → 10 Hz grid
2. Remove static periods (variance < threshold for > 2 s)
3. Extract windows with 50% overlap (stride = 5 samples)
4. TEMPORAL SPLIT ONLY — never random:
     Train: first 80% of each drive
     Test:  last 20% of each drive
5. Normalize per channel: x_norm = (x - μ) / σ
   (store μ, σ with model for inference)
6. Loss: MAE + 0.1 × velocity_consistency_penalty
   (penalises large speed jumps between adjacent windows)
```

**Expected performance:**

| Model | MAE (m/s) | vs. heuristic |
|---|---|---|
| Binary heuristic (current) | ~5.0 | baseline |
| Random Forest | ~1.5–2.5 | 50–70% improvement |
| 1D-CNN | ~0.4–0.8 | 84–92% |
| TCN | ~0.3–0.5 | 90–94% |
| Bi-LSTM | ~0.2–0.4 | 92–96% |

---

### 6.3 Module B: In-Vehicle Alignment and Calibration

**Problem:** IMU reports forces in the phone's body frame. Navigation needs them in the vehicle frame. The rotation `R` is unknown.

**Automatic alignment from a straight drive segment:**

During straight driving at near-constant speed (low gyro magnitude + steady GPS speed), the forward acceleration dominates. Apply SVD:

```python
A = array of [a_x, a_y, a_z] samples during straight drive   # shape (N, 3)
_, _, Vt = np.linalg.svd(A.T @ A)
forward_axis_body = Vt[0]    # first principal component = vehicle forward in body frame
```

For roll: when stationary, `[a_x, a_y, a_z]_static` = gravity in body frame. The rotation mapping this to `[0, 0, -9.81]` gives the roll and pitch correction.

Together, these fully determine `R`. All DR math then operates on `R · a_body` instead of raw `a_body`.

**At the SIH finale:** Run this automatic calibration during the first 30 seconds of straight driving, lock `R` for the session.

---

### 6.4 Module C: GNSS+INS Fusion with AI

**Foundation — Extended Kalman Filter (EKF):**

State vector:
```
x = [φ, λ, v, ψ, b_a, b_g]ᵀ
    (latitude, longitude, speed, heading, accel_bias, gyro_bias)
```

**Predict step** (every IMU sample, 10–200 Hz):
```
x_(k|k-1) = f(x_(k-1|k-1), u_k)         ← integrate IMU
P_(k|k-1) = F_k · P_(k-1) · F_kᵀ + Q   ← propagate uncertainty
```

**Update step** (every GNSS fix, ~1 Hz):
```
K = P_(k|k-1) · Hᵀ · (H · P_(k|k-1) · Hᵀ + R)⁻¹    ← Kalman Gain
x_(k|k) = x_(k|k-1) + K · (z_gps - H · x_(k|k-1))   ← fuse measurement
P_(k|k) = (I - K · H) · P_(k|k-1)                    ← reduce uncertainty
```

`Q` = how much we trust the IMU. `R` = how much we trust the GPS. `K` = optimal blend weight computed automatically.

**When GNSS is lost:** No update step runs. The EKF predicts forward using IMU only — this is pure DR, but now with bias estimation running in the background.

**AI Enhancement 1 — Adaptive R (GNSS Noise Covariance):**

Train a small MLP (~5K parameters) to predict `R` dynamically:

```
Input:  [satellite_count, HDOP, avg_C/N₀, recent_position_jump]
Output: scalar R (GNSS measurement noise variance)
```

Urban canyon → large R → Kalman gain K → 0 → trust IMU, ignore noisy GPS.  
Open highway → small R → K → 1 → trust GPS, correct IMU drift.

**AI Enhancement 2 — TCN Speed as Pseudo-Measurement:**

Once Module A is trained, inject its output into the EKF at every IMU step:

```
z_speed = v_TCN                     ← ML speed prediction
R_speed = MAE_TCN²                  ← empirical uncertainty from validation
```

The EKF treats this as an additional sensor reading and blends it with the IMU using the Kalman Gain. This is the critical integration point between the ML speed model and the navigation engine — the ML output becomes a properly uncertainty-weighted Bayesian measurement.

---

### 6.5 Module D: Map-Matching and Non-Holonomic Constraints

**Non-Holonomic Constraints (NHC) — Physics as a Free Sensor:**

A wheeled vehicle cannot slide sideways or fly vertically. In the vehicle frame:

```
v_lateral = 0   (cannot slide sideways)
v_vertical = 0  (cannot fly or sink)
```

These are pseudo-measurements injected into the EKF at **every time step**, even with no GNSS:

```
z_NHC = [0, 0]ᵀ
R_NHC = [0.01, 0.01]   (very small — we are very confident in this)
```

Effect: the EKF physically cannot drift the estimated position sideways. Lateral drift is reduced by 60–80%. All remaining drift is forced forward (along the travel direction), which the speed model then minimises.

**Map-Matching with Hidden Markov Model (HMM-MM):**

After the EKF produces a position estimate, project it onto the nearest OSM road:

- **States:** road segments `r_i` in the OSM graph
- **Emission probability:** `P(observation | r_i)` based on distance from EKF position to road segment
- **Transition probability:** `P(r_j | r_i)` based on road connectivity and speed plausibility
- **Viterbi algorithm** finds the most likely road sequence in O(N × K)

Map-matching provides:
1. Guaranteed on-road position
2. Road bearing for heading correction
3. One-way street enforcement (constrains velocity direction)
4. Impossible path rejection (cannot cross rivers or buildings)

**OSM Database setup:**
1. Download `.pbf` for target region (Delhi NCR ≈ 300 MB)
2. Convert to SQLite with R-tree spatial index using `osmosis`
3. Runtime road query within 500 m bounding box: < 5 ms

---

## 7. IO-VNBD Dataset — What It Provides and How to Use It

**Signals available at 10 Hz:**

```
timestamp | accel_x | accel_y | accel_z | gyro_x | gyro_y | gyro_z
speed (wheel odometry) | gps_lat | gps_lon | heading
```

**Module-to-data mapping:**

| Module | Input Features | Ground Truth Label |
|---|---|---|
| A: Speed Model | `accel_{x,y,z}`, `gyro_{x,y,z}` windowed (50 samples) | `speed` (wheel encoder) |
| B: Alignment | `accel_{x,y,z}` during straight drive | `heading` from GPS |
| C: EKF Tuning | All IMU + GPS metadata | `gps_lat`, `gps_lon` |
| D: Map-Matching | `gps_lat`, `gps_lon`, `speed`, `heading` | OSM road segment (spatial query) |

**Full preprocessing pipeline:**

```python
1. Load S-Dataset + V-Dataset CSVs, merge on timestamp
2. Interpolate to uniform 10 Hz grid
3. Remove static periods: all channels near-zero variance for > 2 s
4. Segment drives: detect straight, turn, braking, combined
5. Extract windows: N=50 samples, stride=5 (50% overlap)
6. TEMPORAL SPLIT (not random):
     Train: first 80% of each drive's chronological sequence
     Test:  last 20%
7. Normalize per channel per drive:
     x_norm = (x - μ_drive) / σ_drive
     Save μ, σ → deploy with model for inference
```

Why normalize per-drive rather than globally: different drives may have different phone mounting orientations, changing the sign and scale of individual axes. Global normalization would corrupt this.

---

## 8. Performance Benchmarks and Target Metrics

| Metric | SIH Requirement | Current Prototype | ML Target |
|---|---|---|---|
| DR drift / 50 m walk | < 5 m | ~15–25 m | < 3 m |
| DR drift / 1 km at 60 kmph | < 100 m | ~300–500 m | < 50 m |
| Position update rate | 10 Hz (phone) | 5 Hz | 10 Hz |
| Heading accuracy | < 5° | ~10–15° | < 3° |
| GNSS → DR transition | < 100 ms | ~200 ms | < 50 ms |
| Speed error (vehicle) | — | ±40–60% | ±5–10% |
| Lateral drift (vehicle) | Minimal | Unconstrained | Near-zero (NHC) |

---

## 9. On-Device Deployment Strategy

**Training (offline, laptop or cloud):**
- Train in PyTorch or TensorFlow on IO-VNBD
- Validate on held-out chronological 20% of each drive
- Export: **TFLite FlatBuffer** for Android, **CoreML** for iOS
- Bundle normalisation `μ`/`σ` as a JSON file alongside the model

**Inference (on-device, real-time at 10 Hz):**

```
50-sample IMU buffer
  → Normalise with stored μ/σ
  → TFLite 1D-CNN inference (< 2 ms, NNAPI delegate)
  → v_predicted (m/s)
  → EKF pseudo-measurement update
  → Map-match to OSM road (< 5 ms)
  → Display position on Flutter map
```

**TFLite Acceleration:**
- **NNAPI delegate:** offloads to dedicated NPU/DSP (Android 8.1+)
- **GPU delegate:** uses phone GPU for matrix operations
- 1D-CNN typical latency: 0.5–2 ms, leaving 98 ms free at 10 Hz

**Memory Budget:**

| Component | Size |
|---|---|
| 1D-CNN TFLite model | ~200 KB |
| OSM SQLite (Delhi NCR) | ~300 MB |
| EKF state + covariance | < 1 KB |
| Flutter app + UI assets | ~50 MB |
| **Total** | **< 400 MB** |

Fits comfortably on any modern smartphone (minimum 4 GB RAM).

---

## 10. Current Prototype Status

| Component | Status | Notes |
|---|---|---|
| Live IMU capture (Accel, Gyro, Mag) | ✅ Complete | `sensors_plus`, all 3 axes |
| Live GNSS capture | ✅ Complete | `geolocator`, `bestForNavigation` accuracy |
| WebSocket streaming pipeline | ✅ Complete | Flutter ↔ FastAPI, 5 Hz |
| Gyroscope deadband filter | ✅ Complete | 0.05 rad/s threshold |
| Complementary filter heading | ✅ Complete | α = 0.96 (Python backend) |
| Magnetometer heading seeding | ✅ Complete | Correct initial heading on blackout |
| Angle wraparound correction | ✅ Complete | `angle_lerp` handles 359° → 1° |
| Rolling-window step detection | ✅ Complete | 5-sample mean variance |
| Spherical position update | ✅ Complete | WGS-84, R = 6,378,137 m |
| Flutter display smoothing | ✅ Complete | 15% LPF at 20 fps |
| GNSS/DR seamless toggle | ✅ Complete | Sub-200 ms transition |
| Trajectory visualization | ✅ Complete | Blue = GPS, Red = DR, capped at 500 points |
| Destination pin + bearing label | ✅ Complete | Live distance in metres |
| Auto-reconnect on crash | ✅ Complete | 5-second retry loop |
| Permission error feedback | ✅ Complete | Snackbar notifications |
| **Binary speed model** | **⚠️ Heuristic** | **PRIMARY ML TARGET — Module A** |
| Vehicle vibration filtering | ❌ Planned | Implicit in 1D-CNN (Module A) |
| Alignment calibration | ❌ Planned | SVD/PCA (Module B) |
| EKF GNSS+INS fusion | ❌ Planned | Kalman filter (Module C) |
| Map-matching + NHC | ❌ Planned | OSM + HMM-MM (Module D) |

> **The single highest-impact next step:** Replace the binary speed heuristic with the trained 1D-CNN speed model (Module A). This changes the speed error from ±40% to ±5–10%, which reduces 1 km drift from ~400 m to < 50 m — the difference between failing and meeting the SIH benchmark.

---

## 11. References

1. **Groves, P.D.** (2013). *Principles of GNSS, Inertial, and Multisensor Integrated Navigation Systems*, 2nd ed. Artech House. — Definitive reference for INS/GNSS fusion, EKF derivations, error modelling.

2. **Onyekpe et al.** (2021). *IO-VNBD: Inertial and Odometry Vehicle Navigation Benchmark Dataset.* — Primary dataset for this problem statement.

3. **Herath, S., Yan, H., Furukawa, Y.** (2020). *RONIN: Robust Neural Inertial Navigation in the Wild.* ICRA 2020. — LSTM velocity estimation from IMU, pedestrian context, comparable methodology.

4. **Yan, H., Shan, Q., Furukawa, Y.** (2018). *RIDI: Robust IMU Double Integration.* ECCV 2018. — SVM/regression velocity estimation from IMU; foundational work for this approach.

5. **Madgwick, S.O.H.** (2010). *An Efficient Orientation Filter for Inertial and Inertial/Magnetic Sensor Arrays.* — Mathematical basis for the complementary filter implemented here.

6. **Bai, S., Kolter, J.Z., Koltun, V.** (2018). *An Empirical Evaluation of Generic Convolutional and Recurrent Networks for Sequence Modelling.* arXiv:1803.01271. — TCN vs LSTM comparison; basis for the 1D-CNN architecture choice.

7. **Newson, P., Krumm, J.** (2009). *Hidden Markov Map Matching Through Noise and Sparseness.* ACM GIS 2009. — The HMM-MM algorithm for road map-matching (Section 6.5).

8. **Dissanayake et al.** (2001). *A Solution to the Simultaneous Localisation and Map Building Problem.* IEEE Transactions on Robotics. — EKF-SLAM theory underpinning the fusion filter.

9. **OpenStreetMap Foundation** — OSM `.pbf` data and Overpass API for offline map database.

10. **TensorFlow Lite Guide** (2023). Google. — TFLite on-device inference, NNAPI delegate, model quantisation.

---

*Smart India Hackathon (SIH) 2025 — Team IDR*  
*Prototype: `app_dem/` (Flutter) + `backend/` (Python FastAPI)*
