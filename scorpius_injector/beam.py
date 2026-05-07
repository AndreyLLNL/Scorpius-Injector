"""
Beam-state representation for the E-Beam Injector simulation.

The beam is described by its RMS (root-mean-square) phase-space moments,
which is the standard description used in beam-envelope codes.  The full
6-D phase space is projected onto the two transverse planes (x, y) and
the longitudinal plane is characterised only by the mean kinetic energy
and beam current.

Coordinate system
-----------------
z   – longitudinal axis (direction of beam propagation), in metres.
x   – horizontal transverse coordinate, in metres.
x'  – dx/dz, horizontal angle (rad).
y   – vertical transverse coordinate, in metres.
y'  – dy/dz, vertical angle (rad).

Twiss / Courant-Snyder parametrisation
---------------------------------------
Given the second-order moments σ_x² = ⟨x²⟩, σ_{x'}² = ⟨x'²⟩,
σ_{xx'} = ⟨xx'⟩, the geometric RMS emittance is

    ε_x = √(σ_x² σ_{x'}² − σ_{xx'}²)

and the Twiss parameters are

    β_x  =  σ_x²  / ε_x          (m rad⁻¹)
    α_x  = −σ_{xx'} / ε_x        (dimensionless)
    γ_x  = (1 + α_x²) / β_x      (rad m⁻¹)

The normalized emittance is  ε_nx = βγ · ε_x  where β, γ are the
relativistic factors of the beam.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

from .constants import (
    ALFVEN_CURRENT,
    ELECTRON_REST_ENERGY_EV,
    SPEED_OF_LIGHT,
)


@dataclass
class BeamState:
    """Complete RMS state of the electron beam at a longitudinal position.

    Attributes
    ----------
    position :
        Axial position z (m).
    kinetic_energy :
        Mean kinetic energy of the beam (eV).
    current :
        Instantaneous beam current (A).
    sigma_x, sigma_y :
        RMS beam radii in x and y (m).
    sigma_xp, sigma_yp :
        RMS angular divergences in x' and y' (rad).
    sigma_xxp, sigma_yyp :
        Cross-correlations ⟨x x'⟩ and ⟨y y'⟩ (m rad).
    x_centroid, y_centroid :
        Centroid positions (m).
    xp_centroid, yp_centroid :
        Centroid angles (rad).
    """

    position: float = 0.0

    # --- Energy ---
    kinetic_energy: float = 0.0   # eV

    # --- Current ---
    current: float = 0.0          # A

    # --- RMS beam sizes ---
    sigma_x: float = 0.01         # m
    sigma_y: float = 0.01         # m

    # --- RMS angular divergences ---
    sigma_xp: float = 1e-3        # rad
    sigma_yp: float = 1e-3        # rad

    # --- Phase-space correlations ---
    sigma_xxp: float = 0.0        # m rad
    sigma_yyp: float = 0.0        # m rad

    # --- Centroid ---
    x_centroid: float = 0.0       # m
    y_centroid: float = 0.0       # m
    xp_centroid: float = 0.0      # rad
    yp_centroid: float = 0.0      # rad

    # ------------------------------------------------------------------ #
    # Relativistic parameters                                             #
    # ------------------------------------------------------------------ #

    @property
    def gamma(self) -> float:
        """Relativistic Lorentz factor γ = 1 + T/(m_e c²)."""
        return 1.0 + self.kinetic_energy / ELECTRON_REST_ENERGY_EV

    @property
    def beta(self) -> float:
        """Relativistic velocity factor β = v/c."""
        g = self.gamma
        return math.sqrt(1.0 - 1.0 / (g * g))

    @property
    def beta_gamma(self) -> float:
        """Relativistic momentum factor βγ."""
        return self.beta * self.gamma

    @property
    def momentum(self) -> float:
        """Relativistic momentum p = βγ m_e c  (kg m/s)."""
        from .constants import ELECTRON_MASS
        return self.beta_gamma * ELECTRON_MASS * SPEED_OF_LIGHT

    # ------------------------------------------------------------------ #
    # Emittance                                                           #
    # ------------------------------------------------------------------ #

    @property
    def emittance_x(self) -> float:
        """Geometric RMS emittance in x  ε_x  (m rad)."""
        disc = self.sigma_x**2 * self.sigma_xp**2 - self.sigma_xxp**2
        return math.sqrt(max(disc, 0.0))

    @property
    def emittance_y(self) -> float:
        """Geometric RMS emittance in y  ε_y  (m rad)."""
        disc = self.sigma_y**2 * self.sigma_yp**2 - self.sigma_yyp**2
        return math.sqrt(max(disc, 0.0))

    @property
    def normalized_emittance_x(self) -> float:
        """Normalized RMS emittance  ε_nx = βγ ε_x  (m rad)."""
        return self.beta_gamma * self.emittance_x

    @property
    def normalized_emittance_y(self) -> float:
        """Normalized RMS emittance  ε_ny = βγ ε_y  (m rad)."""
        return self.beta_gamma * self.emittance_y

    # ------------------------------------------------------------------ #
    # Twiss / Courant-Snyder parameters                                   #
    # ------------------------------------------------------------------ #

    @property
    def twiss_alpha_x(self) -> float:
        """Twiss α parameter in x  (dimensionless)."""
        eps = self.emittance_x
        if eps > 0.0:
            return -self.sigma_xxp / eps
        return 0.0

    @property
    def twiss_beta_x(self) -> float:
        """Twiss β parameter in x  (m rad⁻¹)."""
        eps = self.emittance_x
        if eps > 0.0:
            return self.sigma_x**2 / eps
        return float("inf")

    @property
    def twiss_gamma_x(self) -> float:
        """Twiss γ parameter in x  (rad m⁻¹)."""
        eps = self.emittance_x
        if eps > 0.0:
            return self.sigma_xp**2 / eps
        return float("inf")

    @property
    def twiss_alpha_y(self) -> float:
        """Twiss α parameter in y  (dimensionless)."""
        eps = self.emittance_y
        if eps > 0.0:
            return -self.sigma_yyp / eps
        return 0.0

    @property
    def twiss_beta_y(self) -> float:
        """Twiss β parameter in y  (m rad⁻¹)."""
        eps = self.emittance_y
        if eps > 0.0:
            return self.sigma_y**2 / eps
        return float("inf")

    @property
    def twiss_gamma_y(self) -> float:
        """Twiss γ parameter in y  (rad m⁻¹)."""
        eps = self.emittance_y
        if eps > 0.0:
            return self.sigma_yp**2 / eps
        return float("inf")

    # ------------------------------------------------------------------ #
    # Space charge                                                        #
    # ------------------------------------------------------------------ #

    @property
    def perveance(self) -> float:
        """Generalised beam perveance  K = I / (I_A β³ γ³)  (dimensionless).

        This quantity measures the strength of space-charge forces relative
        to the beam's inertia.
        """
        b = self.beta
        g = self.gamma
        denom = ALFVEN_CURRENT * b**3 * g**3
        if denom > 0.0:
            return self.current / denom
        return 0.0

    # ------------------------------------------------------------------ #
    # Convenience                                                         #
    # ------------------------------------------------------------------ #

    def copy(self) -> "BeamState":
        """Return a shallow copy of this state."""
        from dataclasses import replace
        return replace(self)

    def summary(self) -> dict:
        """Return a dict of key beam parameters for logging/display."""
        return {
            "z_m":              self.position,
            "KE_MeV":           self.kinetic_energy * 1e-6,
            "I_kA":             self.current * 1e-3,
            "sigma_x_mm":       self.sigma_x * 1e3,
            "sigma_y_mm":       self.sigma_y * 1e3,
            "eps_nx_mmmrad":    self.normalized_emittance_x * 1e6,
            "eps_ny_mmmrad":    self.normalized_emittance_y * 1e6,
            "perveance":        self.perveance,
            "beta_gamma":       self.beta_gamma,
        }
