# Scorpius-Injector

**Digital Twin simulation model of the E-Beam Injector for the Scorpius Linear Inductive Accelerator.**

The `scorpius_injector` Python package provides a physics-based model that mirrors the real injector in sufficient detail to support:

- Pre-shot operational planning and parameter optimisation.
- Sensitivity studies across a wide range of operating scenarios.
- Training datasets for machine-learning-based diagnostics.
- Fault detection and root-cause analysis.

---

## Physical model

The simulation covers the complete injection chain from cathode emission to the end of the transport beamline:

| Subsystem | Module | Physics |
|-----------|--------|---------|
| Cathode | `cathode.py` | Child-Langmuir space-charge-limited emission; Richardson-Dushman thermionic emission |
| Accelerating diode | `diode.py` | Relativistic beam energy; initial phase-space state from cathode temperature and geometry |
| Voltage pulse | `pulse.py` | Trapezoidal waveform with raised-cosine transitions; energy-per-shot calculation |
| Solenoid magnets | `focusing.py` | Smooth Enge-type fringe-field profile; Larmor wavenumber; thin-lens focal length |
| Beam transport | `transport.py` | Coupled KV envelope equations with space-charge (generalised perveance) integrated by scipy RK45 |
| Virtual diagnostics | `diagnostics.py` | Current transformer (FCT), beam position monitor (BPM), OTR profile screen, Faraday cup |

The beam state is represented by its RMS phase-space moments (σ_x, σ_{x'}, σ_y, σ_{y'}) and the derived Twiss/Courant-Snyder parameters, emittances, and generalised perveance.

### KV envelope equations

The transverse beam envelopes X(z) = σ_x(z), Y(z) = σ_y(z) are evolved according to:

```
X'' + κ(z) X − ε_x² / X³ − K / (X + Y) = 0
Y'' + κ(z) Y − ε_y² / Y³ − K / (X + Y) = 0
```

where κ(z) is the solenoid focusing gradient, ε_x, ε_y are the geometric rms emittances, and K = I / (I_A β³γ³) is the generalised perveance (I_A ≈ 17 045 A is the Alfvén current).

---

## Installation

```bash
pip install -r requirements.txt
pip install -e .
```

Requires Python ≥ 3.8, NumPy ≥ 1.21, SciPy ≥ 1.7, Matplotlib ≥ 3.4.

---

## Quick start

```python
from scorpius_injector import InjectorSimulation

# Run with default Scorpius-class configuration
sim    = InjectorSimulation()
result = sim.run()

# Print scalar summary at the end of the beamline
print(result.summary())

# Access full envelope arrays for plotting
arrs = result.envelope_arrays()
# arrs["z"]       – axial positions (m)
# arrs["sigma_x"] – horizontal RMS beam size (m)
# arrs["sigma_y"] – vertical RMS beam size (m)
# arrs["eps_nx"]  – normalised emittance x (m·rad)

# Inspect diagnostic readbacks
for meas in result.measurements:
    print(meas["name"], meas["device_type"], meas)
```

### Custom configuration

```python
from scorpius_injector.config import InjectorConfig

cfg = InjectorConfig.default_scorpius()
cfg.diode.voltage          = 2.5e6   # reduce gun voltage to 2.5 MV
cfg.cathode.radius         = 0.030   # increase cathode radius to 30 mm
cfg.pulse.flat_top_voltage = 2.5e6   # keep pulse consistent

sim    = InjectorSimulation(cfg)
result = sim.run()
```

---

## Repository layout

```
scorpius_injector/
    __init__.py        – public API
    constants.py       – SI physical constants
    config.py          – configuration dataclasses
    beam.py            – BeamState (moments, Twiss, emittance, perveance)
    cathode.py         – emission models
    diode.py           – accelerating diode
    pulse.py           – drive-voltage waveform
    focusing.py        – solenoid magnet
    transport.py       – KV envelope integrator
    diagnostics.py     – virtual instruments
    simulation.py      – InjectorSimulation orchestrator
tests/
    test_beam.py
    test_cathode.py
    test_diode.py
    test_pulse.py
    test_focusing.py
    test_diagnostics.py
    test_transport.py
    test_simulation.py
```

---

## Running tests

```bash
pytest tests/ -v
```

All 117 unit tests cover every module and key physical relationships.
