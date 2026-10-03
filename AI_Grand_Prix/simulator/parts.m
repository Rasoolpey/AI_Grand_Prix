function cat = parts()
% PARTS  The parts catalogue for the AI Grand Prix car.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   cat = parts()
%
%   cat.budget          credits a team may spend
%   cat.fixed           values that are the same for every car
%   cat.motor, .battery, .tyres, .aero, .gearing
%                       1x3 struct arrays, one element per option.
%                       Every option has .id (the name used in carDesign.m),
%                       .label, .cost and its physical values.
%
%   Each part changes one term of the equation sheet (PHYSICS.md):
%     motor   -> P in F_drive <= min(P/v, F_gear)          (eq. 2)
%     battery -> the energy E you can spend                 (eq. 8)
%     tyres   -> mu in the friction circle, C_rr in F_roll  (eqs. 4-6)
%     aero    -> C_D*A in F_drag, C_L*A in F_down           (eqs. 3, 6)
%     gearing -> v_gear and F_gear in F_drive               (eq. 2)
%   and every part except gearing adds mass (eq. 1).
%
%   Values tuned (g3, 2026-10-03) with instructor/race/trackTuning so every
%   part is decisive on one path and costly on another (TODO_RACE §4b).
%
%   See also: buildCar, carDesign, garage

    cat.budget = 80;

    cat.fixed = struct( ...
        'chassisMass', 70, ...     % kg
        'wheelbase',   1.0, ...    % m
        'maxSteer',    0.5, ...    % rad
        'steerRate',   1.5, ...    % rad/s
        'eta',         0.85, ...   % drivetrain efficiency
        'rho',         1.2, ...    % air density, kg/m^3
        'g',           9.81);      % m/s^2

    cat.motor = struct( ...
        'id',    {"2kW", "3.5kW", "5.5kW"}, ...
        'label', {"2 kW motor", "3.5 kW motor", "5.5 kW motor"}, ...
        'power', {2000, 3500, 5500}, ...          % W at the wheels
        'mass',  {7, 11, 16}, ...
        'cost',  {10, 20, 35});

    cat.battery = struct( ...
        'id',    {"45Wh", "70Wh", "100Wh"}, ...
        'label', {"45 Wh battery", "70 Wh battery", "100 Wh battery"}, ...
        'energyWh', {45, 70, 100}, ...
        'mass',  {5, 8, 12}, ...
        'cost',  {10, 18, 30});

    cat.tyres = struct( ...
        'id',    {"hard", "medium", "soft"}, ...
        'label', {"Hard tyres", "Medium tyres", "Soft tyres"}, ...
        'mu',    {0.9, 1.1, 1.3}, ...
        'Crr',   {0.012, 0.020, 0.032}, ...
        'mass',  {0, 0, 0}, ...
        'cost',  {5, 12, 20});

    cat.aero = struct( ...
        'id',    {"none", "lowdrag", "downforce"}, ...
        'label', {"No aero kit", "Low-drag kit", "Downforce kit"}, ...
        'CdA',   {0.35, 0.30, 0.50}, ...              % m^2
        'ClA',   {0, 0.3, 1.2}, ...                   % m^2
        'mass',  {0, 2, 4}, ...
        'cost',  {0, 10, 20});

    cat.gearing = struct( ...
        'id',    {"short", "medium", "long"}, ...
        'label', {"Short gearing", "Medium gearing", "Long gearing"}, ...
        'vGear', {14, 17, 20}, ...                     % m/s, motor gives nothing at or above this
        'Fgear', {800, 560, 380}, ...                  % N, most force the gearing passes
        'mass',  {0, 0, 0}, ...
        'cost',  {0, 0, 0});

    cat.partNames = ["motor", "battery", "tyres", "aero", "gearing"];
end
