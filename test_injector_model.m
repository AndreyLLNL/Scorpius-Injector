% TEST_INJECTOR_MODEL  Unit tests for the Scorpius injector model.
%
% Run from the MATLAB command window:
%
%   >> test_injector_model
%
% Or using the MATLAB unit-test framework:
%
%   >> results = runtests('test_injector_model');
%   >> disp(results)

classdef test_injector_model < matlab.unittest.TestCase

    % ==================================================================
    % Tests for define_solenoids
    % ==================================================================
    methods (Test)

        function test_solenoid_count(testCase)
            % Must return exactly 49 solenoids
            sol = define_solenoids();
            testCase.verifyEqual(numel(sol), 49, ...
                'Expected exactly 49 solenoid entries.');
        end

        function test_solenoid_ids_sequential(testCase)
            % IDs must run 1..49 without gaps
            sol = define_solenoids();
            ids = [sol.id];
            testCase.verifyEqual(ids, 1:49, ...
                'Solenoid IDs are not sequential 1..49.');
        end

        function test_solenoid_positions_in_range(testCase)
            % All solenoid centres must lie within beamline [0, 8.425] m
            sol = define_solenoids();
            z   = [sol.z_center];
            testCase.verifyGreaterThanOrEqual(min(z), 0, ...
                'A solenoid is upstream of the cathode.');
            testCase.verifyLessThanOrEqual(max(z), 8.425, ...
                'A solenoid is beyond the end of the drift pipe.');
        end

        function test_solenoid_physical_dimensions(testCase)
            % Inner radius must be strictly less than outer radius
            sol = define_solenoids();
            for k = 1:numel(sol)
                if isempty(sol(k).id), continue; end
                testCase.verifyLessThan(sol(k).inner_radius, ...
                    sol(k).outer_radius, ...
                    sprintf('Solenoid %d: Ri >= Ro.', k));
            end
        end

        function test_solenoid_positive_current(testCase)
            % All solenoids must have positive design current
            sol = define_solenoids();
            for k = 1:numel(sol)
                if isempty(sol(k).id), continue; end
                testCase.verifyGreaterThan(sol(k).current, 0, ...
                    sprintf('Solenoid %d has non-positive current.', k));
            end
        end

        function test_solenoid_types_valid(testCase)
            % Type must be one of the allowed strings
            allowed = {'focusing', 'bucking', 'steering'};
            sol = define_solenoids();
            for k = 1:numel(sol)
                if isempty(sol(k).id), continue; end
                testCase.verifyTrue(ismember(sol(k).type, allowed), ...
                    sprintf('Solenoid %d has invalid type "%s".', ...
                    k, sol(k).type));
            end
        end

    end  % solenoid tests

    % ==================================================================
    % Tests for define_bpms
    % ==================================================================
    methods (Test)

        function test_bpm_nonempty(testCase)
            bpms = define_bpms();
            testCase.verifyGreaterThan(numel(bpms), 0, ...
                'No BPMs returned.');
        end

        function test_bpm_ids_sequential(testCase)
            bpms = define_bpms();
            ids  = [bpms.id];
            testCase.verifyEqual(ids, 1:numel(bpms), ...
                'BPM IDs are not sequential.');
        end

        function test_bpm_positions_in_range(testCase)
            bpms = define_bpms();
            z    = [bpms.z_position];
            testCase.verifyGreaterThanOrEqual(min(z), 0, ...
                'A BPM is upstream of the cathode.');
            testCase.verifyLessThanOrEqual(max(z), 8.425, ...
                'A BPM is beyond the end of the drift pipe.');
        end

        function test_bpm_types_valid(testCase)
            allowed = {'stripline', 'button', 'Faraday_cup', 'ICT'};
            bpms = define_bpms();
            for k = 1:numel(bpms)
                testCase.verifyTrue(ismember(bpms(k).type, allowed), ...
                    sprintf('BPM %d has invalid type "%s".', k, bpms(k).type));
            end
        end

    end  % bpm tests

    % ==================================================================
    % Tests for build_hardware
    % ==================================================================
    methods (Test)

        function test_hardware_fields_present(testCase)
            hw = build_hardware();
            testCase.verifyTrue(isfield(hw, 'cathode'),    'Missing hw.cathode');
            testCase.verifyTrue(isfield(hw, 'anode'),      'Missing hw.anode');
            testCase.verifyTrue(isfield(hw, 'walls'),      'Missing hw.walls');
            testCase.verifyTrue(isfield(hw, 'drift_pipe'), 'Missing hw.drift_pipe');
            testCase.verifyTrue(isfield(hw, 'solenoids'),  'Missing hw.solenoids');
            testCase.verifyTrue(isfield(hw, 'bpms'),       'Missing hw.bpms');
        end

        function test_drift_pipe_length(testCase)
            hw = build_hardware();
            testCase.verifyEqual(hw.drift_pipe.length, 8.305, 'AbsTol', 1e-6, ...
                'Drift pipe length must be exactly 8.305 m.');
        end

        function test_cathode_upstream_of_anode(testCase)
            hw = build_hardware();
            testCase.verifyLessThan(hw.cathode.z_position, ...
                hw.anode.z_position, ...
                'Cathode must be upstream (smaller z) of anode.');
        end

        function test_anode_grounded(testCase)
            hw = build_hardware();
            testCase.verifyEqual(hw.anode.voltage_V, 0.0, ...
                'Anode must be at 0 V (grounded).');
        end

        function test_walls_grounded(testCase)
            hw = build_hardware();
            testCase.verifyEqual(hw.walls.potential_V, 0.0, ...
                'Walls must be at 0 V (grounded).');
        end

        function test_accelerating_voltage_negative(testCase)
            % Cathode voltage must be negative (electrons accelerated toward anode)
            hw = build_hardware();
            testCase.verifyLessThan(hw.anode.accel_voltage_V, 0, ...
                'Accelerating voltage on cathode must be negative.');
        end

    end  % hardware tests

    % ==================================================================
    % Tests for solve_fields
    % ==================================================================
    methods (Test)

        function test_fields_output_dimensions(testCase)
            hw     = build_hardware();
            z_grid = (0 : 0.010 : 8.425)';
            r_grid = (0 : 0.010 : 0.080)';
            f      = solve_fields(hw, z_grid, r_grid);

            Nz = numel(z_grid);
            Nr = numel(r_grid);
            testCase.verifyEqual(numel(f.Bz_axis), Nz, ...
                'Bz_axis length mismatch.');
            testCase.verifyEqual(size(f.Bz_2d), [Nr, Nz], ...
                'Bz_2d size mismatch.');
            testCase.verifyEqual(size(f.Br_2d), [Nr, Nz], ...
                'Br_2d size mismatch.');
        end

        function test_on_axis_Bz_positive_somewhere(testCase)
            hw = build_hardware();
            f  = solve_fields(hw);
            testCase.verifyGreaterThan(max(f.Bz_axis), 0, ...
                'On-axis Bz should be positive somewhere.');
        end

        function test_diode_electric_field_nonzero(testCase)
            hw = build_hardware();
            f  = solve_fields(hw);
            testCase.verifyGreaterThan(max(abs(f.Ez_diode)), 0, ...
                'Diode Ez should be non-zero.');
        end

        function test_phi_cathode_equals_accel_voltage(testCase)
            hw = build_hardware();
            z_grid = (0 : 0.001 : 0.120)';
            f  = solve_fields(hw, z_grid);
            % phi at z=0 should equal accel_voltage_V
            testCase.verifyEqual(f.phi_diode(1), hw.anode.accel_voltage_V, ...
                'AbsTol', 1e3, ...
                'Potential at cathode does not match accel_voltage_V.');
        end

    end  % field tests

    % ==================================================================
    % Tests for beam_dynamics
    % ==================================================================
    methods (Test)

        function test_beam_envelope_positive(testCase)
            hw = build_hardware();
            f  = solve_fields(hw);
            bp.energy_MeV  = 20.0;
            bp.current_A   = 2.0e3;
            bp.emittance_n = 200e-6;
            bp.r0_m        = 0.020;
            bp.rp0         = 0.0;
            beam = beam_dynamics(hw, f, bp);
            testCase.verifyGreaterThan(min(beam.R), 0, ...
                'Beam radius must remain positive throughout tracking.');
        end

        function test_bpm_readings_have_correct_count(testCase)
            hw = build_hardware();
            f  = solve_fields(hw);
            bp.energy_MeV  = 20.0;
            bp.current_A   = 2.0e3;
            bp.emittance_n = 200e-6;
            bp.r0_m        = 0.020;
            bp.rp0         = 0.0;
            beam = beam_dynamics(hw, f, bp);
            testCase.verifyEqual(numel(beam.bpm_readings), numel(hw.bpms), ...
                'Number of BPM readings should match number of BPMs.');
        end

    end  % beam dynamics tests

end  % classdef
