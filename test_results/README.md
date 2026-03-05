# Scorpius Injector — Simulation Test Results

## Test Index

| Test | Configuration | Length | Pulses | Pressure | Key Metric | Status |
|------|--------------|--------|--------|----------|------------|--------|
| **Test 75** | V1 dual-pulse | 2.76 m | 2 | 1e-6 mbar | Statistical baseline | Uploading |
| **Test 76** | V1 dual-pulse | 2.76 m | 2 | 1e-6 mbar | η=93.9%, I=1460A | Uploading |
| **Full 8.3m** | V1 single-pulse | 8.305 m | 1 | 1e-7 mbar | In progress (at 212ns) | Running |

## File Naming Convention

Files in each test folder follow this pattern:
- `T##_Fig##_Description.png` — Figures (e.g., `T76_Fig08_Current_Transport.png`)
- `T##_Command_Window.docx` — Full MATLAB Command Window output
- `T##_workspace.mat` — MATLAB workspace (if uploaded)

## Comparative Analysis

Tests 75 and 76 use identical physics settings with different random seeds, enabling statistical uncertainty quantification on all beam parameters.