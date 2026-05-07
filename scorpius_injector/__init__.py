"""
Scorpius Injector – Digital Twin simulation package.

Provides a physics-based model of the E-Beam Injector for the Scorpius
Linear Inductive Accelerator.  The model mirrors the real hardware in
sufficient detail to support pre-shot operational planning, parameter
sensitivity studies, and machine-learning training datasets.

Quick start::

    from scorpius_injector import InjectorSimulation

    sim    = InjectorSimulation()
    result = sim.run()
    print(result.summary())

Sub-modules
-----------
constants    – Physical constants (SI).
config       – Configuration dataclasses for every subsystem.
beam         – BeamState: RMS phase-space moments and derived quantities.
cathode      – Cathode emission models (Child-Langmuir, Richardson-Dushman).
diode        – Accelerating diode and initial beam-state generation.
pulse        – Drive-voltage pulse waveform model.
focusing     – Solenoid magnet model with Enge fringe-field profile.
transport    – KV beam-envelope ODE integrator (scipy RK45).
diagnostics  – Virtual FCT, BPM, OTR screen, Faraday cup.
simulation   – Top-level InjectorSimulation orchestrator.
"""

from .simulation import InjectorSimulation, SimulationResult
from .config import InjectorConfig
from .beam import BeamState

__all__ = [
    "InjectorSimulation",
    "SimulationResult",
    "InjectorConfig",
    "BeamState",
]
