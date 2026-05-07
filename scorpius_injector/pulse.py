"""
Voltage/current pulse shape model for the E-Beam Injector.

Real injector pulses are not perfect square waves.  This module implements a
trapezoidal pulse with cosine-smoothed (raised-cosine) transitions so that
the waveform has a continuous first derivative.  The model is used to:

* Provide a time-varying diode voltage V(t) for multi-shot simulations.
* Quantify how beam properties change during the rising edge, flat-top, and
  falling edge of each pulse.

Waveform definition
--------------------
Let  t₀ = 0  be the start of the pulse.

    Region            Time interval                 V(t)
    ────────────────  ────────────────────────────  ──────────────────────────
    Rise              0 ≤ t < t_rise               V_pk · ½(1 − cos(π t/t_rise))
    Flat-top          t_rise ≤ t < t_rise + t_flat  V_pk
    Fall              ≥ t_rise + t_flat             V_pk · ½(1 + cos(π(t−t_flat_end)/t_fall))
    After pulse       ≥ t_rise + t_flat + t_fall    0

where  t_flat = pulse_duration − rise_time − fall_time.
"""

from __future__ import annotations

import math
from typing import Sequence

import numpy as np

from .config import PulseConfig


class VoltPulse:
    """Model of the injector drive voltage waveform.

    Parameters
    ----------
    config :
        Pulse waveform parameters.
    """

    def __init__(self, config: PulseConfig) -> None:
        self.config = config
        t_flat = (
            config.pulse_duration - config.rise_time - config.fall_time
        )
        if t_flat < 0.0:
            raise ValueError(
                "rise_time + fall_time exceeds pulse_duration; "
                "no flat-top region exists."
            )
        self._t_flat = t_flat
        self._t_flat_end = config.rise_time + t_flat

    # ------------------------------------------------------------------ #
    # Waveform evaluation                                                 #
    # ------------------------------------------------------------------ #

    def voltage(self, t: float) -> float:
        """Instantaneous drive voltage at time t (V).

        Parameters
        ----------
        t :
            Time relative to the start of the pulse (s).

        Returns
        -------
        float
            Voltage in volts.
        """
        cfg = self.config
        V_pk = cfg.flat_top_voltage

        if t < 0.0:
            return 0.0
        if t < cfg.rise_time:
            # Raised-cosine rise
            return V_pk * 0.5 * (1.0 - math.cos(math.pi * t / cfg.rise_time))
        if t < self._t_flat_end:
            return V_pk
        t_into_fall = t - self._t_flat_end
        if t_into_fall < cfg.fall_time:
            # Raised-cosine fall
            return V_pk * 0.5 * (
                1.0 + math.cos(math.pi * t_into_fall / cfg.fall_time)
            )
        return 0.0

    def waveform(self, n_points: int = 500) -> tuple:
        """Evaluate the voltage waveform on a uniform time grid.

        Parameters
        ----------
        n_points :
            Number of sample points spanning the pulse duration.

        Returns
        -------
        tuple[numpy.ndarray, numpy.ndarray]
            (time_array_s, voltage_array_V)
        """
        t_arr = np.linspace(0.0, self.config.pulse_duration, n_points)
        v_arr = np.array([self.voltage(float(t)) for t in t_arr])
        return t_arr, v_arr

    # ------------------------------------------------------------------ #
    # Derived quantities                                                  #
    # ------------------------------------------------------------------ #

    @property
    def flat_top_duration(self) -> float:
        """Duration of the flat-top portion of the pulse (s)."""
        return self._t_flat

    @property
    def peak_voltage(self) -> float:
        """Peak flat-top voltage (V)."""
        return self.config.flat_top_voltage

    @property
    def fwhm(self) -> float:
        """Full-width at half-maximum of the pulse (s), approximated as the
        duration over which V(t) ≥ 0.5 V_pk."""
        n = 2000
        t_arr, v_arr = self.waveform(n_points=n)
        threshold = 0.5 * self.peak_voltage
        above = v_arr >= threshold
        if not above.any():
            return 0.0
        t_on  = float(t_arr[np.argmax(above)])
        # Last time index above threshold (search from the right)
        t_off = float(t_arr[len(above) - 1 - np.argmax(above[::-1])])
        return t_off - t_on

    def energy_per_shot(self, load_impedance: float) -> float:
        """Estimate the energy delivered per shot (J).

        Assumes a purely resistive load with the given impedance.

        Parameters
        ----------
        load_impedance :
            Load resistance Ω.

        Returns
        -------
        float
            Energy in joules.
        """
        if load_impedance <= 0.0:
            return 0.0
        t_arr, v_arr = self.waveform(n_points=2000)
        p_arr = v_arr**2 / load_impedance
        return float(np.trapezoid(p_arr, t_arr))
