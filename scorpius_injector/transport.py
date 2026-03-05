"""
Beam-envelope transport engine.

The beam is evolved along the beamline by integrating the coupled
Kapchinskij-Vladimirskij (KV) envelope equations:

    X'' + κ(z) X − ε_x² / X³ − K / (X + Y) = 0
    Y'' + κ(z) Y − ε_y² / Y³ − K / (X + Y) = 0

where

* X(z), Y(z)  – RMS beam envelopes (= σ_x, σ_y) in metres.
* κ(z) = Σ_k κ_k(z)  – total focusing gradient from all solenoids (m⁻²).
* ε_x, ε_y  – geometric RMS emittances, held constant along the drift
  (no acceleration or emittance growth).
* K  – generalised perveance (dimensionless).

The integration variable is z (the longitudinal coordinate) and the
system state is [X, X', Y, Y'].  The ODE is solved with SciPy's
``solve_ivp`` using the RK45 method with tight tolerances.

Phase-space correlations σ_{xx'} = −α_x ε_x and σ_{yy'} = −α_y ε_y
are recovered from Twiss parameters at each output step.

References
----------
* T. P. Wangler, *RF Linear Accelerators*, 2nd ed., Wiley-VCH (2008),
  Chapter 4.
* M. Reiser, *Theory and Design of Charged-Particle Beams*, Wiley (1994).
"""

from __future__ import annotations

from typing import List

import math

import numpy as np
from scipy.integrate import solve_ivp

from .beam import BeamState
from .config import InjectorConfig
from .focusing import Solenoid


class BeamTransport:
    """Integrate the KV beam-envelope equations along the injector beamline.

    Parameters
    ----------
    config :
        Master injector configuration.
    """

    def __init__(self, config: InjectorConfig) -> None:
        self.config = config
        self.solenoids: List[Solenoid] = [
            Solenoid(sc) for sc in config.solenoids
        ]

    # ------------------------------------------------------------------ #
    # Focusing gradient                                                   #
    # ------------------------------------------------------------------ #

    def total_focusing_gradient(self, z: float, beta_gamma: float) -> float:
        """Sum of Larmor wavenumbers κ(z) from all solenoids (m⁻²).

        Parameters
        ----------
        z :
            Axial position (m).
        beta_gamma :
            Relativistic momentum factor βγ of the beam.

        Returns
        -------
        float
            Total κ in m⁻².
        """
        return sum(s.larmor_wavenumber(z, beta_gamma) for s in self.solenoids)

    # ------------------------------------------------------------------ #
    # ODE right-hand side                                                 #
    # ------------------------------------------------------------------ #

    def _rhs(
        self,
        z: float,
        y: np.ndarray,
        emittance_x: float,
        emittance_y: float,
        perveance: float,
        beta_gamma: float,
    ) -> np.ndarray:
        """RHS of the KV envelope ODEs.

        State vector  y = [X, X', Y, Y']  where X = σ_x, Y = σ_y.

        Parameters
        ----------
        z :
            Current longitudinal position (m).
        y :
            State vector.
        emittance_x, emittance_y :
            Geometric RMS emittances (m rad).
        perveance :
            Generalised beam perveance K.
        beta_gamma :
            Relativistic momentum factor βγ.

        Returns
        -------
        numpy.ndarray
            dy/dz with shape (4,).
        """
        X, Xp, Y, Yp = y

        # Guard against collapse to zero radius
        X = max(X, 1.0e-9)
        Y = max(Y, 1.0e-9)

        kappa = self.total_focusing_gradient(z, beta_gamma)

        # KV envelope equations (equal focusing in x and y for solenoid)
        Xpp = (
            -kappa * X
            + emittance_x**2 / X**3
            + perveance / (X + Y)
        )
        Ypp = (
            -kappa * Y
            + emittance_y**2 / Y**3
            + perveance / (X + Y)
        )

        return np.array([Xp, Xpp, Yp, Ypp])

    # ------------------------------------------------------------------ #
    # Public interface                                                    #
    # ------------------------------------------------------------------ #

    def transport(self, initial_state: BeamState) -> List[BeamState]:
        """Transport the beam from the diode exit to the end of the beamline.

        The emittances and energy are assumed constant (no acceleration in the
        transport section).

        Parameters
        ----------
        initial_state :
            Beam state at the entrance to the transport lattice.

        Returns
        -------
        list of BeamState
            One entry per integration output point (``config.n_steps``
            evenly-spaced positions from *initial_state.position* to
            *config.total_length*).
        """
        z0  = initial_state.position
        z1  = self.config.total_length
        n   = self.config.n_steps

        eps_x   = initial_state.emittance_x
        eps_y   = initial_state.emittance_y
        K       = initial_state.perveance
        bg      = initial_state.beta_gamma
        KE      = initial_state.kinetic_energy
        current = initial_state.current

        # Convert BeamState moments to envelope-equation initial conditions.
        # The ODE uses X = σ_x and X' = dσ_x/dz = σ_{xx'} / σ_x.
        X0  = initial_state.sigma_x
        Xp0 = initial_state.sigma_xxp / X0 if X0 > 0.0 else 0.0
        Y0  = initial_state.sigma_y
        Yp0 = initial_state.sigma_yyp / Y0 if Y0 > 0.0 else 0.0

        y0 = np.array([X0, Xp0, Y0, Yp0])

        z_eval = np.linspace(z0, z1, n)

        sol = solve_ivp(
            fun=lambda z, y: self._rhs(z, y, eps_x, eps_y, K, bg),
            t_span=(z0, z1),
            y0=y0,
            method="RK45",
            t_eval=z_eval,
            rtol=1.0e-8,
            atol=1.0e-12,
            dense_output=False,
        )

        states: List[BeamState] = []
        for i, z in enumerate(sol.t):
            X  = abs(float(sol.y[0, i]))
            Xp = float(sol.y[1, i])   # dX/dz  (derivative of rms envelope)
            Y  = abs(float(sol.y[2, i]))
            Yp = float(sol.y[3, i])   # dY/dz

            st = BeamState()
            st.position       = float(z)
            st.kinetic_energy = KE
            st.current        = current

            st.sigma_x = X
            st.sigma_y = Y

            # The ODE state Xp = dσ_x/dz is NOT the rms divergence σ_{x'}.
            # The Twiss relation gives:
            #   σ_{x'}² = ε_x² / σ_x² + (dσ_x/dz)²
            # which correctly preserves emittance:  ε = √(σ_x² σ_{x'}² − σ_{xx'}²)
            # and the phase-space correlation:      σ_{xx'} = σ_x · (dσ_x/dz)
            if X > 0.0:
                st.sigma_xp  = math.sqrt(eps_x**2 / X**2 + Xp**2)
                st.sigma_xxp = X * Xp
            else:
                st.sigma_xp  = 0.0
                st.sigma_xxp = 0.0

            if Y > 0.0:
                st.sigma_yp  = math.sqrt(eps_y**2 / Y**2 + Yp**2)
                st.sigma_yyp = Y * Yp
            else:
                st.sigma_yp  = 0.0
                st.sigma_yyp = 0.0

            st.x_centroid  = initial_state.x_centroid
            st.y_centroid  = initial_state.y_centroid
            st.xp_centroid = initial_state.xp_centroid
            st.yp_centroid = initial_state.yp_centroid

            states.append(st)

        return states
