function car = buildCar(design, cat)
% BUILDCAR  Turn a carDesign() struct into the car the simulator drives.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   car = buildCar(design)
%   car = buildCar(design, cat)     with a catalogue other than parts() (tuning)
%
%   design  struct from student/carDesign.m (team, colour, motor, battery,
%           tyres, aero, gearing)
%   car     struct with every number the physics needs:
%             team, colour, parts (the chosen ids), cost, budget,
%             mass, mu, Crr, power, CdA, ClA, vGear, Fgear,
%             batteryWh, batteryJ, wheelbase, maxSteer, steerRate, eta, rho, g
%
%   An unknown option, a missing part or an over-budget design is an error
%   (identifier 'AIGP:design') with a message that says how to fix it.
%
%   See also: parts, carDesign, garage

    if nargin < 2 || isempty(cat), cat = parts(); end
    if ~isstruct(design) || ~isscalar(design)
        error('AIGP:design', 'carDesign() must return a struct.');
    end

    car.team   = "Team";
    car.colour = [0.95 0.35 0.10];
    if isfield(design, 'team'), car.team = string(design.team); end
    if isfield(design, 'colour')
        c = double(design.colour);
        if numel(c) ~= 3 || any(~isfinite(c)) || any(c < 0 | c > 1)
            error('AIGP:design', 'car.colour must be an RGB triple with values between 0 and 1, e.g. [0.95 0.35 0.10].');
        end
        car.colour = reshape(c, 1, 3);
    end

    car.cost = 0;
    mass = cat.fixed.chassisMass;
    for name = cat.partNames
        options = cat.(name);
        ids = [options.id];
        if ~isfield(design, name)
            error('AIGP:design', 'carDesign() has no "%s". Choose one of: %s.', name, strjoin(ids, ' | '));
        end
        choice = string(design.(name));
        k = find(strcmpi(ids, choice), 1);
        if ~isscalar(choice) || isempty(k)
            error('AIGP:design', 'Unknown %s "%s". Choose one of: %s.', name, strjoin(string(choice), ','), strjoin(ids, ' | '));
        end
        opt = options(k);
        car.parts.(name) = opt.id;
        car.cost = car.cost + opt.cost;
        mass = mass + opt.mass;
    end
    car.budget = cat.budget;
    if car.cost > cat.budget
        error('AIGP:design', 'This car costs %d credits but the budget is %d. Swap a part for a cheaper option.', ...
            car.cost, cat.budget);
    end

    m  = cat.motor(strcmp([cat.motor.id], car.parts.motor));
    b  = cat.battery(strcmp([cat.battery.id], car.parts.battery));
    t  = cat.tyres(strcmp([cat.tyres.id], car.parts.tyres));
    a  = cat.aero(strcmp([cat.aero.id], car.parts.aero));
    gr = cat.gearing(strcmp([cat.gearing.id], car.parts.gearing));

    car.mass      = mass;
    car.mu        = t.mu;
    car.Crr       = t.Crr;
    car.power     = m.power;
    car.CdA       = a.CdA;
    car.ClA       = a.ClA;
    car.vGear     = gr.vGear;
    car.Fgear     = gr.Fgear;
    car.batteryWh = b.energyWh;
    car.batteryJ  = b.energyWh * 3600;
    f = cat.fixed;
    car.wheelbase = f.wheelbase;
    car.maxSteer  = f.maxSteer;
    car.steerRate = f.steerRate;
    car.eta       = f.eta;
    car.rho       = f.rho;
    car.g         = f.g;
end
