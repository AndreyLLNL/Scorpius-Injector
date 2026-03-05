from setuptools import setup, find_packages

setup(
    name="scorpius_injector",
    version="0.1.0",
    description="Digital Twin simulation model of the E-Beam Injector for the Scorpius Linear Inductive Accelerator",
    packages=find_packages(),
    python_requires=">=3.8",
    install_requires=[
        "numpy>=1.21",
        "scipy>=1.7",
        "matplotlib>=3.4",
    ],
    extras_require={
        "test": ["pytest>=7.0"],
    },
)
