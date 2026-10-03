function out = trackTuning(cat, paths)
% TRACKTUNING  Measure what each part does on each path (TODO_RACE §4b steps 4-5).
%
%   trackTuning()                                % current catalogue, core paths
%   out = trackTuning(cat, paths)                % candidate catalogue / paths
%
%   Prints:
%   1. The MEASURED SENSITIVITY MATRIX: change one part at a time from several
%      base cars (cheap, balanced, power-, grip-, aero-heavy), keep the rest.
%      Cell = which option is best on that path (in how many base cars) and
%      how many score points separate the best and worst option (mean).
%      Compare it with the target matrix in TODO_RACE §4b step 1.
%   2. Balance evidence from all affordable designs (benchmark times):
%      designs within 5 % of the best, best design per path, the cheapest
%      design, and whether endurance needs energy management with the
%      smallest battery.
%
%   Uses benchmark times (no controller); confirm with balanceSweep.
%
%   See also: designSweep, balanceSweep, benchmarkTime

    if nargin < 1 || isempty(cat), cat = parts(); end
    if nargin < 2 || isempty(paths), paths = ["drag", "technical", "endurance"]; end
    courses = cell(1, numel(paths));
    for j = 1:numel(paths)
        if iscell(paths), courses{j} = paths{j}; else, courses{j} = loadPath(paths(j)); end
    end
    names = cellfun(@(c) char(c.name), courses, 'UniformOutput', false);
    nP = numel(courses);
    partNames = cat.partNames;

    % ---- reference times: middle option of every part ------------------ %
    ref = struct('team', "Ref");
    for p = partNames, ref.(p) = cat.(p)(2).id; end
    refCar = buildCar(ref, cat);
    tref = zeros(1, nP);
    for j = 1:nP, tref(j) = benchmarkTime(refCar, courses{j}).time; end

    % ---- 1. one part at a time from several base cars ------------------ %
    bases = struct('name', {"cheap", "balanced", "power", "grip", "aero"}, ...
                   'idx',  {[1 1 1 1 2], [2 2 2 2 2], [3 2 1 1 3], [2 1 3 2 1], [2 2 2 3 2]});
    effect = nan(numel(partNames), nP, numel(bases));
    winner = zeros(numel(partNames), nP, numel(bases));
    for bi = 1:numel(bases)
        for pk = 1:numel(partNames)
            sc = nan(3, nP);
            for opt = 1:3
                idx = bases(bi).idx;  idx(pk) = opt;
                d = struct('team', "T");
                for q = 1:numel(partNames), d.(partNames(q)) = cat.(partNames(q))(idx(q)).id; end
                try
                    car = buildCar(d, cat);
                catch
                    continue;                              % over budget
                end
                for j = 1:nP, sc(opt, j) = scoreOne(car, courses{j}, tref(j)); end
            end
            ok = ~any(isnan(sc), 2);
            if sum(ok) >= 2
                s2 = sc;  s2(~ok, :) = -Inf;
                [mx, w] = max(s2, [], 1);
                effect(pk, :, bi) = mx - min(sc(ok, :), [], 1);
                winner(pk, :, bi) = w;
            end
        end
    end
    fprintf('\nMEASURED SENSITIVITY (best option (base cars where it wins), mean score spread best-worst)\n');
    fprintf('%-9s', 'part');
    for j = 1:nP, fprintf('%24s', names{j}); end
    fprintf('\n');
    for pk = 1:numel(partNames)
        fprintf('%-9s', partNames(pk));
        ids = [cat.(partNames(pk)).id];
        for j = 1:nP
            w = squeeze(winner(pk, j, :));  w = w(w > 0);
            e = mean(squeeze(effect(pk, j, :)), 'omitnan');
            if isempty(w), fprintf('%24s', '-'); continue; end
            counts = histcounts(w, 0.5:1:3.5);
            [~, b] = max(counts);
            fprintf('%24s', sprintf('%s (%d/%d) %5.1f', ids(b), counts(b), numel(w), e));
        end
        fprintf('\n');
    end

    % ---- 2. all affordable designs ------------------------------------- %
    T = designSweep(courses, 'Catalogue', cat, 'Reference', ref);
    sCols = T.Properties.VariableNames(startsWith(T.Properties.VariableNames, 's_'));
    best = T.overall(1);
    near = T.overall >= 0.95 * best;
    fprintf('\nALL %d AFFORDABLE DESIGNS (benchmark scores vs the middle-option car)\n', height(T));
    fprintf('overall: best %.1f, median %.1f, worst %.1f; within 5%% of best: %d designs\n', ...
        best, median(T.overall), T.overall(end), sum(near));
    disp(T(1:min(8, height(T)), [{'motor', 'battery', 'tyres', 'aero', 'gearing', 'cost'}, sCols, {'overall'}]));
    fprintf('best design per path:\n');
    topRows = zeros(1, numel(sCols));
    for j = 1:numel(sCols)
        [~, k] = max(T.(sCols{j}));  topRows(j) = k;
        fprintf('  %-26s %s %s %s %s %s  (%.1f)\n', sCols{j}, T.motor(k), T.battery(k), T.tyres(k), T.aero(k), T.gearing(k), T.(sCols{j})(k));
    end
    fprintf('one design best on every path: %s\n', string(all(topRows == topRows(1))));
    [~, k] = min(T.cost);
    fprintf('cheapest design (%d credits): %s %s %s %s %s  scores %s  overall %.1f\n', T.cost(k), T.motor(k), T.battery(k), ...
        T.tyres(k), T.aero(k), T.gearing(k), mat2str(round(T{k, sCols}, 1)), T.overall(k));

    % endurance energy check: smallest battery at full pace
    jE = find(cellfun(@(c) c.laps > 1, courses), 1);
    if ~isempty(jE)
        small = ref;  small.battery = cat.battery(1).id;
        b = benchmarkTime(buildCar(small, cat), courses{jE}, 'EnergyLimited', false);
        fprintf('%s at full pace (middle car, smallest battery) needs %.1f Wh; the battery holds %d Wh -> must manage energy: %s\n', ...
            names{jE}, b.energyWh, cat.battery(1).energyWh, string(b.energyWh > cat.battery(1).energyWh));
    end
    fprintf('reference (middle-option) benchmark times: %s s\n', mat2str(round(tref, 2)));
    out = struct('table', T, 'effect', effect, 'winner', winner, 'tref', tref);
    if nargout == 0, clear out; end
end

function s = scoreOne(car, course, tref)
    b = benchmarkTime(car, course);
    if b.feasible, s = min(120, 100 * tref / b.time); else, s = 0; end
end
