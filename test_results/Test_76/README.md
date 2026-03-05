# Test 76 — Dual Pulse Simulation (2.76 m Injector)

## Test Configuration
- **Model**: Pierce_Gun_PIC_v8_Integrated_SC_Extended_V1.m
- **Beamline length**: 2.76 m (partial injector)
- **Pulse mode**: Dual pulse (120 ns each, 100 ns inter-pulse gap)
- **Pressure**: 1.0e-06 mbar
- **Beam energy**: 1.7 MeV (γ = 4.33)
- **Cathode temperature**: 1200 K

## Key Results
- **Emission current**: 1460.1 A (steady state)
- **Anode efficiency**: 100.0%
- **Drift exit transmission**: 93.9%
- **Pulse-to-pulse difference**: -0.09%
- **Ion neutralization fraction**: ~2×10⁻⁶ (negligible)
- **Runtime**: 229,735 s (63.8 hours)

## Contents
- Command Window output (.docx)
- Beam envelope evolution (Pulse 1 & Pulse 2)
- Current transport and collection efficiency
- Ion accumulation and space charge effects
- Ion spatial distribution analysis
- Beam cross-section profiles at diagnostic stations
- Phase space (r-r') at key locations
- Twiss parameter analysis
- Pulse comparison plots
- Inter-pulse electron cloud diagnostics

## Notes
Test 76 uses identical settings to Test 75 but with different random seed for particle emission. Statistical comparison between T75 and T76 quantifies stochastic uncertainty.
