function S = balanceSweep(varargin)
% BALANCESWEEP  Evidence of balance from the full simulator (TODO_RACE §8).
%
%   S = balanceSweep()                       all affordable designs x core paths
%                                            x 4 controller styles x 3 path variations
%   S = balanceSweep('Designs', d, 'Styles', s, 'Variations', [0 1 2], 'Paths', p)
%
%   Variation 0 is the practice path itself; variation k > 0 is a hidden
%   variation (perturbPieces with seed k).  T_ref for each path variation =
%   the middle-option car with the "reference" style.  Score per path =
%   min(120, 100 T_ref / T), 0 for a DNF; overall = 0.6 mean + 0.4 min.
%
%   Passing gives EVIDENCE (not proof) of balance under these controllers
%   and tracks.  Checks printed for every (style, variation):
%     - designs within 5 % of the best overall (want >= 3)
%     - no single design best on every path
%     - the cheapest design finishes every path
%   plus: the smallest battery cannot finish endurance at full throttle
%   without managing energy.
%
%   S fields: designs, styles, variations, paths, time (D x P x K x V),
%             score, overall (D x K x V), robust (mean overall), tref, table
%
%   Uses parfor when the Parallel Computing Toolbox is available.
%
%   See also: trackTuning, designSweep, controllerStyles, perturbPieces

    o = inputParser();
    o.addParameter('Designs', []);
    o.addParameter('Paths', ["drag", "technical", "endurance"]);
    o.addParameter('Styles', controllerStyles());
    o.addParameter('Variations', [0 1 2]);
    o.addParameter('Catalogue', []);
    o.parse(varargin{:});
    cat = o.Results.Catalogue;  if isempty(cat), cat = parts(); end
    designs = o.Results.Designs;  if isempty(designs), designs = allAffordable(cat); end
    paths = string(o.Results.Paths);  styles = o.Results.Styles;  vars = o.Results.Variations;
    nD = numel(designs);  nP = numel(paths);  nK = numel(styles);  nV = numel(vars);

    courses = cell(nP, nV);
    for p = 1:nP
        for v = 1:nV
            courses{p, v} = makeCourse(paths(p), vars(v));
        end
    end

    % T_ref: middle-option car, reference style
    ref = struct('team', "Reference");
    for q = cat.partNames, ref.(q) = cat.(q)(2).id; end
    refCar = buildCar(ref, cat);
    tref = zeros(nP, nV);
    for p = 1:nP
        for v = 1:nV
            r = RaceSimulation(courses{p, v}, refCar, @refController, styles(1).config);
            if ~r.finished, error('balanceSweep:ref', 'The reference car does not finish %s (variation %d): %s', paths(p), vars(v), r.dnfReason); end
            tref(p, v) = r.totalTime;
        end
    end

    % all runs as one flat job list
    [I, P, K, V] = ndgrid(1:nD, 1:nP, 1:nK, 1:nV);
    nJobs = numel(I);
    tt = inf(nJobs, 1);  en = nan(nJobs, 1);
    cars = cell(nD, 1);
    for i = 1:nD, cars{i} = buildCar(designs(i), cat); end
    cfgs = {styles.config};
    fprintf('balanceSweep: %d designs x %d paths x %d styles x %d variations = %d runs\n', nD, nP, nK, nV, nJobs);
    tic;
    parfor j = 1:nJobs
        r = RaceSimulation(courses{P(j), V(j)}, cars{I(j)}, @refController, cfgs{K(j)}); %#ok<PFBNS>
        tt(j) = r.totalTime;  en(j) = r.energyUsedWh;
    end
    fprintf('  done in %.0f s\n', toc);

    time = reshape(tt, nD, nP, nK, nV);
    trefB = reshape(tref, 1, nP, 1, nV);
    score = min(120, 100 * trefB ./ time);
    score(~isfinite(time)) = 0;
    overall = squeeze(0.6 * mean(score, 2) + 0.4 * min(score, [], 2));   % D x K x V
    overall = reshape(overall, nD, nK, nV);
    robust = mean(reshape(overall, nD, []), 2);

    % ---- report --------------------------------------------------------- %
    cost = arrayfun(@(i) cars{i}.cost, 1:nD)';
    [~, cheap] = min(cost);
    fprintf('\n%-11s %-5s %8s %8s %10s %12s %14s\n', 'style', 'var', 'best', 'median', 'within5%', 'one-best-all', 'cheapest-fin');
    for k = 1:nK
        for v = 1:nV
            ov = overall(:, k, v);
            [~, top] = max(squeeze(score(:, :, k, v)), [], 1);
            fprintf('%-11s %-5d %8.1f %8.1f %10d %12s %14s\n', styles(k).name, vars(v), max(ov), median(ov), ...
                sum(ov >= 0.95 * max(ov)), string(all(top == top(1))), string(all(isfinite(time(cheap, :, k, v)))));
        end
    end
    T = struct2table(rmfield(designs, intersect(fieldnames(designs), {'team', 'colour'})));
    T.cost = cost;
    T.robust = robust;
    T.dnfRuns = squeeze(sum(~isfinite(reshape(time, nD, [])), 2));
    T = sortrows(T, 'robust', 'descend');
    fprintf('\nmost robust designs (mean overall over styles and variations):\n');
    disp(T(1:min(12, nD), :));

    % smallest battery at full throttle on endurance (energy management off)
    jE = find(paths == "endurance", 1);
    if ~isempty(jE)
        small = ref;  small.battery = cat.battery(1).id;
        r = RaceSimulation(courses{jE, 1}, buildCar(small, cat), @refController, ...
            struct('gripMargin', 0.98, 'brakeMargin', 0.92, 'kp', 2.5, 'energyAware', false));
        fprintf('smallest battery, full throttle, no energy management on endurance: %s\n', ...
            ternary(r.finished, sprintf('finished in %.1f s (battery left %.0f %%)', r.totalTime, 100 * r.batteryLeftFrac), ...
            "did not finish: " + r.dnfReason));
        r2 = RaceSimulation(courses{jE, 1}, buildCar(small, cat), @refController, styles(1).config);
        fprintf('  ... with the energy-aware reference style: %s\n', ternary(r2.finished, sprintf('%.1f s', r2.totalTime), "DNF: " + r2.dnfReason));
    end

    S = struct('designs', designs, 'styles', styles, 'variations', vars, 'paths', paths, 'time', time, ...
        'energyWh', reshape(en, nD, nP, nK, nV), 'score', score, 'overall', overall, 'robust', robust, ...
        'tref', tref, 'table', T);
end

function c = makeCourse(name, v)
    fn = str2func("practice" + upper(extractBefore(name, 2)) + extractAfter(name, 1));
    if v == 0
        c = fn();
    else
        c = fn(@(p) perturbPieces(p, v));
    end
end

function d = allAffordable(cat)
    d = struct('team', {}, 'motor', {}, 'battery', {}, 'tyres', {}, 'aero', {}, 'gearing', {});
    for m = [cat.motor.id]
        for b = [cat.battery.id]
            for t = [cat.tyres.id]
                for a = [cat.aero.id]
                    for g = [cat.gearing.id]
                        x = struct('team', "sweep", 'motor', m, 'battery', b, 'tyres', t, 'aero', a, 'gearing', g);
                        try, buildCar(x, cat); d(end+1) = x; catch, end %#ok<AGROW>
                    end
                end
            end
        end
    end
end

function v = ternary(c, a, b)
    if c, v = a; else, v = b; end
end
