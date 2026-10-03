function S = standings(R, F)
% STANDINGS  Scores and ranking from qualifying results (TODO_RACE §5, D3).
%
%   S = standings(R, F)     R = per-run results (qualify), F = finals (tref, ids)
%
%   Path score  s_i = min(120, 100 * T_ref,i / T_i), T_i = time + penalties; 0 for a DNF.
%   Overall     = 0.6 * mean(s_i) + 0.4 * min(s_i)
%   Ranking (D3): cars that finished every path first, by overall score;
%   then the others by number of paths completed, then overall score.
%   Ties: higher min(s_i), then lower total energy.
%
%   S: one row per team: rank, team, per path time / penalty / score / DNF
%      reason, paths finished, overall, min score, total energy.
%
%   See also: qualify, raceDay
    teams = unique(string({R.team}), 'stable');
    nT = numel(teams);  nP = numel(F.ids);
    T = inf(nT, nP);  pen = zeros(nT, nP);  sc = zeros(nT, nP);  E = zeros(nT, 1);
    why = strings(nT, nP);  name = strings(nT, 1);
    for r = R(:)'
        i = find(teams == r.team);  k = find(F.ids == r.pathId);
        name(i) = string(r.teamName);
        if r.finished
            T(i, k) = r.totalTime;  pen(i, k) = r.penalty;
            sc(i, k) = min(120, 100 * F.tref(k) / r.totalTime);
        else
            why(i, k) = r.dnfReason;
        end
        E(i) = E(i) + r.energyUsedWh;
    end
    nFin = sum(isfinite(T), 2);
    overall = 0.6 * mean(sc, 2) + 0.4 * min(sc, [], 2);
    minS = min(sc, [], 2);
    allFin = nFin == nP;
    % sort: all-finished first, then paths completed, overall, min score, -energy
    [~, order] = sortrows([-double(allFin), -nFin, -overall, -minS, E]);
    S = table((1:nT)', name(order), teams(order)', 'VariableNames', {'rank', 'teamName', 'folder'});
    for k = 1:nP
        id = F.ids(k);
        S.("time_" + id)    = T(order, k);
        S.("penalty_" + id) = pen(order, k);
        S.("score_" + id)   = round(sc(order, k), 1);
        S.("dnf_" + id)     = why(order, k);
    end
    S.pathsFinished = nFin(order);
    S.overall = round(overall(order), 2);
    S.minScore = round(minS(order), 1);
    S.energyWh = round(E(order), 1);
end
