function course = buildPath(pieces, varargin)
% BUILDPATH  Turn a list of road pieces into a RacePath the simulator can race on.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   course = buildPath(pieces, Name, Value, ...)
%
%   pieces   row vector of road.straight / road.corner / road.chicane /
%            road.surface pieces, in driving order
%
%   Options:
%     'Name'          display name                          ("Path")
%     'Type'          "circuit" (closed loop) or "open"     ("circuit")
%     'Laps'          laps to complete (circuit)            (1)
%     'Width'         road width (m)                        (5)
%     'Runoff'        run-off between road edge and barrier (m)  (3)
%     'StopBox'       open path: stop box length after the finish (m) (0)
%     'FinishRunoff'  open path: run-off after the stop box (m)       (0)
%     'TimeLimit'     DNF after this many seconds           (120)
%     'Checkpoints'   checkpoint spacing (m)                (25)
%     'Transition'    clothoid length at curvature changes (m)  (5)
%     'GradeTransition' length of grade changes (crest/dip) (m) (10)
%     'Start'         [x y headingDeg] of the start         ([0 0 0])
%
%   A circuit must turn through exactly +-360 degrees in total.  Its end is
%   joined to its start by changing the lengths of the straights marked
%   "adjust" (or of all straights if none is marked), and its elevation is
%   corrected so it ends at its start height (no free climbing per lap).
%
%   Open path layout: [ racing section | finish line | stop box | run-off | barrier ].
%   The racing section is everything before the last StopBox + FinishRunoff metres.
%
%   Checks (an error if broken): total turn of a circuit, closure, and that
%   the road (plus run-off) never runs into itself.
%
%   See also: RacePath, road.straight, road.corner, road.chicane, road.surface

    o = inputParser();
    o.addParameter('Name', "Path");
    o.addParameter('Type', "circuit");
    o.addParameter('Laps', 1);
    o.addParameter('Width', 5);
    o.addParameter('Runoff', 3);
    o.addParameter('StopBox', 0);
    o.addParameter('FinishRunoff', 0);
    o.addParameter('TimeLimit', 120);
    o.addParameter('Checkpoints', 25);
    o.addParameter('Transition', 5);
    o.addParameter('GradeTransition', 10);
    o.addParameter('Start', [0 0 0]);
    o.parse(varargin{:});
    opt = o.Results;
    isCircuit = strcmpi(string(opt.Type), "circuit");

    isMarker = [pieces.kind] == "surface";
    geo      = pieces(~isMarker);
    if isempty(geo), error('buildPath:empty', 'No road pieces.'); end

    % ---- Close the circuit by adjusting straight lengths -------------- %
    if isCircuit
        totalTurn = sum([geo.kappa] .* [geo.length]);
        if abs(abs(totalTurn) - 2*pi) > 1e-6
            error('buildPath:turn', 'A circuit must turn +-360 deg in total; this one turns %.3f deg.', rad2deg(totalTurn));
        end
        adj = find([geo.adjust]);
        if isempty(adj), adj = find([geo.kind] == "straight"); end
        if numel(adj) < 2, error('buildPath:close', 'Need at least 2 straights to close the circuit.'); end
        for it = 1:8
            g = integrate(pieces, opt, isCircuit);
            e = [g.x(end) - g.x(1), g.y(end) - g.y(1)];
            if norm(e) < 1e-6, break; end
            % straight directions (a straight keeps its heading; take it at its midpoint)
            A = zeros(2, numel(adj));
            for k = 1:numel(adj)
                th = interp1(g.s, g.theta, g.pieceStart(adj(k)) + geo(adj(k)).length/2);
                A(:, k) = [cos(th); sin(th)];
            end
            W  = diag([geo(adj).length]);
            dL = W * A' * ((A * W * A') \ (-e(:)));
            newL = [geo(adj).length] + dL';
            if any(newL < 1)
                error('buildPath:close', 'Cannot close the circuit: a straight would need length %.1f m. Check the layout.', min(newL));
            end
            for k = 1:numel(adj), geo(adj(k)).length = newL(k); end
            pieces(~isMarker) = geo;
        end
        if norm(e) > 1e-3
            error('buildPath:close', 'Circuit does not close (gap %.3f m).', norm(e));
        end
    end
    g = integrate(pieces, opt, isCircuit);

    z = g.z;

    % ---- Resample to ~0.5 m spacing ------------------------------------ %
    every = 5;                                    % fine grid is ~0.1 m
    if isCircuit
        idx = 1:every:numel(g.s) - 1;             % drop the duplicated end point
    else
        idx = 1:every:numel(g.s);
        if idx(end) ~= numel(g.s), idx(end+1) = numel(g.s); end
    end
    d.name      = string(opt.Name);
    d.type      = string(lower(opt.Type));
    d.laps      = opt.Laps;
    d.width     = opt.Width;
    d.runoff    = opt.Runoff;
    d.timeLimit = opt.TimeLimit;
    d.s         = g.s(idx);
    d.centreline = [g.x(idx), g.y(idx)];
    d.heading   = g.theta(idx);
    d.kappa     = g.kappa(idx);
    d.grade     = g.grade(idx);
    d.z         = z(idx);
    d.muFactor  = g.mu(idx);
    d.length    = g.s(end);                       % lap length (circuit) or total length (open)

    % ---- Finish, stop box, checkpoints --------------------------------- %
    if isCircuit
        d.finishS = 0;
        d.stopBox = [NaN NaN];
        cpS = opt.Checkpoints : opt.Checkpoints : d.length - opt.Checkpoints/2;
    else
        d.finishS = d.length - opt.StopBox - opt.FinishRunoff;
        if d.finishS <= 0, error('buildPath:open', 'StopBox + FinishRunoff is longer than the path.'); end
        if opt.StopBox > 0
            d.stopBox = [d.finishS, d.finishS + opt.StopBox];
        else
            d.stopBox = [NaN NaN];
        end
        cpS = opt.Checkpoints : opt.Checkpoints : d.finishS - opt.Checkpoints/2;
    end
    d.checkpointS = cpS(:);

    checkGeometry(d, isCircuit);
    course = RacePath(d);
end

% ======================================================================= %
function g = integrate(pieces, opt, isCircuit)
% Exact centreline from piecewise-constant curvature and grade.
% A clothoid transition of length l is the moving average of the curvature
% over l, so the smoothed heading is a moving average of the raw heading
% T(s) = int kappa.  Both are evaluated from closed-form piecewise integrals,
% which keeps every quantity a smooth function of the piece lengths.
    isMarker = [pieces.kind] == "surface";
    geo   = pieces(~isMarker);
    L     = [geo.length];
    total = sum(L);
    edges = [0, cumsum(L)];

    gradeV = [geo.grade] / 100;
    if isCircuit
        dz = sum(gradeV .* L);
        if abs(dz) > 2
            error('buildPath:height', 'Circuit ends %.2f m above its start: balance the climbs and descents.', dz);
        end
        gradeV = gradeV - dz / total;             % tiny uniform correction: close the height exactly
    end

    n = 5 * max(round(total / 0.5), 2);           % fine grid ~0.1 m; resampled every 5th point
    s = (0:n)' * (total / n);

    lt = opt.Transition;  lg = opt.GradeTransition;
    kappa = smoothVal(s, edges, [geo.kappa], isCircuit, lt);
    theta = deg2rad(opt.Start(3)) + smoothInt(s, edges, [geo.kappa], isCircuit, lt) ...
            - smoothInt(0, edges, [geo.kappa], isCircuit, lt);
    grade = 100 * smoothVal(s, edges, gradeV, isCircuit, lg);
    z     = smoothInt(s, edges, gradeV, isCircuit, lg) - smoothInt(0, edges, gradeV, isCircuit, lg);

    x = opt.Start(1) + cumtrapz(s, cos(theta));
    y = opt.Start(2) + cumtrapz(s, sin(theta));

    % surface markers: placed at the start of the next geometric piece
    mu = ones(n + 1, 1);
    geoBefore = cumsum(~isMarker);
    for i = find(isMarker)
        s0 = edges(min(geoBefore(i) + 1, numel(edges)));
        on = s >= s0 & s < s0 + pieces(i).length;
        mu(on) = min(mu(on), pieces(i).muFactor);
    end

    g = struct('s', s, 'x', x, 'y', y, 'theta', theta, 'kappa', kappa, 'grade', grade, ...
               'z', z, 'mu', mu, 'pieceStart', edges(1:end-1));
end

function v = smoothVal(s, edges, vals, isCircuit, l)
% Moving average of the piecewise-constant function over a window l.
    if l <= 0
        F1 = pwInt(s + 1e-9, edges, vals, isCircuit);  F0 = pwInt(s - 1e-9, edges, vals, isCircuit);
        v = (F1 - F0) / 2e-9;  return;
    end
    v = (pwInt(s + l/2, edges, vals, isCircuit) - pwInt(s - l/2, edges, vals, isCircuit)) / l;
end

function v = smoothInt(s, edges, vals, isCircuit, l)
% Moving average of F = int f over a window l (the integral of smoothVal).
    if l <= 0
        v = pwInt(s, edges, vals, isCircuit);  return;
    end
    [~, G1] = pwInt(s + l/2, edges, vals, isCircuit);
    [~, G0] = pwInt(s - l/2, edges, vals, isCircuit);
    v = (G1 - G0) / l;
end

function [F, G] = pwInt(s, edges, vals, isCircuit)
% F(s) = int_0^s f,  G(s) = int_0^s F, for f piecewise constant (vals on
% [edges(k), edges(k+1))).  Outside [0, P]: periodic for a circuit
% (F(s+P) = F(s) + F(P)); f = 0 beyond the ends of an open path.
    P  = edges(end);  L = diff(edges);
    Fe = [0, cumsum(vals .* L)];
    Ge = [0, cumsum(Fe(1:end-1) .* L + 0.5 * vals .* L.^2)];
    FP = Fe(end);  GP = Ge(end);
    F = zeros(size(s));  G = zeros(size(s));
    in = s >= 0 & s <= P;
    [F(in), G(in)] = inside(s(in));
    if isCircuit
        hi = s > P;   [f, g] = inside(s(hi) - P);
        F(hi) = f + FP;  G(hi) = GP + g + FP * (s(hi) - P);
        lo = s < 0;   a = -s(lo);  [f, g] = inside(P - a);
        F(lo) = f - FP;  G(lo) = -(GP - g) + FP * a;
    else
        hi = s > P;                               % beyond the end: f = 0
        F(hi) = FP;  G(hi) = GP + FP * (s(hi) - P);
    end                                           % before the start: 0
    function [f, g] = inside(x)
        k = discretize(x, edges);
        k(isnan(k)) = numel(vals);                % x == P exactly
        d = x - edges(k)';
        d = reshape(d, size(x));  k = reshape(k, size(x));
        f = reshape(Fe(k), size(x)) + reshape(vals(k), size(x)) .* d;
        g = reshape(Ge(k), size(x)) + reshape(Fe(k), size(x)) .* d + 0.5 * reshape(vals(k), size(x)) .* d.^2;
    end
end

function checkGeometry(d, isCircuit)
% The road plus run-off must not run into itself.
    P = d.centreline;  s = d.s;  n = size(P, 1);
    clearance = d.width + 2 * d.runoff;           % barrier to barrier
    minArc = clearance * pi / 2;                  % closer than this along the road is just "the same bend"
    for i = 1:n
        dd = hypot(P(:,1) - P(i,1), P(:,2) - P(i,2));
        arc = abs(s - s(i));
        if isCircuit, arc = min(arc, d.length - arc); end
        bad = find(dd < clearance & arc > minArc, 1);
        if ~isempty(bad)
            error('buildPath:overlap', ...
                'The road runs into itself near s = %.0f m and s = %.0f m (%.1f m apart, need %.1f m).', ...
                s(i), s(bad), dd(bad), clearance);
        end
    end
end
