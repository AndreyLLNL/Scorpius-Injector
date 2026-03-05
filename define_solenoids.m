function solenoids = define_solenoids()
% DEFINE_SOLENOIDS  Return parameters for all 49 solenoids/magnets along
%                   the Scorpius injector beamline.
%
% Each solenoid structure contains:
%   id        - sequential index (1..49)
%   name      - human-readable label
%   z_center  - longitudinal centre position along beamline [m]
%   length    - axial coil length [m]
%   inner_radius - inner bore radius [m]
%   outer_radius - outer coil radius [m]
%   turns     - number of wire turns
%   current   - design operating current [A]
%   Bz_peak   - on-axis peak field at design current [T]
%   type      - 'focusing' | 'bucking' | 'steering'
%
% Layout overview
%   z = 0       : photocathode face
%   z = 0.120   : anode plane
%   z = 0.120 - 8.425 : drift / transport section (8.305 m pipe)
%   Solenoids 1-4   : gun solenoids (embedded around the diode)
%   Solenoids 5-49  : transport / focusing lattice along the drift pipe

    N = 49;
    solenoids(N) = struct('id', [], 'name', '', ...
                          'z_center', [], 'length', [], ...
                          'inner_radius', [], 'outer_radius', [], ...
                          'turns', [], 'current', [], ...
                          'Bz_peak', [], 'type', '');

    % ------------------------------------------------------------------
    % Gun solenoids  (ids 1-4)
    % Provide the solenoidal immersion / bucking field at the diode gap
    %
    % Columns: id, z_center, length, Ri, Ro, turns, I_A, Bz_T, type
    % ------------------------------------------------------------------
    gun_data = {
        1,  0.030,  0.060,  0.040,  0.090,  120,  1500,  0.25,  'focusing'
        2,  0.075,  0.060,  0.040,  0.090,  120,  1500,  0.25,  'focusing'
        3,  0.100,  0.040,  0.035,  0.080,   80,  1200,  0.18,  'bucking'
        4,  0.155,  0.060,  0.040,  0.090,  120,  1500,  0.25,  'focusing'
    };

    for k = 1:size(gun_data, 1)
        id = gun_data{k, 1};
        solenoids(id).id           = id;
        solenoids(id).name         = sprintf('GunSol_%02d', id);
        solenoids(id).z_center     = gun_data{k, 2};
        solenoids(id).length       = gun_data{k, 3};
        solenoids(id).inner_radius = gun_data{k, 4};
        solenoids(id).outer_radius = gun_data{k, 5};
        solenoids(id).turns        = gun_data{k, 6};
        solenoids(id).current      = gun_data{k, 7};
        solenoids(id).Bz_peak      = gun_data{k, 8};
        solenoids(id).type         = gun_data{k, 9};
    end

    % ------------------------------------------------------------------
    % Transport / focusing lattice  (ids 5-49)
    % Equally spaced FODO-like cells along the 8.305 m drift pipe.
    % The pipe starts at z = 0.120 m (anode plane) and ends at
    % z = 0.120 + 8.305 = 8.425 m.
    % ------------------------------------------------------------------
    n_transport = 45;                   % solenoids 5..49
    z_pipe_start = 0.220;               % first lattice solenoid centre [m]
    z_pipe_end   = 8.350;               % last  lattice solenoid centre [m]
    z_positions  = linspace(z_pipe_start, z_pipe_end, n_transport);

    for j = 1:n_transport
        id = 4 + j;
        % Alternate stronger / weaker magnets for a FODO-like lattice
        if mod(j, 2) == 1
            turns   = 200;
            current = 2000;
            Bz      = 0.35;
            t       = 'focusing';
        else
            turns   = 160;
            current = 1600;
            Bz      = 0.28;
            t       = 'focusing';
        end

        solenoids(id).id           = id;
        solenoids(id).name         = sprintf('TranSol_%02d', id);
        solenoids(id).z_center     = z_positions(j);
        solenoids(id).length       = 0.080;
        solenoids(id).inner_radius = 0.045;
        solenoids(id).outer_radius = 0.100;
        solenoids(id).turns        = turns;
        solenoids(id).current      = current;
        solenoids(id).Bz_peak      = Bz;
        solenoids(id).type         = t;
    end
end
