function g = garage(varargin)
% GARAGE  See your car: drawing, spec sheet, strengths, budget and equations.
%
%   garage                    your car from student/carDesign.m
%   garage(design)            any design struct (same fields as carDesign) -
%                             handy to compare candidates without editing files
%   garage(..., 'Plot', false)   print the spec sheet only (no figure)
%   g = garage(...)           also return the numbers
%
%   Spec sheet (all from the equation sheet, PHYSICS.md):
%     mass, power-to-weight, top speed (gearing or power/drag limit, eqs. 1-3),
%     0-10 m/s time (eqs. 1, 2), safe corner speed at R 10 m and R 40 m
%     (eq. 6), and the ESTIMATED benchmark time and energy on each practice
%     path.  The estimates assume the car follows the centreline with
%     near-perfect driving (benchmarkTime); they are not properties of the
%     parts alone, and your controller decides how close you get.
%
%   See also: carDesign, practiceRace, benchmarkTime, cornerSpeed

    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'), fullfile(thisDir, 'simulator', 'physics'), ...
            fullfile(thisDir, 'student'), fullfile(thisDir, 'tracks'));
    p = inputParser();  p.StructExpand = false;     % a design struct is a design, not options
    p.addOptional('Design', []);
    p.addParameter('Plot', true);
    p.parse(varargin{:});
    design = p.Results.Design;
    if isempty(design), design = carDesign(); end

    cat = parts();
    open = cat;  open.budget = Inf;                % show an over-budget car instead of refusing it
    car = buildCar(design, open);
    car.budget = cat.budget;
    overBudget = car.cost > cat.budget;

    % ---- numbers -------------------------------------------------------- %
    g.car = car;
    g.cost = car.cost;  g.budget = cat.budget;  g.overBudget = overBudget;
    g.mass = car.mass;
    g.powerToWeight = car.power / car.mass;
    vPower = fzero(@(v) car.power / v - (0.5 * car.rho * car.CdA * v^2 + car.Crr * car.mass * car.g), [1 100]);
    g.topSpeed = min(car.vGear, vPower);
    g.topSpeedLimit = "gearing";  if vPower < car.vGear, g.topSpeedLimit = "power vs drag"; end
    g.t0to10 = timeTo(car, 10);
    g.corner10 = cornerSpeed(car, 1/10);
    g.corner40 = cornerSpeed(car, 1/40);
    names = ["drag", "technical", "endurance", "mud"];
    for i = 1:numel(names)
        b = benchmarkTime(car, loadPath(names(i)));
        g.estimate.(names(i)) = struct('time', b.time, 'energyWh', b.energyWh, 'capped', b.capped, 'feasible', b.feasible);
    end
    g.assumption = "Estimates: car on the centreline, near-perfect driving, simple speed-cap energy strategy (benchmarkTime).";

    % ---- print ---------------------------------------------------------- %
    fprintf('\n================ GARAGE: %s ================\n', car.team);
    fprintf('  %-8s %-14s %s\n', 'motor', car.parts.motor, sprintf('P = %.1f kW         -> F_drive <= min(P/v, F_gear)   (eq. 2)', car.power / 1000));
    fprintf('  %-8s %-14s %s\n', 'battery', car.parts.battery, sprintf('E = %d Wh           -> E <- E - F_drive v dt / eta   (eq. 8)', car.batteryWh));
    fprintf('  %-8s %-14s %s\n', 'tyres', car.parts.tyres, sprintf('mu = %.2f, C_rr = %.3f -> grip mu N, F_roll = C_rr N (eqs. 4-6)', car.mu, car.Crr));
    fprintf('  %-8s %-14s %s\n', 'aero', car.parts.aero, sprintf('C_D A = %.2f, C_L A = %.1f -> drag and downforce (eq. 3)', car.CdA, car.ClA));
    fprintf('  %-8s %-14s %s\n', 'gearing', car.parts.gearing, sprintf('v_gear = %d m/s, F_gear = %d N                    (eq. 2)', car.vGear, car.Fgear));
    fprintf('  ------------------------------------------------------------\n');
    if overBudget
        fprintf('  COST     %d / %d credits   <-- OVER BUDGET: this car cannot race\n', car.cost, cat.budget);
    else
        fprintf('  Cost     %d / %d credits\n', car.cost, cat.budget);
    end
    fprintf('  Mass     %.0f kg     power-to-weight %.0f W/kg\n', g.mass, g.powerToWeight);
    fprintf('  Top speed %.1f m/s (%s)     0-10 m/s in %.2f s\n', g.topSpeed, g.topSpeedLimit, g.t0to10);
    fprintf('  Safe corner speed (eq. 6): R 10 m -> %.1f m/s,  R 40 m -> %.1f m/s\n', g.corner10, g.corner40);
    fprintf('  Estimated benchmark (assumes centreline + near-perfect driving):\n');
    for i = 1:numel(names)
        e = g.estimate.(names(i));
        note = "";  if e.capped, note = "  (energy-limited: must save energy)"; end
        if ~e.feasible, note = "  (NOT ENOUGH ENERGY even when slow)"; end
        fprintf('    %-10s %7.2f s   %5.1f Wh%s\n', names(i), e.time, e.energyWh, note);
    end
    fprintf('================================================\n\n');

    if p.Results.Plot, drawGarage(g, car, cat); end
    if nargout == 0, clear g; end
end

% ======================================================================= %
function t = timeTo(car, vT)
    s = struct('x', 0, 'y', 0, 'theta', 0, 'v', 0, 'delta', 0, 'energyJ', car.batteryJ);
    road = struct('alpha', 0, 'muFactor', 1);  t = 0;
    while s.v < vT && t < 30
        s = stepCar(car, s, 1, 0, road, 0.01);  t = t + 0.01;
    end
    if s.v < vT, t = Inf; end
end

function drawGarage(g, car, cat)
    fig = figure('Name', "AI Grand Prix - Garage - " + car.team, 'Color', [0.11 0.11 0.13], ...
        'NumberTitle', 'off', 'Position', [60 60 1250 720]);
    txt = @(ax, x, y, s, varargin) text(ax, x, y, s, 'Color', 'w', 'Interpreter', 'tex', varargin{:});

    % ---- car drawing ----
    ax = axes(fig, 'Position', [0.02 0.30 0.36 0.62], 'Color', [0.16 0.16 0.19], 'XColor', 'none', 'YColor', 'none');
    hold(ax, 'on');  axis(ax, 'equal');  xlim(ax, [-2.2 2.2]);  ylim(ax, [-1.6 1.6]);
    col = car.colour;
    tyreCol = struct('hard', [0.95 0.95 0.95], 'medium', [1 0.85 0.1], 'soft', [0.95 0.15 0.15]);
    tc = tyreCol.(car.parts.tyres);
    for tx = [0.95 -0.95]
        for ty = [0.62 -0.62]
            rectangle(ax, 'Position', [tx - 0.28, ty - 0.14, 0.56, 0.28], 'Curvature', 0.3, 'FaceColor', [0.08 0.08 0.08], 'EdgeColor', tc, 'LineWidth', 3);
        end
    end
    patch(ax, [1.7 1.2 0.6 -1.2 -1.4 -1.4 -1.2 0.6 1.2 1.7], [0 0.16 0.3 0.38 0.3 -0.3 -0.38 -0.3 -0.16 0], col, 'EdgeColor', 'k');
    fwD = 0.18;  rwD = 0.16;  rwW = 0.55;
    if car.parts.aero == "lowdrag", fwD = 0.2; rwD = 0.22; rwW = 0.6; end
    if car.parts.aero == "downforce", fwD = 0.3; rwD = 0.42; rwW = 0.75; end
    patch(ax, [1.45 1.45 + fwD 1.45 + fwD 1.45], [-0.8 -0.8 0.8 0.8], col * 0.8, 'EdgeColor', 'k');
    patch(ax, -1.45 - [0 rwD rwD 0], [-rwW -rwW rwW rwW], col * 0.75, 'EdgeColor', 'k');
    mW = 0.25 + 0.12 * find([cat.motor.id] == car.parts.motor);
    rectangle(ax, 'Position', [-1.05, -mW/2, mW, mW], 'FaceColor', [0.55 0.55 0.6], 'EdgeColor', 'k');
    txt(ax, -1.05 + mW/2, 0, 'M', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    bL = 0.3 + 0.2 * find([cat.battery.id] == car.parts.battery);
    rectangle(ax, 'Position', [-0.4, -0.16, bL, 0.32], 'FaceColor', [0.2 0.5 0.9], 'EdgeColor', 'k');
    txt(ax, -0.4 + bL/2, 0, 'B', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    title(ax, car.team, 'Color', 'w', 'FontSize', 15);
    txt(ax, -2.1, -1.45, sprintf('tyres: %s   aero: %s   gearing: %s', car.parts.tyres, car.parts.aero, car.parts.gearing), 'FontSize', 9);

    % ---- budget bar ----
    ab = axes(fig, 'Position', [0.04 0.18 0.32 0.05], 'Color', [0.16 0.16 0.19], 'XColor', 'none', 'YColor', 'none', ...
        'XLim', [0 max(cat.budget, g.cost) * 1.05], 'YLim', [0 1]);
    hold(ab, 'on');
    bc = [0.3 0.8 0.4];  if g.overBudget, bc = [0.95 0.25 0.2]; end
    patch(ab, [0 g.cost g.cost 0], [0 0 1 1], bc, 'EdgeColor', 'none');
    plot(ab, [cat.budget cat.budget], [0 1], 'w-', 'LineWidth', 2);
    title(ab, sprintf('budget: %d / %d credits%s', g.cost, cat.budget, string(ifelse(g.overBudget, '  - OVER BUDGET', ''))), ...
        'Color', bc, 'FontSize', 11);

    % ---- spec sheet with equations ----
    as = axes(fig, 'Position', [0.40 0.06 0.30 0.88], 'Color', [0.16 0.16 0.19], 'XColor', 'none', 'YColor', 'none', 'XLim', [0 1], 'YLim', [0 1]);
    hold(as, 'on');
    lines = {
        '\bfSPEC SHEET', ''
        sprintf('mass  %.0f kg', g.mass), 'm \cdot dv/dt = F_{drive} - F_{drag} - F_{roll} - F_{grade}  (1)'
        sprintf('power  %.1f kW  (%.0f W/kg)', car.power / 1000, g.powerToWeight), 'F_{drive} \leq min(P/v, F_{gear})  (2)'
        sprintf('gearing  v_{gear} %d m/s, F_{gear} %d N', car.vGear, car.Fgear), ''
        sprintf('aero  C_DA %.2f, C_LA %.1f', car.CdA, car.ClA), 'F_{drag} = 0.5\rhoC_DAv^2,  F_{down} = 0.5\rhoC_LAv^2  (3)'
        sprintf('tyres  \\mu %.2f, C_{rr} %.3f', car.mu, car.Crr), 'F_{roll} = C_{rr}N,   \surd(F_x^2+F_y^2) \leq \muN  (4, 5)'
        sprintf('battery  %d Wh', car.batteryWh), 'E \leftarrow E - F_{drive} v dt / \eta  (8)'
        '', ''
        sprintf('top speed  %.1f m/s  (%s)', g.topSpeed, g.topSpeedLimit), ''
        sprintf('0 - 10 m/s  %.2f s', g.t0to10), ''
        sprintf('corner R 10 m  %.1f m/s,  R 40 m  %.1f m/s', g.corner10, g.corner40), 'v^2 = \mugcos\alpha / (|\kappa| - \mu\rhoC_LA/2m)  (6)'
        '', ''
        '\bfESTIMATED BENCHMARK', '\itcentreline, near-perfect driving'
        };
    y = 0.96;
    for i = 1:size(lines, 1)
        txt(as, 0.03, y, lines{i, 1}, 'FontSize', 10);
        if ~isempty(lines{i, 2}), txt(as, 0.03, y - 0.03, lines{i, 2}, 'FontSize', 8, 'Color', [0.65 0.8 1]); end
        y = y - 0.058;
    end
    for nm = ["drag", "technical", "endurance", "mud"]
        e = g.estimate.(nm);
        extra = '';  if e.capped, extra = '  energy-limited'; end
        txt(as, 0.06, y, sprintf('%-10s %6.1f s   %5.1f Wh%s', nm, e.time, e.energyWh, extra), 'FontSize', 10, 'FontName', 'Consolas');
        y = y - 0.045;
    end

    % ---- strengths radar ----
    ar = axes(fig, 'Position', [0.72 0.06 0.26 0.88], 'Color', [0.16 0.16 0.19], 'XColor', 'none', 'YColor', 'none');
    hold(ar, 'on');  axis(ar, 'equal');  xlim(ar, [-1.5 1.5]);  ylim(ar, [-1.5 1.5]);
    [vals, labels] = strengths(g, car, cat);
    n = numel(vals);  th = pi/2 - (0:n-1) * 2*pi/n;
    for rr = [0.25 0.5 0.75 1]
        plot(ar, rr * cos([th th(1)]), rr * sin([th th(1)]), '-', 'Color', [0.35 0.35 0.4]);
    end
    for k = 1:n
        plot(ar, [0 cos(th(k))], [0 sin(th(k))], '-', 'Color', [0.35 0.35 0.4]);
        txt(ar, 1.22 * cos(th(k)), 1.22 * sin(th(k)), labels{k}, 'HorizontalAlignment', 'center', 'FontSize', 9);
    end
    patch(ar, vals .* cos(th), vals .* sin(th), car.colour, 'FaceAlpha', 0.45, 'EdgeColor', car.colour, 'LineWidth', 2);
    title(ar, 'strengths (vs every option in the catalogue)', 'Color', 'w', 'FontSize', 10);
    txt(ar, -1.5, -1.45, g.assumption, 'FontSize', 7, 'Color', [0.7 0.7 0.7]);
    drawnow;
    set(fig, 'UserData', g);
end

function [vals, labels] = strengths(g, car, cat)
% 0..1 on each axis, scaled between the weakest and strongest possible car.
    labels = {'acceleration', 'top speed', 'slow corners', 'fast corners', 'energy', 'light'};
    lo = struct();  hi = struct();
    acc = @(c) c.power / c.mass;
    mk = @(m, b, t, a, gr) buildCar(struct('motor', m, 'battery', b, 'tyres', t, 'aero', a, 'gearing', gr), ...
        setfield(cat, 'budget', Inf)); %#ok<SFLD>
    ids = @(p, k) cat.(p)(k).id;
    weak = mk(ids('motor', 1), ids('battery', 3), ids('tyres', 1), ids('aero', 3), ids('gearing', 1));
    strong = mk(ids('motor', 3), ids('battery', 1), ids('tyres', 3), ids('aero', 3), ids('gearing', 3));
    lo.acc = acc(weak);  hi.acc = acc(strong);
    v = [acc(car), g.topSpeed, g.corner10, g.corner40, car.batteryWh, -car.mass];
    lo = [lo.acc, cat.gearing(1).vGear * 0.8, cornerSpeed(weak, 1/10), cornerSpeed(mk(ids('motor', 1), ids('battery', 3), ...
          ids('tyres', 1), ids('aero', 1), ids('gearing', 1)), 1/40), cat.battery(1).energyWh, -125];
    hi = [hi.acc, cat.gearing(3).vGear, cornerSpeed(strong, 1/10), cornerSpeed(strong, 1/40), cat.battery(3).energyWh, -75];
    vals = max(0.05, min(1, (v - lo) ./ (hi - lo)));
end

function v = ifelse(c, a, b)
    if c, v = a; else, v = b; end
end
