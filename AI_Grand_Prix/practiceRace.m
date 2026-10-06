function results = practiceRace(varargin)
% PRACTICERACE  Race your car (carDesign.m + controller.m) on the practice paths.
%
%   practiceRace                                % technical circuit, with animation
%   practiceRace('Path', 'mud')                 % "drag" | "technical" | "endurance" | "mud" | "wet"
%   practiceRace('Path', 'all')                 % THE FOUR SCORED PATHS: a fast replay against your
%                                               % best run (the ghost), your overall score, and a
%                                               % new best model saved if you beat your best
%   r = practiceRace('Path', 'endurance', 'Headless', true);
%
%   Options:
%     'Path'      which practice path, or "all"                   ("technical")
%     'Headless'  true = no animation, much faster                (false)
%     'Quiet'     true = print nothing and no animation           (false)
%     'Seconds'   "all": length of the replay (s)                 (6)
%     'SaveBest'  "all": save a new best model when you beat it   (true)
%
%   YOUR BEST MODEL ("all" only)
%     Every "all" run is compared with your best.  If the OVERALL score is
%     higher, your car, driver and tuning are saved as your best model and
%     replace the old one.  If not, nothing is saved.  There is only ever one:
%       best_model/<team>.zip   the file you hand in (bestModel shows it)
%       best_model/best.mat     its four runs, shown as the grey ghost car
%     The same car under a new team name (or colour) replaces it too.
%
%   results: finished, dnf, dnfReason, time, penalty, totalTime, nOffTrack,
%     nBarrier, stopInRunoff, lapTimes, energyUsedWh, batteryLeftFrac,
%     benchmark (estimated benchmark time, see below), score, log (for plotLap)
%   With 'Path','all': a struct array, one element per path, plus .overall,
%     .bestBefore (your best overall before this run, NaN if none) and
%     .newBest (true if this run was saved as your new best).
%
%   Estimated benchmark time: what YOUR CAR could do on the centreline with
%   near-perfect driving (benchmarkTime).  It is an estimate, not a limit.
%   Controller efficiency = benchmark / your time.
%
%   Score per path (same rule as race day):  s = min(120, 100 * T_ref / T)
%   with T_ref the reference car's time; overall = 0.6 mean(s) + 0.4 min(s).
%
%   See also: bestModel, plotLap, garage, submitCar

    p = inputParser();
    p.addParameter('Path', "technical");
    p.addParameter('Headless', false);
    p.addParameter('Quiet', false);
    p.addParameter('Seconds', 6);
    p.addParameter('SaveBest', true);
    p.addParameter('DT', 0.02);
    p.addParameter('Frames', "");                   % instructor checks: save replay frames instead of animating
    p.parse(varargin{:});
    opt = p.Results;

    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'), fullfile(thisDir, 'simulator', 'physics'), ...
            fullfile(thisDir, 'student'), fullfile(thisDir, 'tracks'));

    design = carDesign();
    car = buildCar(design);
    config = struct();
    try
        config = robotConfig();
    catch ME
        warning('practiceRace:config', 'Could not load robotConfig: %s', ME.message);
    end
    best = bestModel('load');

    if strcmpi(string(opt.Path), "all")
        names = ["drag", "technical", "endurance", "mud"];
        for i = numel(names):-1:1
            r(i) = runOne(names(i), true, true); %#ok<AGROW>
        end
        r = reshape(r, 1, []);
        sc = [r.score];
        overall = 0.6 * mean(sc) + 0.4 * min(sc);
        bestBefore = NaN;  if ~isempty(best), bestBefore = best.overall; end

        show = ~opt.Quiet && ~opt.Headless && (opt.Frames ~= "" || ~batchStartupOptionUsed);
        if show, replay(r, names, best, car, opt); end

        [saved, why] = deal(false, "");
        if opt.SaveBest
            [saved, why] = saveIfBetter(r, names, overall, best, design, car, thisDir);
        end
        if ~opt.Quiet, printAll(r, names, overall, best, saved, why, car); end
        [r.overall] = deal(overall);
        [r.bestBefore] = deal(bestBefore);
        [r.newBest] = deal(saved);
        results = r;
    else
        results = runOne(string(opt.Path), logical(opt.Headless), logical(opt.Quiet));
    end
    if nargout == 0, clear results; end

    % ==================================================================== %
    function r = runOne(name, headless, quiet)
        course = loadPath(name);
        clear controller                              % fresh persistent variables every run
        simOpt = struct('headless', headless, 'dt', opt.DT);
        if ~headless, simOpt.ghost = ghostFor(best, name); end
        r = RaceSimulation(course, car, @controller, config, simOpt);
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
        g = ghostFor(best, name);
        if ~isempty(g) && g.finished, fprintf('\n  Your best  : %.2f s on this path (your best model, the grey ghost)', g.totalTime); end
        fprintf('\n============================================================\n\n');
    end
end

% ======================================================================= %
function g = ghostFor(best, name)
    g = [];
    if isempty(best), return; end
    k = find(best.paths == name, 1);
    if ~isempty(k), g = best.ghost(k); end
end

function printAll(r, names, overall, best, saved, why, car)
    hasBest = ~isempty(best);
    fprintf('\n  %-10s %9s %8s %9s %7s %8s\n', 'Path', 'Time', 'Penalty', 'Bench', 'Score', 'Best');
    for i = 1:numel(r)
        bs = '';
        if hasBest
            k = find(best.paths == names(i), 1);
            if ~isempty(k), bs = sprintf('%8.1f', best.scores(k)); end
        end
        if r(i).dnf
            fprintf('  %-10s %9s %8s %8.2fs %7.1f %8s   DNF: %s\n', names(i), '-', '-', r(i).benchmark, 0, bs, r(i).dnfReason);
        else
            fprintf('  %-10s %8.2fs %7.0fs %8.2fs %7.1f %8s\n', names(i), r(i).time, r(i).penalty, r(i).benchmark, r(i).score, bs);
        end
    end
    fprintf('  Overall = 0.6 x mean + 0.4 x min = %.1f   (%d of %d paths finished)\n', ...
        overall, sum([r.finished]), numel(r));
    if saved
        info = bestModel('load');
        if hasBest
            fprintf('  >>> %s (was %.1f). Saved as your best model: best_model/%s\n', why, best.overall, info.zipName);
        else
            fprintf('  >>> First best model saved: best_model/%s\n', info.zipName);
        end
        fprintf('      This is the file you hand in. Only your best is kept.\n');
        if car.team == "Team Name"
            fprintf('  [!!] Your model is called "Team Name": set car.team in carDesign.m, then run this again.\n');
        end
    elseif hasBest
        fprintf('  Your best is still %.1f (best_model/%s): nothing saved.\n', best.overall, best.zipName);
    elseif why ~= ""
        fprintf('  Not saved: %s\n', why);
    end
    fprintf('\n');
end

% ======================================================================= %
function [saved, why] = saveIfBetter(r, names, overall, best, design, car, thisDir)
% Save the current car + driver as the best model if its overall is higher.
    saved = false;  why = "";
    studentDir = fullfile(thisDir, 'student');
    files = dir(fullfile(studentDir, '*.m'));
    code = struct();
    for f = files'
        code.(matlab.lang.makeValidName(f.name)) = string(fileread(fullfile(f.folder, f.name)));
    end
    if overall <= 0
        why = "no path finished yet";  return;
    end
    if isempty(best)
        why = "First best model";
    elseif overall > best.overall + 1e-6
        why = "NEW BEST";
    elseif abs(overall - best.overall) <= 1e-6 && sameCar(best, car, code) && ...
            (best.team ~= car.team || any(abs(best.colour - car.colour) > 1e-9))
        why = "Same car, new name or colour";
    else
        return;
    end

    bestDir = fullfile(thisDir, 'best_model');
    if ~exist(bestDir, 'dir'), mkdir(bestDir); end
    zipName = string(regexprep(regexprep(char(car.team), '[^A-Za-z0-9-]+', '_'), '^_+|_+$', '')) + ".zip";
    if zipName == ".zip", zipName = "model.zip"; end
    stage = fullfile(tempdir, "aigp_best_" + string(feature('getpid')));
    if exist(stage, 'dir'), rmdir(stage, 's'); end
    mkdir(stage);
    for f = files', copyfile(fullfile(f.folder, f.name), stage); end
    B.team = car.team;  B.colour = car.colour;  B.parts = car.parts;  B.cost = car.cost;
    B.overall = overall;  B.paths = names;  B.scores = [r.score];  B.totalTimes = [r.totalTime];
    B.saved = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    B.zipName = zipName;  B.code = code;
    manifest = struct('team', car.team, 'colour', car.colour, ...
        'design', rmfield(design, intersect(fieldnames(design), {'colour'})), ...
        'cost', car.cost, 'overall', round(overall, 2), 'scores', struct(), 'saved', B.saved, 'matlab', string(version));
    for i = 1:numel(names), manifest.scores.(names(i)) = round(r(i).score, 2); end
    fid = fopen(fullfile(stage, 'manifest.json'), 'w');
    fprintf(fid, '%s', jsonencode(manifest, 'PrettyPrint', true));
    fclose(fid);
    old = dir(fullfile(bestDir, '*.zip'));
    for o = old', delete(fullfile(o.folder, o.name)); end      % only ever one model
    zip(fullfile(bestDir, zipName), '*', stage);
    rmdir(stage, 's');
    for i = numel(r):-1:1
        lg = r(i).log;
        G(i) = struct('t', single(lg.t), 'x', single(lg.x), 'y', single(lg.y), 'theta', single(lg.theta), ...
            'finished', r(i).finished, 'totalTime', r(i).totalTime);
    end
    B.ghost = G;
    save(fullfile(bestDir, 'best.mat'), 'B');
    saved = true;
end

function tf = sameCar(best, car, code)
% Same parts and the same code (apart from carDesign.m, where the name lives).
    tf = isequal(best.parts, car.parts);
    if ~tf, return; end
    f = setdiff(union(fieldnames(best.code), fieldnames(code)), {'carDesign_m'});
    for i = 1:numel(f)
        if ~isfield(best.code, f{i}) || ~isfield(code, f{i}) || best.code.(f{i}) ~= code.(f{i})
            tf = false;  return;
        end
    end
end

% ======================================================================= %
function replay(r, names, best, car, opt)
% Fast replay of the four runs, side by side, with the best run as a ghost.
    fig = figure('Name', "AI Grand Prix - all paths - " + car.team, 'Color', [0.08 0.08 0.1], ...
        'NumberTitle', 'off', 'Position', [30 40 1500 860], 'Visible', onOff(opt.Frames == ""));
    tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    n = numel(r);
    [cars, ghosts, lbl, ttl, gh, dots, gdots] = deal(cell(n, 1));
    dur = zeros(n, 1);
    for i = 1:n
        ax = nexttile(tl);
        Visualizer.drawCourse(ax, r(i).course);
        gh{i} = ghostFor(best, names(i));
        if ~isempty(gh{i}) && ~isempty(gh{i}.t)
            ghosts{i} = Visualizer.makeGhost(ax, best.parts.aero);
            gdots{i} = plot(ax, NaN, NaN, 'o', 'MarkerSize', 13, 'MarkerEdgeColor', [0.95 0.95 0.95], 'LineWidth', 2.5);
            lbl{i} = text(ax, NaN, NaN, ' best', 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
        end
        cars{i} = Visualizer.makeCar(ax, car.colour, car.parts.aero);
        dots{i} = plot(ax, NaN, NaN, 'o', 'MarkerSize', 12, 'MarkerFaceColor', car.colour, ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        ttl{i} = title(ax, r(i).course.name, 'Color', 'w', 'FontSize', 13, 'Interpreter', 'none');
        dur(i) = max([r(i).log.t(:); 0]);
        if ~isempty(ghosts{i}), dur(i) = max(dur(i), double(gh{i}.t(end))); end
    end
    sub = "grey car = your best model";  if isempty(best), sub = "no best model yet: this run can become it"; end
    title(tl, sprintf('%s  -  all four paths, sped up  (%s)', car.team, sub), ...
        'Color', [1 0.85 0.3], 'FontSize', 14, 'Interpreter', 'none');

    if opt.Frames ~= ""
        if ~exist(opt.Frames, 'dir'), mkdir(opt.Frames); end
        for frac = [0.5 1]
            drawAt(frac * opt.Seconds);
            exportgraphics(fig, fullfile(opt.Frames, sprintf('all_%03.0f.png', 100 * frac)), 'Resolution', 70);
        end
        close(fig);
        return;
    end
    t0 = tic;
    while isvalid(fig)
        w = toc(t0);
        drawAt(min(w, opt.Seconds));
        drawnow;
        if w >= opt.Seconds, break; end
    end

    function drawAt(w)
        for j = 1:n
            t = w / opt.Seconds * dur(j);
            lg = r(j).log;
            if ~isempty(lg.t)
                m = min(numel(lg.t), max(1, round(t / 0.02)));
                Visualizer.placeCar(cars{j}, lg.x(m), lg.y(m), lg.theta(m));
                set(dots{j}, 'XData', lg.x(m), 'YData', lg.y(m));
            end
            gs = "";
            if ~isempty(ghosts{j})
                g = gh{j};
                k = min(numel(g.t), max(1, round(t / 0.02)));
                gx = double(g.x(k));  gy = double(g.y(k));
                Visualizer.placeCar(ghosts{j}, gx, gy, double(g.theta(k)));
                set(gdots{j}, 'XData', gx, 'YData', gy);
                set(lbl{j}, 'Position', [gx + 3, gy + 3, 0]);
                if g.finished, gs = sprintf('   |   best %.2f s', g.totalTime); else, gs = "   |   best: DNF"; end
            end
            if r(j).dnf
                ys = "DNF";
            elseif t >= r(j).time
                ys = sprintf('%.2f s', r(j).totalTime);
            else
                ys = sprintf('%.1f s', t);
            end
            set(ttl{j}, 'String', sprintf('%s   |   you %s%s', r(j).course.name, ys, gs));
        end
    end
end

function s = onOff(tf)
    if tf, s = 'on'; else, s = 'off'; end
end
