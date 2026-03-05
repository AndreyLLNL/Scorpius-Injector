"""Tests for scorpius_injector.cathode – emission models."""

import math
import pytest

from scorpius_injector.cathode import Cathode
from scorpius_injector.config import CathodeConfig
from scorpius_injector.constants import (
    BOLTZMANN,
    ELECTRON_CHARGE,
    ELECTRON_MASS,
    SPEED_OF_LIGHT,
    VACUUM_PERMITTIVITY,
)


@pytest.fixture
def default_cathode():
    return Cathode(CathodeConfig(radius=0.025, work_function=2.0, temperature=1400.0))


class TestCathodeGeometry:
    def test_area(self, default_cathode):
        expected = math.pi * 0.025**2
        assert default_cathode.area == pytest.approx(expected, rel=1e-9)

    def test_area_scales_with_radius(self):
        c1 = Cathode(CathodeConfig(radius=0.01))
        c2 = Cathode(CathodeConfig(radius=0.02))
        assert c2.area == pytest.approx(4.0 * c1.area, rel=1e-9)


class TestChildLangmuir:
    def test_zero_voltage(self, default_cathode):
        assert default_cathode.child_langmuir_current(0.0, 0.1) == 0.0

    def test_negative_voltage(self, default_cathode):
        assert default_cathode.child_langmuir_current(-1e6, 0.1) == 0.0

    def test_zero_gap(self, default_cathode):
        assert default_cathode.child_langmuir_current(1e6, 0.0) == 0.0

    def test_voltage_scaling(self, default_cathode):
        """Child-Langmuir J ∝ V^(3/2)."""
        I1 = default_cathode.child_langmuir_current(1.0e6, 0.1)
        I2 = default_cathode.child_langmuir_current(2.0e6, 0.1)
        assert I2 == pytest.approx(I1 * (2.0 ** 1.5), rel=1e-6)

    def test_gap_scaling(self, default_cathode):
        """Child-Langmuir J ∝ 1/d²."""
        I1 = default_cathode.child_langmuir_current(3.0e6, 0.10)
        I2 = default_cathode.child_langmuir_current(3.0e6, 0.20)
        assert I2 == pytest.approx(I1 * 0.25, rel=1e-6)

    def test_current_positive(self, default_cathode):
        I = default_cathode.child_langmuir_current(3.0e6, 0.10)
        assert I > 0.0

    def test_current_increases_with_area(self):
        small = Cathode(CathodeConfig(radius=0.01))
        large = Cathode(CathodeConfig(radius=0.03))
        I_small = small.child_langmuir_current(3.0e6, 0.10)
        I_large = large.child_langmuir_current(3.0e6, 0.10)
        assert I_large > I_small


class TestRichardsonDushman:
    def test_zero_temperature(self, default_cathode):
        assert default_cathode.richardson_dushman_current(0.0) == 0.0

    def test_negative_temperature(self, default_cathode):
        assert default_cathode.richardson_dushman_current(-100.0) == 0.0

    def test_current_increases_with_temperature(self, default_cathode):
        I_low  = default_cathode.richardson_dushman_current(1200.0)
        I_high = default_cathode.richardson_dushman_current(1600.0)
        assert I_high > I_low

    def test_current_positive_at_nominal_temperature(self, default_cathode):
        I = default_cathode.richardson_dushman_current(1400.0)
        assert I > 0.0

    def test_uses_config_temperature_by_default(self, default_cathode):
        I_default = default_cathode.richardson_dushman_current()
        I_explicit = default_cathode.richardson_dushman_current(1400.0)
        assert I_default == pytest.approx(I_explicit, rel=1e-9)


class TestEmissionCurrent:
    def test_limited_by_cl_when_rd_larger(self):
        """Saturated cathode: RD current >> CL current → CL limit wins."""
        # Very hot cathode (RD >> CL), modest voltage
        cfg = CathodeConfig(radius=0.025, work_function=1.0, temperature=2000.0)
        cat = Cathode(cfg)
        I_cl = cat.child_langmuir_current(0.5e6, 0.1)
        I_rd = cat.richardson_dushman_current(2000.0)
        assert I_rd > I_cl  # pre-condition
        assert cat.emission_current(0.5e6, 0.1, temperature=2000.0) == pytest.approx(I_cl, rel=1e-9)

    def test_emission_current_non_negative(self, default_cathode):
        assert default_cathode.emission_current(3.0e6, 0.1) >= 0.0


class TestThermalEmittance:
    def test_thermal_emittance_positive(self, default_cathode):
        assert default_cathode.thermal_emittance > 0.0

    def test_thermal_emittance_scales_with_radius(self):
        c1 = Cathode(CathodeConfig(radius=0.01, temperature=1400.0))
        c2 = Cathode(CathodeConfig(radius=0.02, temperature=1400.0))
        assert c2.thermal_emittance == pytest.approx(2.0 * c1.thermal_emittance, rel=1e-9)

    def test_thermal_emittance_scales_with_sqrt_temperature(self):
        c1 = Cathode(CathodeConfig(radius=0.025, temperature=1000.0))
        c2 = Cathode(CathodeConfig(radius=0.025, temperature=4000.0))
        assert c2.thermal_emittance == pytest.approx(2.0 * c1.thermal_emittance, rel=1e-6)
