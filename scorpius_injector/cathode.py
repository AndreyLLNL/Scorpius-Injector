"""
Electron-gun cathode emission model.

Two complementary emission regimes are implemented:

Child-Langmuir (space-charge limited)
--------------------------------------
When the accelerating field is strong enough to pull away all emitted
electrons instantaneously the emission is *space-charge limited* and the
current density obeys the Child-Langmuir law for a planar diode:

    J_CL = (4 ε₀/9) √(2e/m_e) · V^(3/2) / d²
         ≈ 2.334 × 10⁻⁶ · V^(3/2) / d²   (A m⁻²)

Richardson-Dushman (temperature limited)
-----------------------------------------
At the same time, the cathode can supply at most as much current as the
temperature-activated emission permits:

    J_RD = A_R · T² · exp(−φ / k_B T)

where A_R = 1.202 × 10⁶ A m⁻² K⁻² is the universal Richardson constant,
φ is the work function (J), and T is the cathode temperature (K).

The realised emission is the smaller of the two limits.
"""

from __future__ import annotations

import math
from typing import Optional

from .config import CathodeConfig
from .constants import (
    BOLTZMANN,
    ELECTRON_CHARGE,
    ELECTRON_MASS,
    RICHARDSON_CONSTANT,
    VACUUM_PERMITTIVITY,
)


class Cathode:
    """Model of the electron-gun emitter.

    Parameters
    ----------
    config :
        Cathode geometry and material parameters.
    """

    def __init__(self, config: CathodeConfig) -> None:
        self.config = config

    # ------------------------------------------------------------------ #
    # Geometry                                                            #
    # ------------------------------------------------------------------ #

    @property
    def area(self) -> float:
        """Emission area  A = π r²  (m²)."""
        return math.pi * self.config.radius**2

    # ------------------------------------------------------------------ #
    # Space-charge-limited emission (Child-Langmuir)                     #
    # ------------------------------------------------------------------ #

    def child_langmuir_current_density(self, voltage: float, gap: float) -> float:
        """Space-charge-limited current density (A m⁻²).

        Parameters
        ----------
        voltage :
            Diode voltage (V).  Must be positive.
        gap :
            Cathode-to-anode gap spacing (m).  Must be positive.

        Returns
        -------
        float
            Current density in A m⁻².
        """
        if voltage <= 0.0 or gap <= 0.0:
            return 0.0
        cl = (4.0 * VACUUM_PERMITTIVITY / 9.0) * math.sqrt(
            2.0 * ELECTRON_CHARGE / ELECTRON_MASS
        )
        return cl * voltage**1.5 / gap**2

    def child_langmuir_current(self, voltage: float, gap: float) -> float:
        """Total space-charge-limited beam current (A).

        Integrates the Child-Langmuir current density over the emission
        area of the cathode.
        """
        return self.child_langmuir_current_density(voltage, gap) * self.area

    # ------------------------------------------------------------------ #
    # Temperature-limited emission (Richardson-Dushman)                  #
    # ------------------------------------------------------------------ #

    def richardson_dushman_current_density(
        self, temperature: Optional[float] = None
    ) -> float:
        """Thermionic current density from the Richardson-Dushman equation (A m⁻²).

        Parameters
        ----------
        temperature :
            Cathode temperature (K).  Defaults to the value in config.

        Returns
        -------
        float
            Thermionic current density in A m⁻².
        """
        T = temperature if temperature is not None else self.config.temperature
        if T <= 0.0:
            return 0.0
        phi_J = self.config.work_function * ELECTRON_CHARGE  # J
        exponent = -phi_J / (BOLTZMANN * T)
        # Guard against overflow
        if exponent < -700.0:
            return 0.0
        return RICHARDSON_CONSTANT * T**2 * math.exp(exponent)

    def richardson_dushman_current(
        self, temperature: Optional[float] = None
    ) -> float:
        """Total thermionic emission current (A)."""
        return self.richardson_dushman_current_density(temperature) * self.area

    # ------------------------------------------------------------------ #
    # Combined emission model                                             #
    # ------------------------------------------------------------------ #

    def emission_current(
        self,
        voltage: float,
        gap: float,
        temperature: Optional[float] = None,
    ) -> float:
        """Effective beam current limited by the smaller of the two regimes (A).

        The actual delivered current cannot exceed either the space-charge
        limit or the thermionic supply limit.

        Parameters
        ----------
        voltage :
            Diode voltage (V).
        gap :
            Cathode-anode gap (m).
        temperature :
            Cathode temperature (K); defaults to config value.

        Returns
        -------
        float
            Effective emission current in A.
        """
        I_cl = self.child_langmuir_current(voltage, gap)
        I_rd = self.richardson_dushman_current(temperature)
        return min(I_cl, I_rd)

    # ------------------------------------------------------------------ #
    # Cathode brightness                                                  #
    # ------------------------------------------------------------------ #

    @property
    def thermal_emittance(self) -> float:
        """Intrinsic normalized thermal emittance (m rad).

        ε_th = r_c · √(k_B T / (m_e c²))

        This is the minimum achievable normalized emittance set by the
        cathode temperature and radius.
        """
        from .constants import SPEED_OF_LIGHT
        T = self.config.temperature
        kT_over_mc2 = BOLTZMANN * T / (ELECTRON_MASS * SPEED_OF_LIGHT**2)
        return self.config.radius * math.sqrt(kT_over_mc2)
