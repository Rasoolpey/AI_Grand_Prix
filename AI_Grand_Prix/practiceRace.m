function results = practiceRace(varargin)
% PRACTICERACE  Race your car (carDesign.m + controller.m) on a practice path.
%
%   practiceRace                                % technical circuit, with animation
%   practiceRace('Path', 'drag')                % "drag" | "technical" | "endurance" | "wet"
%   practiceRace('Path', 'all')                 % the three core paths, headless, + overall score
%   r = practiceRace('Path', 'endurance', 'Headless', true);
%
%   Options:
%     'Path'      which practice path                       ("technical")
%     'Headless'  true = no animation, much faster          (false)
%     'Quiet'     true = print nothing                      (false)
%
%   results: finished, dnf, dnfReason, time, penalty, totalTime, nOffTrack,
%     nBarrier, stopInRunoff, lapTimes, energyUsedWh, batteryLeftFrac,
%     benchmark (estimated benchmark time, see below), score, log (for plotLap)
%   With 'Path','all': a struct array, one element per path, plus .overall.
%
%   Estimated benchmark time: what YOUR CAR could do on the centreline with
%   near-perfect driving (benchmarkTime).  It is an estimate, not a limit.
%   Controller efficiency = benchmark / your time.
%
%   Score per path (same rule as race day):  s = min(120, 100 * T_ref / T)
%   with T_ref the reference car's time; overall = 0.6 mean(s) + 0.4 min(s).
%
%   See also: plotLap, garage, carDesign, controller

    p = inputParser();
    p.addParameter('Path', "technical");
    p.addParameter('Headless', false);
    p.addParameter('Quiet', false);
    p.addParameter('DT', 0.02);
    p.parse(varargin{:});
    opt = p.Results;

    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'), fullfile(thisDir, 'simulator', 'physics'), ...
            fullfile(thisDir, 'student'), fullfile(thisDir, 'tracks'));

    car = buildCar(carDesign());
    config = struct();
    try
        config = robotConfig();
    catch ME
        warning('practiceRace:config', 'Could not load robotConfig: %s', ME.message);
    end

    if strcmpi(string(opt.Path), "all")
        names = ["drag", "technical", "endurance"];
        for i = numel(names):-1:1
            r(i) = runOne(names(i), true, true); %#ok<AGROW>
        end
        r = reshape(r, 1, []);
        sc = [r.score];
        overall = 0.6 * mean(sc) + 0.4 * min(sc);
        if ~opt.Quiet
            fprintf('\n  %-12s %9s %9s %9s %7s\n', 'Path', 'Time', 'Penalty', 'Bench', 'Score');
            for i = 1:numel(r)
                if r(i).dnf
                    fprintf('  %-12s %9s %9s %8.2fs %7.1f   DNF: %s\n', names(i), '-', '-', r(i).benchmark, 0, r(i).dnfReason);
                else
                    fprintf('  %-12s %8.2fs %8.0fs %8.2fs %7.1f\n', names(i), r(i).time, r(i).penalty, r(i).benchmark, r(i).score);
                end
            end
            fprintf('  Overall = 0.6 x mean + 0.4 x min = %.1f   (%d of %d paths finished)\n\n', ...
                overall, sum([r.finished]), numel(r));
        end
        [r.overall] = deal(overall);
        results = r;
    else
        results = runOne(string(opt.Path), logical(opt.Headless), logical(opt.Quiet));
    end
    if nargout == 0, clear results; end

    % ==================================================================== %
    function r = runOne(name, headless, quiet)
        course = loadPath(name);
        clear controller                              % fresh persistent variables every run
        r = RaceSimulation(course, car, @controller, config, struct('headless', headless, 'dt', opt.DT));
        b = benchmarkTime(car, course);
        r.benchmark = b.time;
        r.benchmarkEnergyWh = b.energyWh;
        tref = practiceReference(name);
        if r.finished && ~isnan(tref)
            r.score = min(120, 100 * tref / r.totalTime);
        else
            r.score = 0;
        end
        r.referenceTime = tref;
        if quiet, return; end
        fprintf('\n============================================================\n');
        fprintf('  AI GRAND PRIX - %s   |   %s\n', course.name, car.team);
        fprintf('------------------------------------------------------------\n');
        if r.dnf
            fprintf('  Result     : DNF - %s\n', r.dnfReason);
        else
            fprintf('  Result     : finished\n');
            fprintf('  Time       : %.2f s', r.time);
            if numel(r.lapTimes) > 1, fprintf('   (laps: %s)', strjoin(compose('%.2f', r.lapTimes), ', ')); end
            fprintf('\n  Penalties  : +%d s  (off-track %d x 5, barrier %d x 10', r.penalty, r.nOffTrack, r.nBarrier);
            if r.stopInRunoff, fprintf(', stopped past the box +3'); end
            fprintf(')\n  Total      : %.2f s\n', r.totalTime);
        end
        fprintf('  Energy     : %.1f Wh used, %.0f %% left\n', r.energyUsedWh, 100 * r.batteryLeftFrac);
        fprintf('  Benchmark  : %.2f s  (estimate for YOUR car on the centreline)', r.benchmark);
        if r.finished, fprintf('  -> efficiency %.0f %%', 100 * r.benchmark / r.totalTime); end
        if ~isnan(tref), fprintf('\n  Score      : %.1f  (reference %.2f s)', r.score, tref); end
        fprintf('\n============================================================\n\n');
    end
end
