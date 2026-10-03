function b = benchmarkTime(car, course, varargin)
% BENCHMARKTIME  Estimated benchmark time and energy for a car on a path.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   b = benchmarkTime(car, course)
%   b = benchmarkTime(car, course, 'EnergyLimited', false)
%
%   A quasi-steady speed profile along the PRESCRIBED CENTRELINE, built from
%   the same physics functions as the simulator (eqs. 1-9):
%     1. corner limit at every point from eq. 6 (grade, downforce, wet), and v_gear
%     2. forward pass: accelerate as hard as power, gearing and the combined
%        grip budget allow, from a standing start
%     3. backward pass: brake as late as the combined grip allows (on a drag
%        strip: be stopped at the end of the stop box)
%     4. profile = the lower of the two; laps run continuously
%     5. if that needs more energy than the battery holds, the fastest
%        profile under a speed cap that fits the battery (cap by bisection)
%
%   ASSUMPTIONS (state them wherever the number is shown): fixed centreline
%   (no racing line), steering-rate limit ignored, a simple speed-cap energy
%   strategy.  It is an ESTIMATE, not the true minimum time.  A controller
%   that beats it is a reason to look closer (racing line, model or bug).
%
%   b fields: time (s, at the finish line), energyWh, feasible, capped,
%     vCap (m/s, Inf if none), s, v, vLimit, t (profile along the race
%     distance), lapTimes, assumptions (text)
%
%   See also: cornerSpeed, gripLimit, driveForce, roadForces, garage

    o = inputParser();
    o.addParameter('EnergyLimited', true);
    o.addParameter('BatteryMargin', 0.99);
    o.parse(varargin{:});
    opt = o.Results;

    % ---- Race distance as one long list of points ---------------------- %
    N  = course.numPoints();
    ds = course.ds;
    if course.isCircuit()
        ii = repmat((1:N)', course.laps, 1);
        ii(end+1) = 1;                                 % back on the line
        finishK = numel(ii);
        stopAtEnd = false;
    else
        if isnan(course.stopBox(2))
            lastS = course.finishS;
        else
            lastS = course.stopBox(2);
        end
        ii = (1:course.indexAt(lastS))';
        finishK = course.indexAt(course.finishS);
        stopAtEnd = ~isnan(course.stopBox(2));
    end
    kap   = course.kappa(ii);
    alpha = atan(course.grade(ii) / 100);
    mu    = course.muFactor(ii);
    vLim0 = min(cornerSpeed(car, kap, alpha, mu), car.vGear);

    p = profile(vLim0);
    b.capped = false;  b.vCap = Inf;  b.feasible = true;
    if opt.EnergyLimited && p.E > opt.BatteryMargin * car.batteryJ
        lo = 2;  hi = max(p.v);
        pLo = profile(min(vLim0, lo));
        if pLo.E > opt.BatteryMargin * car.batteryJ
            b.feasible = false;  p = pLo;
        else
            for it = 1:30
                mid = (lo + hi) / 2;
                pm = profile(min(vLim0, mid));
                if pm.E > opt.BatteryMargin * car.batteryJ, hi = mid; else, lo = mid; pLo = pm; end
                if hi - lo < 0.01, break; end
            end
            p = pLo;  b.capped = true;  b.vCap = lo;
        end
    end

    b.time     = p.t(finishK);
    b.energyWh = p.E / 3600;
    b.s        = (0:numel(ii) - 1)' * ds;
    b.v        = p.v;
    b.vLimit   = vLim0;
    b.t        = p.t;
    if course.isCircuit()
        b.lapTimes = diff(p.t([1, N * (1:course.laps) + 1]))';
    else
        b.lapTimes = b.time;
    end
    b.assumptions = "Estimate: car follows the centreline, steering-rate limit ignored, simple speed-cap energy strategy.";

    % ==================================================================== %
    function p = profile(vLim)
        n = numel(vLim);
        m = car.mass;
        % forward pass: accelerate
        vf = zeros(n, 1);  vf(1) = 0;
        for k = 1:n-1
            v = vf(k);
            G  = gripLimit(car, v, alpha(k), mu(k));
            Fy = m * v^2 * abs(kap(k));
            Fd = min(driveForce(car, v, 1), sqrt(max(G^2 - Fy^2, 0)));
            [Fdrag, Froll, Fgrade] = roadForces(car, v, alpha(k));
            a  = (Fd - Fdrag - Froll - Fgrade) / m;
            vf(k+1) = min(sqrt(max(v^2 + 2 * a * ds, 0.01)), vLim(k+1));
        end
        % backward pass: brake
        vb = vf;
        if stopAtEnd, vb(n) = 0; end
        for k = n-1:-1:1
            v = vb(k+1);
            G  = gripLimit(car, v, alpha(k+1), mu(k+1));
            Fy = m * v^2 * abs(kap(k+1));
            Fb = sqrt(max(G^2 - Fy^2, 0));
            [Fdrag, Froll, Fgrade] = roadForces(car, v, alpha(k+1));
            dec = (Fb + Fdrag + Froll + Fgrade) / m;
            vb(k) = min(sqrt(max(v^2 + 2 * dec * ds, 0)), vf(k));
        end
        vv = vb;
        % time and energy
        vm = 0.5 * (vv(1:end-1) + vv(2:end));
        dtk = ds ./ max(vm, 1e-3);
        p.t = [0; cumsum(dtk)];
        acc = (vv(2:end).^2 - vv(1:end-1).^2) / (2 * ds);
        [Fdrag, Froll, Fgrade] = roadForces(car, vm, alpha(1:end-1));
        Fdrive = max(0, m * acc + Fdrag + Froll + Fgrade);
        p.E = sum(Fdrive * ds) / car.eta;
        p.v = vv;
    end
end
