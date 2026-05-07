"""
Physical constants used throughout the Scorpius Injector simulation.

All values are in SI units unless noted otherwise.
"""

# Speed of light (m/s)
SPEED_OF_LIGHT: float = 2.99792458e8

# Electron rest mass (kg)
ELECTRON_MASS: float = 9.1093837015e-31

# Elementary charge magnitude (C)
ELECTRON_CHARGE: float = 1.602176634e-19

# Electron rest energy (eV)
ELECTRON_REST_ENERGY_EV: float = 0.51099895e6

# Vacuum permittivity (F/m)
VACUUM_PERMITTIVITY: float = 8.8541878128e-12

# Boltzmann constant (J/K)
BOLTZMANN: float = 1.380649e-23

# Richardson constant for thermionic emission (A m⁻² K⁻²)
RICHARDSON_CONSTANT: float = 1.20173e6

# Alfvén current  I_A = 4π ε₀ m_e c³ / e  ≈ 17045 A
ALFVEN_CURRENT: float = (
    4.0
    * 3.14159265358979
    * VACUUM_PERMITTIVITY
    * ELECTRON_MASS
    * SPEED_OF_LIGHT**3
    / ELECTRON_CHARGE
)
