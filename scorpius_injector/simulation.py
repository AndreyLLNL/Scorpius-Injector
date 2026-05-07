"""
Main simulation orchestrator for the E-Beam Injector Digital Twin.

:class:`InjectorSimulation` ties together every subsystem model:

1. **Cathode** – thermionic / space-charge limited emission.
2. **Diode** – acceleration and initial beam-state generation.
3. **Beam transport** – KV envelope equations with solenoid focusing and
   space-charge forces.
4. **Virtual diagnostics** – current transformers, BPMs, OTR screens,
   Faraday cups.

Typical usage::

    from scorpius_injector import InjectorSimulation

    sim = InjectorSimulation()          # default Scorpius configuration
    result = sim.run()
    print(result.summary())

For parameter scans or multi-shot studies, pass a custom
:class:`~scorpius_injector.config.InjectorConfig`::

    from scorpius_injector.config import InjectorConfig, DiodeConfig

    cfg = InjectorConfig.default_scorpius()
    cfg.diode.voltage = 2.5e6           # reduce gun voltage
    sim = InjectorSimulation(cfg)
    result = sim.run()
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

import numpy as np

from .beam import BeamState
from .cathode import Cathode
from .config import InjectorConfig
from .diagnostics import _VirtualDiagnostic, make_diagnostic
from .diode import Diode
from .transport import BeamTransport


@dataclass
class SimulationResult:
    """Container for all outputs of a single simulation run.

    Attributes
    ----------
    config :
        Injector configuration used for this run.
    initial_state :
        Beam state at the anode exit (start of transport).
    beam_states :
        Ordered list of beam states at every integration step.
    measurements :
        List of measurement dictionaries, one per diagnostic station.
    """

    config: InjectorConfig
    initial_state: BeamState
    beam_states: List[BeamState]
    measurements: List[dict]

    def summary(self) -> Dict[str, float]:
        """Return key scalar beam parameters at the end of the beamline.

        Returns
        -------
        dict
            Dictionary with human-readable keys and SI-derived values.
        """
        final = self.beam_states[-1] if self.beam_states else self.initial_state
        return {
            "beam_energy_MeV":          final.kinetic_energy * 1.0e-6,
            "beam_current_kA":          final.current        * 1.0e-3,
            "final_sigma_x_mm":         final.sigma_x        * 1.0e3,
            "final_sigma_y_mm":         final.sigma_y        * 1.0e3,
            "norm_emittance_x_mmmrad":  final.normalized_emittance_x * 1.0e6,
            "norm_emittance_y_mmmrad":  final.normalized_emittance_y * 1.0e6,
            "perveance":                final.perveance,
            "beta_gamma":               final.beta_gamma,
        }

    def envelope_arrays(self) -> Dict[str, np.ndarray]:
        """Return NumPy arrays of key beam parameters vs. position.

        Returns
        -------
        dict
            Keys: ``z``, ``sigma_x``, ``sigma_y``, ``eps_nx``, ``eps_ny``.
            All values in SI units (m, m·rad).
        """
        z      = np.array([s.position        for s in self.beam_states])
        sig_x  = np.array([s.sigma_x         for s in self.beam_states])
        sig_y  = np.array([s.sigma_y         for s in self.beam_states])
        eps_nx = np.array([s.normalized_emittance_x for s in self.beam_states])
        eps_ny = np.array([s.normalized_emittance_y for s in self.beam_states])
        return {
            "z":      z,
            "sigma_x": sig_x,
            "sigma_y": sig_y,
            "eps_nx":  eps_nx,
            "eps_ny":  eps_ny,
        }


class InjectorSimulation:
    """E-Beam Injector Digital Twin simulation engine.

    Parameters
    ----------
    config :
        Injector configuration.  Defaults to
        :meth:`InjectorConfig.default_scorpius`.
    rng_seed :
        Seed for the pseudo-random-number generator used by the virtual
        diagnostics (enables reproducible noise).  Set to ``None`` for
        non-deterministic noise.
    """

    def __init__(
        self,
        config: Optional[InjectorConfig] = None,
        rng_seed: Optional[int] = 42,
    ) -> None:
        self.config   = config if config is not None else InjectorConfig.default_scorpius()
        self._rng     = np.random.default_rng(rng_seed)
        self.cathode  = Cathode(self.config.cathode)
        self.diode    = Diode(self.config.diode, self.cathode)
        self.transport = BeamTransport(self.config)
        self._diagnostics: List[_VirtualDiagnostic] = [
            make_diagnostic(d, rng=self._rng) for d in self.config.diagnostics
        ]

    # ------------------------------------------------------------------ #
    # Main entry point                                                    #
    # ------------------------------------------------------------------ #

    def run(self) -> SimulationResult:
        """Execute the full single-shot injector simulation.

        Steps
        -----
        1. Generate the initial beam state at the anode exit.
        2. Propagate beam envelopes through the transport lattice.
        3. Sample each virtual diagnostic at its axial position.

        Returns
        -------
        SimulationResult
            Complete simulation output.
        """
        # --- Step 1: emission & initial state ---
        initial_state = self.diode.initial_beam_state()

        # --- Step 2: envelope transport ---
        beam_states = self.transport.transport(initial_state)

        # --- Step 3: diagnostics ---
        measurements = self._collect_measurements(beam_states)

        return SimulationResult(
            config=self.config,
            initial_state=initial_state,
            beam_states=beam_states,
            measurements=measurements,
        )

    # ------------------------------------------------------------------ #
    # Internal helpers                                                    #
    # ------------------------------------------------------------------ #

    def _collect_measurements(
        self, beam_states: List[BeamState]
    ) -> List[dict]:
        """Sample all diagnostics from the nearest beam-state in z."""
        z_arr = np.array([s.position for s in beam_states])
        measurements: List[dict] = []
        for diag in self._diagnostics:
            idx   = int(np.argmin(np.abs(z_arr - diag.config.position)))
            state = beam_states[idx]
            measurements.append(diag.measure(state))
        return measurements
