# Scorpius Injector — Test Results

This directory contains simulation results organized by test number.

## Test Index

| Test | Beamline | Pulses | Pressure | Key Metric | Status |
|------|----------|--------|----------|------------|--------|
| **75** | 2.76 m | Dual | 1e-6 mbar | Baseline (statistical pair with T76) | Data upload in progress |
| **76** | 2.76 m | Dual | 1e-6 mbar | Transmission 93.9%, detailed B-R analysis | Data upload in progress |

## Comparative Analysis

Tests 75 and 76 use identical simulation settings with different random seeds for particle emission. Together they quantify the statistical uncertainty in:
- Beam transmission efficiency
- RMS beam envelope
- Twiss parameters (beta, alpha)
- Ion accumulation
- Pulse-to-pulse reproducibility

## File Naming Convention

Each test folder uses the prefix T## for figure files:

T75_Fig08_Current_Transport.png
T76_Fig08_Current_Transport.png

This prevents confusion when figures from different tests appear visually similar.