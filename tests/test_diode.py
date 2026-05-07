"""Tests for scorpius_injector.diode – accelerating diode model."""

import pytest

from scorpius_injector.cathode import Cathode
from scorpius_injector.config import CathodeConfig, DiodeConfig
from scorpius_injector.diode import Diode


@pytest.fixture
def default_diode():
    cat = Cathode(CathodeConfig(radius=0.025, temperature=1400.0))
    return Diode(DiodeConfig(voltage=3.0e6, gap_spacing=0.10), cat)


class TestDiodeEnergyAndCurrent:
    def test_kinetic_energy_equals_voltage(self, default_diode):
        assert default_diode.beam_kinetic_energy == pytest.approx(3.0e6, rel=1e-9)

    def test_beam_current_positive(self, default_diode):
        assert default_diode.beam_current > 0.0

    def test_beam_current_increases_with_voltage(self):
        cat = Cathode(CathodeConfig(radius=0.025, temperature=2000.0, work_function=1.0))
        d1  = Diode(DiodeConfig(voltage=2.0e6, gap_spacing=0.1), cat)
        d2  = Diode(DiodeConfig(voltage=3.0e6, gap_spacing=0.1), cat)
        assert d2.beam_current > d1.beam_current


class TestInitialBeamState:
    def test_position_at_anode(self, default_diode):
        st = default_diode.initial_beam_state()
        assert st.position == pytest.approx(default_diode.config.gap_spacing, rel=1e-9)

    def test_kinetic_energy_set(self, default_diode):
        st = default_diode.initial_beam_state()
        assert st.kinetic_energy == pytest.approx(3.0e6, rel=1e-9)

    def test_current_positive(self, default_diode):
        st = default_diode.initial_beam_state()
        assert st.current > 0.0

    def test_sigma_x_equals_sigma_y(self, default_diode):
        st = default_diode.initial_beam_state()
        assert st.sigma_x == pytest.approx(st.sigma_y, rel=1e-9)

    def test_sigma_x_proportional_to_cathode_radius(self):
        """σ_x = r_cathode / 2 for a uniform-density disc."""
        r = 0.03
        cat = Cathode(CathodeConfig(radius=r, temperature=1400.0))
        diode = Diode(DiodeConfig(voltage=3.0e6, gap_spacing=0.1), cat)
        st = diode.initial_beam_state()
        assert st.sigma_x == pytest.approx(r / 2.0, rel=1e-9)

    def test_divergence_positive(self, default_diode):
        st = default_diode.initial_beam_state()
        assert st.sigma_xp > 0.0

    def test_no_initial_correlation(self, default_diode):
        st = default_diode.initial_beam_state()
        assert st.sigma_xxp == pytest.approx(0.0, abs=1e-15)
        assert st.sigma_yyp == pytest.approx(0.0, abs=1e-15)

    def test_emittance_positive(self, default_diode):
        st = default_diode.initial_beam_state()
        assert st.emittance_x > 0.0
        assert st.emittance_y > 0.0
