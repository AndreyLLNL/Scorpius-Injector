"""
Virtual diagnostic instruments for the E-Beam Injector simulation.

Each class mirrors a real hardware device installed along the beamline.
All measurements include a configurable Gaussian noise model so that
simulated readbacks resemble real data-acquisition outputs.

Instruments
-----------
``CurrentTransformer``
    Non-intercepting inductive pick-up coil measuring the instantaneous
    beam current (A).

``BeamPositionMonitor``
    Button-electrode BPM reporting the beam centroid position (m) in both
    transverse planes.

``OpticalTransitionRadiationScreen``
    Intercepting OTR screen producing a synthetic 2-D beam-profile image
    (pixel array).

``FaradayCup``
    Intercepting Faraday cup measuring total charge deposited, from which
    mean current and beam energy are estimated.

Factory function
----------------
:func:`make_diagnostic` returns the appropriate subclass from a
:class:`~scorpius_injector.config.DiagnosticConfig`.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import numpy as np

from .config import DiagnosticConfig

if TYPE_CHECKING:
    from .beam import BeamState


class _VirtualDiagnostic:
    """Abstract base for all virtual diagnostic instruments.

    Parameters
    ----------
    config :
        Device configuration.
    noise_fraction :
        RMS noise as a fraction of the signal level (0 → no noise).
    """

    def __init__(
        self,
        config: DiagnosticConfig,
        noise_fraction: float = 0.01,
        *,
        rng: "np.random.Generator | None" = None,
    ) -> None:
        self.config = config
        self.noise_fraction = noise_fraction
        self._rng = rng if rng is not None else np.random.default_rng()

    def _noise(self, value: float) -> float:
        """Apply Gaussian noise to a scalar measurement."""
        return float(
            value + self.noise_fraction * abs(value) * self._rng.standard_normal()
        )

    def measure(self, state: "BeamState") -> dict:
        """Return a measurement dictionary for the given beam state.

        Subclasses must override this method.
        """
        raise NotImplementedError


class CurrentTransformer(_VirtualDiagnostic):
    """Inductive current transformer (FCT).

    Returns
    -------
    dict
        ``name``, ``device_type``, ``position``, ``current_A``
    """

    def measure(self, state: "BeamState") -> dict:
        return {
            "name":        self.config.name,
            "device_type": "FCT",
            "position":    self.config.position,
            "current_A":   self._noise(state.current),
        }


class BeamPositionMonitor(_VirtualDiagnostic):
    """Button-electrode beam position monitor (BPM).

    Parameters
    ----------
    position_resolution :
        RMS single-shot position resolution (m).  Defaults to 100 µm.

    Returns
    -------
    dict
        ``name``, ``device_type``, ``position``, ``x_m``, ``y_m``
    """

    def __init__(
        self,
        config: DiagnosticConfig,
        position_resolution: float = 1.0e-4,
        *,
        rng: "np.random.Generator | None" = None,
    ) -> None:
        super().__init__(config, noise_fraction=0.0, rng=rng)
        self._pos_res = position_resolution

    def measure(self, state: "BeamState") -> dict:
        noise_x = float(self._pos_res * self._rng.standard_normal())
        noise_y = float(self._pos_res * self._rng.standard_normal())
        return {
            "name":        self.config.name,
            "device_type": "BPM",
            "position":    self.config.position,
            "x_m":         state.x_centroid + noise_x,
            "y_m":         state.y_centroid + noise_y,
        }


class OpticalTransitionRadiationScreen(_VirtualDiagnostic):
    """OTR screen producing a synthetic beam-profile image.

    The beam intensity is modelled as a 2-D Gaussian distribution with
    widths equal to the RMS beam sizes σ_x and σ_y.

    Parameters
    ----------
    n_pixels :
        Number of pixels along each axis of the square image.
    window_sigma :
        Half-width of the image window, in units of σ_beam.

    Returns
    -------
    dict
        ``name``, ``device_type``, ``position``,
        ``sigma_x_m``, ``sigma_y_m``,
        ``x_centroid_m``, ``y_centroid_m``,
        ``image`` (2-D ndarray, normalised 0–1),
        ``x_axis_m``, ``y_axis_m`` (1-D coordinate arrays)
    """

    def __init__(
        self,
        config: DiagnosticConfig,
        n_pixels: int = 128,
        window_sigma: float = 4.0,
        noise_fraction: float = 0.01,
        *,
        rng: "np.random.Generator | None" = None,
    ) -> None:
        super().__init__(config, noise_fraction=noise_fraction, rng=rng)
        self.n_pixels     = n_pixels
        self.window_sigma = window_sigma

    def measure(self, state: "BeamState") -> dict:
        sx = state.sigma_x
        sy = state.sigma_y
        xc = state.x_centroid
        yc = state.y_centroid

        x_axis = np.linspace(
            xc - self.window_sigma * sx,
            xc + self.window_sigma * sx,
            self.n_pixels,
        )
        y_axis = np.linspace(
            yc - self.window_sigma * sy,
            yc + self.window_sigma * sy,
            self.n_pixels,
        )
        X, Y = np.meshgrid(x_axis, y_axis)

        # Gaussian beam profile
        image = np.exp(
            -0.5 * ((X - xc) ** 2 / sx**2 + (Y - yc) ** 2 / sy**2)
        )

        # Add camera noise
        image += self.noise_fraction * self._rng.random(image.shape)

        # Normalize to [0, 1]
        peak = image.max()
        if peak > 0.0:
            image /= peak

        return {
            "name":          self.config.name,
            "device_type":   "OTR",
            "position":      self.config.position,
            "sigma_x_m":     self._noise(sx),
            "sigma_y_m":     self._noise(sy),
            "x_centroid_m":  xc,
            "y_centroid_m":  yc,
            "image":         image,
            "x_axis_m":      x_axis,
            "y_axis_m":      y_axis,
        }


class FaradayCup(_VirtualDiagnostic):
    """Intercepting Faraday cup for current and energy measurement.

    Returns
    -------
    dict
        ``name``, ``device_type``, ``position``, ``current_A``, ``kinetic_energy_eV``
    """

    def measure(self, state: "BeamState") -> dict:
        return {
            "name":              self.config.name,
            "device_type":       "FC",
            "position":          self.config.position,
            "current_A":         self._noise(state.current),
            "kinetic_energy_eV": self._noise(state.kinetic_energy),
        }


# ------------------------------------------------------------------ #
# Factory                                                             #
# ------------------------------------------------------------------ #

_DEVICE_MAP: dict = {
    "FCT": CurrentTransformer,
    "BPM": BeamPositionMonitor,
    "OTR": OpticalTransitionRadiationScreen,
    "FC":  FaradayCup,
}


def make_diagnostic(
    config: DiagnosticConfig,
    *,
    rng: "np.random.Generator | None" = None,
) -> _VirtualDiagnostic:
    """Create the appropriate virtual diagnostic for a given config.

    Parameters
    ----------
    config :
        Diagnostic configuration (``device_type`` field determines the class).
    rng :
        Optional seeded random-number generator for reproducible noise.

    Returns
    -------
    _VirtualDiagnostic
        Instantiated diagnostic object.

    Raises
    ------
    ValueError
        If ``config.device_type`` is not recognised.
    """
    cls = _DEVICE_MAP.get(config.device_type)
    if cls is None:
        raise ValueError(
            f"Unknown diagnostic device type '{config.device_type}'. "
            f"Valid types: {list(_DEVICE_MAP)}"
        )
    return cls(config, rng=rng)
