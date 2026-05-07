# Scorpius-Injector

Digital Twin model of the E-Beam Injector for the Scorpius Linear Inductive Accelerator (LIA).

## Overview

This repository contains a MATLAB-based physics model of the injector section of the Scorpius
LIA.  The model simulates:

| Component | Description |
|-----------|-------------|
| Electron gun | Child-Langmuir space-charge-limited emission with relativistic kinematics |
| Solenoid focusing | Hard-edge solenoid lenses; thin-lens focal lengths; on-axis Bz profile |
| Beam transport | rms K-V envelope equation integrated via 4th-order Runge-Kutta |

## Repository Layout

```
matlab/
  injector_params.m      – nominal design parameters (physical constants, gun, solenoids, …)
  electron_gun.m         – electron-gun performance (current, gamma, beta, perveance, …)
  solenoid_focusing.m    – solenoid field profile, focal lengths, focusing strengths
  beam_transport.m       – beam-envelope equation solver
  injector_model.m       – main script: runs all stages and saves plots to results/
  test_injector_model.m  – unit tests for the model functions
```

## Requirements

- MATLAB R2019b or later (no additional toolboxes required)

## Quick Start

```matlab
% From inside MATLAB with the matlab/ folder on the path:
cd matlab
injector_model
```

Or from a shell:

```bash
matlab -batch "cd matlab; injector_model"
```

Output figures are written to `matlab/results/`:

| File | Content |
|------|---------|
| `envelope.png` | Beam envelope R(z) and slope R'(z) |
| `Bz_profile.png` | On-axis solenoid field Bz(z) |

## Running Tests

```matlab
cd matlab
test_injector_model
```

Or from a shell:

```bash
matlab -batch "cd matlab; test_injector_model"
```

## Physics References

1. R. C. Davidson & H. Qin, *Physics of Intense Charged Particle Beams in High Energy Accelerators*, World Scientific, 2001.
2. M. Reiser, *Theory and Design of Charged Particle Beams*, Wiley-VCH, 2nd ed., 2008.
3. T. P. Wangler, *RF Linear Accelerators*, Wiley-VCH, 2008.
