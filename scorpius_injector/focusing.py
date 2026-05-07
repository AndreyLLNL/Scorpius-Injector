"""
Magnetic focusing elements for the E-Beam Injector.

Solenoid model
--------------
The on-axis magnetic field of a finite solenoid is modelled with an
Enge-inspired smooth fringe-field function:

    B_z(z) = B_0 / [(1 + exp( a (z − z₁)/R)) · (1 + exp(−a (z − z₂)/R))]

where z₁ and z₂ are the entrance and exit faces, R is the bore radius, and
a = 3 is the Enge sharpness coefficient.  This smoothly interpolates between
the hard-edge (a → ∞) and no-boundary (a → 0) limits.

The Larmor focusing wavenumber (applicable in the beam-envelope equations) is

    κ(z) = [e B_z(z) / (2 p)]²

where p = βγ m_e c is the relativistic momentum of the beam.

Focal length
------------
For a solenoid traversed by a paraxial beam the thin-lens focal length is

    1/f = (e / 2p)² · ∫ B_z²(z) dz

This is evaluated numerically using trapezoidal integration.
"""

from __future__ import annotations

import math

import numpy as np

from .config import SolenoidConfig
from .constants import ELECTRON_CHARGE, ELECTRON_MASS, SPEED_OF_LIGHT

# Enge sharpness coefficient (dimensionless)
_ENGE_A: float = 3.0

# Number of sample points used for the field integral
_N_INTEGRAL: int = 600


class Solenoid:
    """Model of a single focusing solenoid.

    Parameters
    ----------
    config :
        Solenoid geometry and excitation parameters.
    """

    def __init__(self, config: SolenoidConfig) -> None:
        self.config = config

    # ------------------------------------------------------------------ #
    # Field profile                                                       #
    # ------------------------------------------------------------------ #

    def on_axis_field(self, z: float) -> float:
        """On-axis magnetic flux density B_z at longitudinal position z (T).

        The field is modelled with a smooth Enge-type fringe-field function.

        Parameters
        ----------
        z :
            Absolute axial coordinate (m) in the beamline frame.

        Returns
        -------
        float
            B_z in Tesla.
        """
        cfg = self.config
        z1 = cfg.position                    # entrance face
        z2 = cfg.position + cfg.length       # exit face
        R  = cfg.bore_radius

        # Logistic blending at each end
        arg1 = _ENGE_A * (z - z1) / R
        arg2 = _ENGE_A * (z - z2) / R

        # Clamp to avoid exp overflow
        arg1 = max(-500.0, min(500.0, arg1))
        arg2 = max(-500.0, min(500.0, arg2))

        factor1 = 1.0 / (1.0 + math.exp(-arg1))   # rises from 0 to 1 at z1
        factor2 = 1.0 / (1.0 + math.exp( arg2))   # falls from 1 to 0 at z2

        return cfg.peak_field * factor1 * factor2

    # ------------------------------------------------------------------ #
    # Focusing strength                                                   #
    # ------------------------------------------------------------------ #

    def larmor_wavenumber(self, z: float, beta_gamma: float) -> float:
        """Larmor focusing wavenumber κ(z) = [e B_z / (2 p)]² (m⁻²).

        This is the coefficient that appears in the beam-envelope equations.

        Parameters
        ----------
        z :
            Axial position (m).
        beta_gamma :
            Relativistic momentum factor βγ of the beam.

        Returns
        -------
        float
            κ in m⁻².
        """
        Bz = self.on_axis_field(z)
        p  = beta_gamma * ELECTRON_MASS * SPEED_OF_LIGHT  # kg m/s
        if p <= 0.0:
            return 0.0
        kL = ELECTRON_CHARGE * Bz / (2.0 * p)  # m⁻¹
        return kL * kL

    def focal_length(self, beta_gamma: float) -> float:
        """Thin-lens focal length f (m) for a beam with momentum factor βγ.

        Computed via numerical integration of B_z² over the solenoid body
        plus fringe-field tails (extended by one bore radius on each side).

        Parameters
        ----------
        beta_gamma :
            Relativistic momentum factor βγ of the beam.

        Returns
        -------
        float
            Focal length in metres.  Returns +∞ when the field is zero.
        """
        cfg = self.config
        z_start = cfg.position - cfg.bore_radius
        z_end   = cfg.position + cfg.length + cfg.bore_radius
        z_arr   = np.linspace(z_start, z_end, _N_INTEGRAL)
        Bz_arr  = np.array([self.on_axis_field(float(z)) for z in z_arr])
        int_B2  = float(np.trapezoid(Bz_arr**2, z_arr))

        if int_B2 <= 0.0:
            return math.inf

        p   = beta_gamma * ELECTRON_MASS * SPEED_OF_LIGHT  # kg m/s
        k   = ELECTRON_CHARGE / (2.0 * p)                  # 1/(T m)
        return 1.0 / (k**2 * int_B2)

    # ------------------------------------------------------------------ #
    # Convenience                                                         #
    # ------------------------------------------------------------------ #

    @property
    def centre(self) -> float:
        """Axial position of the solenoid centre (m)."""
        return self.config.position + self.config.length / 2.0

    def field_array(self, z_arr: "np.ndarray") -> "np.ndarray":
        """Return B_z evaluated on an array of z positions (T).

        Parameters
        ----------
        z_arr :
            1-D array of axial positions (m).

        Returns
        -------
        numpy.ndarray
            B_z values in Tesla.
        """
        return np.array([self.on_axis_field(float(z)) for z in z_arr])
