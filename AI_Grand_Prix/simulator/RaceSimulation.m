function results = RaceSimulation(course, car, controllerFn, config, options)
% RACESIMULATION  Drive one car round one path with a controller.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   results = RaceSimulation(course, car, controllerFn, config, options)
%
%   course        RacePath (from loadPath / buildPath)
%   car           struct from buildCar(carDesign())
%   controllerFn  @(obs, config) -> command with .throttle and .steering in [-1, 1]
%   config        passed to the controller every step
%   options       .headless (default true), .dt (default 0.02)
%
%   Rules (identical for every car):
%     Circuit: pass every checkpoint in order, then cross the finish line
%       forwards; repeat for every lap.  Your time = when you cross the line
%       at the end of the last lap.
%     Open path (drag strip): cross the finish line, then come to rest.
%       Your time = when you cross the line.
%     Penalties (still a finish): +5 s per off-track incident (leaving the
%       road), +10 s per barrier contact, +3 s for stopping past the stop box.
%     DNF: a checkpoint missed (shortcut), stopped for more than 3 s before
%       finishing, hit the barrier at the end of the strip, the controller
%       errors or returns an invalid command, or the time limit runs out.
%     An empty battery gives no drive: the car coasts, and still finishes if
%       it rolls over the line.
%
%   results: finished, dnf, dnfReason, time, penalty, totalTime (time +
%     penalty, Inf if DNF), nOffTrack, nBarrier, stopInRunoff, lapTimes,
%     energyUsedWh, batteryLeftFrac, checkpointsPassed, log, course, car, dt
%
%   See also: practiceRace, stepCar, RacePath, plotLap

    if nargin < 4 || isempty(config),  config  = struct(); end
    if nargin < 5 || isempty(options), options = struct(); end
    dt       = getOpt(options, 'dt', 0.02);
    headless = getOpt(options, 'headless', true);

    isCircuit = course.isCircuit();
    K       = numel(course.checkpointS);
    cpLines = zeros(K, 4);
    for k = 1:K, cpLines(k,:) = course.checkpointLine(k); end
    cpTang  = [cos(course.heading(course.checkpointIdx)), sin(course.heading(course.checkpointIdx))];
    finLine = course.finishLine();
    finTang = [cos(course.heading(course.finishIdx)), sin(course.heading(course.finishIdx))];
    halfW   = course.width / 2;
    wallAt  = halfW + course.runoff;
    nLaps   = course.laps;
    if ~isCircuit, nLaps = 1; end

    % ---- State --------------------------------------------------------- %
    s = struct('x', course.centreline(1,1), 'y', course.centreline(1,2), ...
               'theta', course.heading(1), 'v', 0, 'delta', 0, 'energyJ', car.batteryJ);
    idx = 1;  sProj = 0;
    lap = 1;  nextCp = 1;  cpPassed = 0;
    nOff = 0;  nBarrier = 0;  wasOff = false;  inContact = false;
    stopped = 0;  lapStart = 0;  lapTimes = [];
    finished = false;  crossedFinish = false;  finishTime = Inf;  stopInRunoff = false;
    dnf = false;  reason = "";

    maxSteps = ceil(course.timeLimit / dt);
    lg = preallocLog(maxSteps);

    if ~headless
        viz = Visualizer(course, car);
    end

    step = 0;
    while step < maxSteps
        step = step + 1;
        t = (step - 1) * dt;

        % ---- Observation ------------------------------------------------ %
        obs.position      = [s.x, s.y];
        obs.heading       = s.theta;
        obs.speed         = s.v;
        obs.steeringAngle = s.delta;
        obs.time          = t;
        obs.dt            = dt;
        obs.trackWidth    = course.width;
        obs.previewPoints = course.preview(idx, 60);
        obs.batteryWh     = s.energyJ / 3600;
        obs.batteryFrac   = s.energyJ / car.batteryJ;
        obs.car           = car;
        obs.path          = pathObs();

        % ---- Controller (any error or bad command = DNF) ---------------- %
        try
            command = controllerFn(obs, config);
            [throttle, steer] = checkCommand(command);
        catch ME
            dnf = true;
            reason = sprintf("Controller error at t = %.2f s: %s", t, ME.message);
            step = step - 1;
            break;
        end

        % ---- Physics ---------------------------------------------------- %
        p1 = [s.x, s.y];
        [s, info] = stepCar(car, s, throttle, steer, course.roadAt(idx), dt);
        [idx, crossErr, sProj] = course.locate(s.x, s.y, idx);

        % Barrier: the car stops at the wall (+10 s per contact)
        if abs(crossErr) > wallAt
            if ~inContact, nBarrier = nBarrier + 1; end
            inContact = true;
            push = sign(crossErr) * (abs(crossErr) - wallAt + 0.05);
            s.x = s.x - push * course.normals(idx,1);
            s.y = s.y - push * course.normals(idx,2);
            s.v = 0;
            crossErr = crossErr - push;
        else
            inContact = false;
        end
        if ~isCircuit && sProj >= course.length - 0.05
            dnf = true;  reason = "Hit the barrier at the end of the strip";
        end

        % Off-track incidents (counted when the car leaves the road)
        off = abs(crossErr) > halfW;
        if off && ~wasOff, nOff = nOff + 1; end
        wasOff = off;

        % ---- Checkpoints and finish line -------------------------------- %
        p2 = [s.x, s.y];
        mv = p2 - p1;
        if ~dnf && ~crossedFinish && any(mv)
            hits = RacePath.crosses(p1, p2, cpLines) & (cpTang * mv') > 0;
            if any(hits)
                hk = find(hits);
                for k = hk(:)'
                    if k == nextCp
                        nextCp = nextCp + 1;  cpPassed = cpPassed + 1;
                    elseif k > nextCp
                        dnf = true;  reason = sprintf("Missed checkpoint %d (lap %d): shortcut", nextCp, lap);
                    end
                end
            end
            [hitF, frac] = RacePath.crosses(p1, p2, finLine);
            if ~dnf && hitF && dot(finTang, mv) > 0
                if nextCp <= K
                    dnf = true;  reason = sprintf("Crossed the finish line with checkpoint %d (lap %d) missed", nextCp, lap);
                else
                    tc = t + frac * dt;
                    if isCircuit
                        lapTimes(end+1) = tc - lapStart;  %#ok<AGROW>
                        lapStart = tc;
                        if lap >= nLaps
                            finished = true;  finishTime = tc;
                        else
                            lap = lap + 1;  nextCp = 1;
                        end
                    else
                        crossedFinish = true;  finishTime = tc;  lapTimes = tc;
                        finished = isnan(course.stopBox(2));     % no stop box: done at the line
                    end
                end
            end
        end
        if ~isCircuit && crossedFinish && ~finished && ~dnf && s.v < 0.05
            finished = true;
            stopInRunoff = ~isnan(course.stopBox(2)) && sProj > course.stopBox(2);
        end

        % Stopped too long before finishing
        if s.v < 0.05, stopped = stopped + dt; else, stopped = 0; end
        if ~finished && ~dnf && ~crossedFinish && stopped > 3
            dnf = true;  reason = sprintf("Stopped for more than 3 s at t = %.1f s", t);
        end

        % ---- Log -------------------------------------------------------- %
        lg.t(step) = t + dt;          lg.x(step) = s.x;           lg.y(step) = s.y;
        lg.z(step) = course.z(idx);   lg.theta(step) = s.theta;   lg.v(step) = s.v;
        lg.throttle(step) = throttle; lg.steering(step) = steer;  lg.steeringAngle(step) = s.delta;
        lg.Fx(step) = info.Fx;        lg.Fy(step) = info.Fy;      lg.G(step) = info.G;
        lg.gripUse(step) = info.gripUse;  lg.understeer(step) = info.understeer;
        lg.energyJ(step) = s.energyJ; lg.grade(step) = course.grade(idx);
        lg.muFactor(step) = course.muFactor(idx);
        lg.crossTrackErr(step) = crossErr;  lg.offTrack(step) = off;
        lg.idx(step) = idx;           lg.progress(step) = progress();
        lg.lap(step) = lap;           lg.checkpoint(step) = nextCp;
        lg.curvature(step) = course.kappa(idx);

        if ~headless
            viz.update(s, info, struct('t', t + dt, 'lap', lap, 'laps', nLaps, 'nextCp', nextCp, ...
                'K', K, 'nOff', nOff, 'nBarrier', nBarrier, 'batteryFrac', s.energyJ / car.batteryJ, ...
                'grade', course.grade(idx), 'throttle', throttle, 'idx', idx));
            drawnow limitrate;
        end

        if finished || dnf, break; end
    end

    if ~finished && ~dnf
        dnf = true;  reason = sprintf("Time limit (%.0f s) exceeded", course.timeLimit);
    end
    if dnf, finished = false; end

    % ---- Results -------------------------------------------------------- %
    penalty = 5 * nOff + 10 * nBarrier + 3 * stopInRunoff;
    f = fieldnames(lg);
    for i = 1:numel(f), lg.(f{i}) = lg.(f{i})(1:step); end

    results.finished        = finished;
    results.dnf             = dnf;
    results.dnfReason       = reason;
    results.time            = finishTime;
    results.penalty         = penalty;
    results.totalTime       = finishTime + penalty;
    if dnf, results.time = Inf; results.totalTime = Inf; end
    results.nOffTrack       = nOff;
    results.nBarrier        = nBarrier;
    results.stopInRunoff    = stopInRunoff;
    results.lapTimes        = lapTimes;
    results.energyUsedWh    = (car.batteryJ - s.energyJ) / 3600;
    results.batteryLeftFrac = s.energyJ / car.batteryJ;
    results.checkpointsPassed = cpPassed;
    results.pathName        = course.name;
    results.log             = lg;
    results.course          = course;
    results.car             = car;
    results.dt              = dt;

    % ==================================================================== %
    function p = pathObs()
        p.type              = course.type;
        p.laps              = nLaps;
        p.lap               = lap;
        p.lapsLeft          = nLaps - lap + 1;
        p.nextCheckpoint    = nextCp;
        p.checkpointsPerLap = K;
        if isCircuit
            sm = sProj;
            if nextCp == 1 && sm > course.length / 2, sm = sm - course.length; end
            p.distanceToFinish = (nLaps - lap) * course.length + course.length - sm;
            p.distanceToStop   = NaN;
        else
            p.distanceToFinish = course.finishS - sProj;
            p.distanceToStop   = course.stopBox(2) - sProj;
        end
    end

    function d = progress()
        if isCircuit
            sm = sProj;
            if nextCp == 1 && sm > course.length / 2, sm = sm - course.length; end
            if nextCp > K && sm < course.length / 2, sm = sm + course.length; end   % just over the line
            d = (lap - 1) * course.length + sm;
        else
            d = sProj;
        end
    end
end

% ======================================================================= %
function [throttle, steer] = checkCommand(c)
    if ~isstruct(c) || ~isfield(c, 'throttle') || ~isfield(c, 'steering')
        error('AIGP:command', 'controller must return a struct with fields throttle and steering');
    end
    throttle = c.throttle;  steer = c.steering;
    if ~isnumeric(throttle) || ~isscalar(throttle) || ~isreal(throttle) || ~isfinite(throttle) || ...
       ~isnumeric(steer)    || ~isscalar(steer)    || ~isreal(steer)    || ~isfinite(steer)
        error('AIGP:command', 'throttle and steering must be finite real numbers');
    end
    throttle = max(-1, min(1, double(throttle)));
    steer    = max(-1, min(1, double(steer)));
end

function lg = preallocLog(n)
    z = zeros(n, 1);
    lg = struct('t', z, 'x', z, 'y', z, 'z', z, 'theta', z, 'v', z, 'throttle', z, ...
        'steering', z, 'steeringAngle', z, 'Fx', z, 'Fy', z, 'G', z, 'gripUse', z, ...
        'understeer', false(n, 1), 'energyJ', z, 'grade', z, 'muFactor', z, ...
        'crossTrackErr', z, 'offTrack', false(n, 1), 'idx', z, 'progress', z, ...
        'lap', z, 'checkpoint', z, 'curvature', z);
end

function v = getOpt(s, f, d)
    if isfield(s, f), v = s.(f); else, v = d; end
end
