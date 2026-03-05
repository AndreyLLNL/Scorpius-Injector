# Scorpius-Injector

MATLAB digital-twin model of the **Scorpius** electron-beam injector for a
Linear Inductive Accelerator (LIA).  The model covers the complete physical
length of the injector, from the photocathode to the end of the 8.305 m drift
pipe, and includes all hardware components and beam-physics solvers.

---

## Physical layout

```
z = 0.000 m  │  Photocathode (field-emission)
z = 0.120 m  │  Anode plane  (grounded, diode gap = 120 mm, −3 MV on cathode)
z = 0.120 m  │  Start of 8.305 m drift / transport pipe
              │   ├── 49 solenoids / focusing magnets
              │   └── 19 Beam Parameter Meters (BPMs)
z = 8.425 m  │  End of drift pipe
```

Hardware components
| Component | Description |
|-----------|-------------|
| **Cathode** | Field-emission velvet cathode, r = 30 mm, 2 kA peak |
| **Anode** | Grounded accelerating electrode, diode gap 120 mm |
| **Walls** | Grounded stainless-steel vacuum vessel |
| **Drift pipe** | 8.305 m stainless-steel transport pipe, bore r = 80 mm |
| **Solenoids 1–4** | Gun solenoids (focusing + bucking) around the diode |
| **Solenoids 5–49** | FODO-like transport lattice along the drift pipe |
| **BPMs** | 2× ICT, 3× button, 13× stripline, 1× Faraday cup |

---

## Repository structure

| File | Purpose |
|------|---------|
| `injector_model.m` | **Main script** – runs the full simulation end-to-end |
| `build_hardware.m` | Hardware builder – assembles cathode, anode, walls, pipe, solenoids, BPMs |
| `solve_fields.m` | Electromagnetic field solver (solenoid superposition + diode E-field) |
| `beam_dynamics.m` | RMS beam-envelope tracker (ODE45, space-charge + emittance) |
| `plot_results.m` | Visualisation – 4 diagnostic figures |
| `define_solenoids.m` | Returns an array of 49 solenoid parameter structures |
| `define_bpms.m` | Returns an array of BPM parameter structures |
| `test_injector_model.m` | MATLAB unit tests (`matlab.unittest.TestCase`) |

---

## Quick start

```matlab
% Add the repository root to the MATLAB path (if not already done)
addpath('/path/to/Scorpius-Injector');

% Run the full simulation
injector_model
```

Four figures will be generated:
1. On-axis magnetic field Bz(z) with solenoid footprints
2. 2-D colour map of |B(r,z)|
3. RMS beam-envelope R(z) with BPM readout markers
4. Diode electrostatic potential φ(z)

---

## Running tests

```matlab
results = runtests('test_injector_model');
disp(results)
```

---

## Requirements

* MATLAB R2019b or later (uses `ode45`, `interp1`, `gradient`)
* No additional toolboxes required
