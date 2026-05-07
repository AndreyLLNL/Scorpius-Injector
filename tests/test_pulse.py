"""Tests for scorpius_injector.pulse – voltage waveform model."""

import math
import pytest
import numpy as np

from scorpius_injector.config import PulseConfig
from scorpius_injector.pulse import VoltPulse


@pytest.fixture
def default_pulse():
    cfg = PulseConfig(
        pulse_duration=100e-9,
        rise_time=15e-9,
        fall_time=15e-9,
        flat_top_voltage=3.0e6,
    )
    return VoltPulse(cfg)


class TestPulseConstruction:
    def test_invalid_config_raises(self):
        cfg = PulseConfig(pulse_duration=20e-9, rise_time=15e-9, fall_time=15e-9)
        with pytest.raises(ValueError, match="flat-top"):
            VoltPulse(cfg)

    def test_flat_top_duration(self, default_pulse):
        expected = 100e-9 - 15e-9 - 15e-9
        assert default_pulse.flat_top_duration == pytest.approx(expected, rel=1e-9)


class TestVoltageWaveform:
    def test_zero_before_pulse(self, default_pulse):
        assert default_pulse.voltage(-1e-9) == 0.0

    def test_zero_after_pulse(self, default_pulse):
        assert default_pulse.voltage(200e-9) == 0.0

    def test_flat_top_voltage(self, default_pulse):
        t_mid = 50e-9  # middle of flat-top
        assert default_pulse.voltage(t_mid) == pytest.approx(3.0e6, rel=1e-9)

    def test_half_voltage_on_rise(self, default_pulse):
        """Raised cosine: V = V_pk/2 at t = rise_time/2."""
        t = 15e-9 / 2.0
        v = default_pulse.voltage(t)
        # At half the rise time, the raised cosine gives exactly V_pk/2
        assert v == pytest.approx(3.0e6 / 2.0, rel=1e-6)

    def test_voltage_non_negative(self, default_pulse):
        t_arr, v_arr = default_pulse.waveform(n_points=1000)
        assert np.all(v_arr >= 0.0)

    def test_voltage_bounded_by_peak(self, default_pulse):
        t_arr, v_arr = default_pulse.waveform(n_points=1000)
        assert np.all(v_arr <= default_pulse.peak_voltage + 1e-6)

    def test_waveform_returns_equal_length_arrays(self, default_pulse):
        t_arr, v_arr = default_pulse.waveform(n_points=200)
        assert len(t_arr) == 200
        assert len(v_arr) == 200

    def test_peak_voltage_property(self, default_pulse):
        assert default_pulse.peak_voltage == pytest.approx(3.0e6, rel=1e-9)


class TestFWHM:
    def test_fwhm_less_than_pulse_duration(self, default_pulse):
        assert default_pulse.fwhm < default_pulse.config.pulse_duration

    def test_fwhm_greater_than_flat_top(self, default_pulse):
        assert default_pulse.fwhm > default_pulse.flat_top_duration


class TestEnergyPerShot:
    def test_zero_impedance(self, default_pulse):
        assert default_pulse.energy_per_shot(0.0) == 0.0

    def test_energy_positive_for_resistive_load(self, default_pulse):
        assert default_pulse.energy_per_shot(50.0) > 0.0

    def test_energy_decreases_with_impedance(self, default_pulse):
        E1 = default_pulse.energy_per_shot(50.0)
        E2 = default_pulse.energy_per_shot(100.0)
        assert E1 > E2
