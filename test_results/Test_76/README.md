# Test 76 — Dual Pulse Simulation (2.76 m Injector)

## Test Configuration
- **Model**: Pierce_Gun_PIC_v8_Integrated_SC_Extended_V1.m
- **Beamline length**: 2.76 m (partial injector)
- **Pulse mode**: Dual pulse (120 ns each, 100 ns inter-pulse gap)
- **Pressure**: 1.0e-06 mbar
- **Beam energy**: 1.7 MeV (γ = 4.33)
- **Cathode temperature**: 1200 K

## Key Results
- **Emission current**: 1,460 A (steady state)
- **Transmission**: 93.9% (anode to drift exit)
- **Anode efficiency**: 100%
- **Wall losses**: 6.0%
- **Backstreaming**: 0.0%
- **Runtime**: 229,735 seconds (63.8 hours)

## Ion Accumulation
- Total ionizations: 5.71e+11
- Peak ion density: 3.83e+08 /m³
- Neutralization fraction: ~2e-6 (negligible)
- Ion effect on transmission: <0.1%

## Contents
- Command Window output (.docx) ✓ (uploaded)
- Beam envelope evolution (Pulse 1 and Pulse 2)
- Current transport and collection efficiency
- Ion accumulation and space charge effects
- Ion spatial distribution analysis
- Beam cross-section profiles at diagnostic stations
- Phase space (r-r') at key locations
- Twiss parameter analysis
- Pulse comparison plots
- Inter-pulse electron cloud analysis

## Notes
Test 76 uses identical settings to Test 75 but with different random seed for particle emission. Provides statistical comparison with Test 75.