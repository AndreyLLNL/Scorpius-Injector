# Scorpius Injector — Simulation Test Results

## Test Matrix

| Test | Beamline | Pulses | Pressure (mbar) | Transmission | Status |
|------|----------|--------|-----------------|-------------|--------|
| **Test 75** | 2.76 m | 2 | 1.0e-06 | TBD | Data uploading |
| **Test 76** | 2.76 m | 2 | 1.0e-06 | 93.9% | Complete |
| **Full 8.3m** | 8.305 m | 1 | 1.0e-07 | In progress | Running (at 212 ns) |

## Folder Structure

each test folder contains:
```
Test_XX/
├── README.md                    (test configuration and key results)
├── Command_Window_Test_XX.docx  (full MATLAB Command Window output)
├── Fig_XX_description.png       (numbered figure files)
└── ...
```

## Comparative Analysis
- **Test 75 vs Test 76**: Statistical reproducibility (identical settings, different emission seeds)
- **2.76 m vs 8.3 m**: Transport scaling and B-R margin evolution over full beamline
