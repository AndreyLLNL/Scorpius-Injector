"""Tests for scorpius_injector.beam – BeamState representation."""

import math
import pytest

from scorpius_injector.beam import BeamState
from scorpius_injector.constants import ALFVEN_CURRENT, ELECTRON_REST_ENERGY_EV


class TestRelativisticParameters:
    def test_gamma_at_rest(self):
        st = BeamState(kinetic_energy=0.0)
        assert st.gamma == pytest.approx(1.0)

    def test_gamma_at_511keV(self):
        """Kinetic energy equal to rest mass → γ = 2."""
        st = BeamState(kinetic_energy=ELECTRON_REST_ENERGY_EV)
        assert st.gamma == pytest.approx(2.0, rel=1e-6)

    def test_beta_less_than_unity(self):
        st = BeamState(kinetic_energy=3.0e6)
        assert 0.0 < st.beta < 1.0

    def test_beta_gamma_positive(self):
        st = BeamState(kinetic_energy=3.0e6)
        assert st.beta_gamma > 0.0

    def test_momentum_positive(self):
        st = BeamState(kinetic_energy=3.0e6)
        assert st.momentum > 0.0


class TestEmittance:
    def _make_upright_state(self, sx=0.01, sxp=5e-3, sy=0.01, syp=5e-3):
        """Beam with zero phase-space tilt → ε = σ_x * σ_x'."""
        st = BeamState()
        st.sigma_x   = sx
        st.sigma_xp  = sxp
        st.sigma_y   = sy
        st.sigma_yp  = syp
        st.sigma_xxp = 0.0
        st.sigma_yyp = 0.0
        return st

    def test_upright_emittance(self):
        st = self._make_upright_state(sx=0.01, sxp=0.005)
        assert st.emittance_x == pytest.approx(0.01 * 0.005, rel=1e-9)

    def test_normalized_emittance_larger_than_geometric(self):
        st = self._make_upright_state()
        st.kinetic_energy = 3.0e6
        assert st.normalized_emittance_x > st.emittance_x

    def test_normalized_emittance_scales_with_bg(self):
        st1 = self._make_upright_state()
        st1.kinetic_energy = 1.0e6
        st2 = self._make_upright_state()
        st2.kinetic_energy = 3.0e6
        ratio = st2.normalized_emittance_x / st1.normalized_emittance_x
        expected = st2.beta_gamma / st1.beta_gamma
        assert ratio == pytest.approx(expected, rel=1e-6)

    def test_emittance_non_negative_for_correlated_beam(self):
        """Emittance must stay ≥ 0 even with correlation."""
        st = BeamState()
        st.sigma_x   = 0.01
        st.sigma_xp  = 0.005
        # Set correlation to almost Cauchy-Schwarz limit
        st.sigma_xxp = 0.99 * st.sigma_x * st.sigma_xp
        assert st.emittance_x >= 0.0


class TestTwissParameters:
    def _beam(self):
        st = BeamState()
        st.sigma_x   = 0.01
        st.sigma_xp  = 0.005
        st.sigma_xxp = 0.0
        st.sigma_y   = 0.008
        st.sigma_yp  = 0.006
        st.sigma_yyp = 0.0
        return st

    def test_beta_x_equals_sigma_x2_over_eps(self):
        st = self._beam()
        expected = st.sigma_x**2 / st.emittance_x
        assert st.twiss_beta_x == pytest.approx(expected, rel=1e-9)

    def test_alpha_x_zero_for_upright_beam(self):
        st = self._beam()
        assert st.twiss_alpha_x == pytest.approx(0.0, abs=1e-12)

    def test_gamma_x_equals_sigma_xp2_over_eps(self):
        st = self._beam()
        expected = st.sigma_xp**2 / st.emittance_x
        assert st.twiss_gamma_x == pytest.approx(expected, rel=1e-9)


class TestPerveance:
    def test_zero_current(self):
        st = BeamState(kinetic_energy=3.0e6, current=0.0)
        assert st.perveance == 0.0

    def test_perveance_positive(self):
        st = BeamState(kinetic_energy=3.0e6, current=3000.0)
        assert st.perveance > 0.0

    def test_perveance_decreases_with_energy(self):
        """Higher energy → larger β³γ³ → smaller perveance for same current."""
        low  = BeamState(kinetic_energy=1.0e6, current=3000.0)
        high = BeamState(kinetic_energy=3.0e6, current=3000.0)
        assert high.perveance < low.perveance


class TestSummary:
    def test_summary_keys(self):
        st = BeamState(kinetic_energy=3.0e6, current=3000.0)
        s = st.summary()
        for key in ("z_m", "KE_MeV", "I_kA", "sigma_x_mm", "sigma_y_mm",
                    "eps_nx_mmmrad", "eps_ny_mmmrad", "perveance", "beta_gamma"):
            assert key in s

    def test_summary_units(self):
        st = BeamState(kinetic_energy=3.0e6, current=3000.0)
        s = st.summary()
        assert s["KE_MeV"] == pytest.approx(3.0, rel=1e-6)
        assert s["I_kA"]   == pytest.approx(3.0, rel=1e-6)
