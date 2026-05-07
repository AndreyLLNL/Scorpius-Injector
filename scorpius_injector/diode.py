"""
Accelerating diode model for the E-Beam Injector.

The diode is the region between the cathode and the anode where the
electron beam is accelerated from rest to its initial kinetic energy.
The model:

* Computes the beam kinetic energy from the applied voltage.
* Delegates emission-current computation to the :class:`Cathode` model.
* Generates the initial :class:`BeamState` at the anode plane, setting
  beam size, divergence, and intrinsic emittance consistent with the gun
  geometry and cathode temperature.

Initial beam conditions at the anode
--------------------------------------
* **RMS beam size** – a uniform-density (Kapchinskij-Vladimirskij) disc of
  radius r = cathode radius gives  σ_x = σ_y = r / 2.
* **Thermal divergence** – the cathode emits electrons with a Maxwell-
  Boltzmann transverse-velocity distribution.  The RMS transverse angle is

      σ_{x'} = v_⊥_rms / v_z  ≈ √(k_B T / m_e) / (β c)

* **Intrinsic emittance** – ε_n = r_c √(k_B T / m_e c²) (normalised),
  consistent with :meth:`Cathode.thermal_emittance`.
"""

from __future__ import annotations

import math

from .beam import BeamState
from .cathode import Cathode
from .config import DiodeConfig
from .constants import BOLTZMANN, ELECTRON_MASS, SPEED_OF_LIGHT


class Diode:
    """Model of the accelerating diode (cathode-anode gap).

    Parameters
    ----------
    config :
        Diode geometry and voltage parameters.
    cathode :
        Cathode instance to use for emission calculations.
    """

    def __init__(self, config: DiodeConfig, cathode: Cathode) -> None:
        self.config = config
        self.cathode = cathode

    # ------------------------------------------------------------------ #
    # Primary beam parameters                                             #
    # ------------------------------------------------------------------ #

    @property
    def beam_kinetic_energy(self) -> float:
        """Beam kinetic energy at the anode (eV)."""
        return self.config.voltage

    @property
    def beam_current(self) -> float:
        """Space-charge-limited beam current at nominal voltage (A)."""
        return self.cathode.emission_current(
            self.config.voltage, self.config.gap_spacing
        )

    # ------------------------------------------------------------------ #
    # Initial beam state                                                  #
    # ------------------------------------------------------------------ #

    def initial_beam_state(self) -> BeamState:
        """Generate the initial :class:`BeamState` at the anode plane.

        The beam is assumed to have a uniform-density (KV) transverse
        distribution matched to the cathode area, with divergence set by
        the cathode temperature.

        Returns
        -------
        BeamState
            Beam state at  z = gap_spacing  (just past the anode).
        """
        state = BeamState()
        state.position = self.config.gap_spacing
        state.kinetic_energy = self.beam_kinetic_energy
        state.current = self.beam_current

        # RMS radius for a uniform disc of radius r  →  σ = r / 2
        r_c = self.cathode.config.radius
        state.sigma_x = r_c / 2.0
        state.sigma_y = r_c / 2.0

        # Thermal transverse velocity → RMS angle
        T = self.cathode.config.temperature
        v_th = math.sqrt(BOLTZMANN * T / ELECTRON_MASS)  # m/s  (non-relativistic)
        v_beam = state.beta * SPEED_OF_LIGHT
        sigma_prime = v_th / v_beam
        state.sigma_xp = sigma_prime
        state.sigma_yp = sigma_prime

        # No initial correlation (beam is upright in phase space)
        state.sigma_xxp = 0.0
        state.sigma_yyp = 0.0

        return state
