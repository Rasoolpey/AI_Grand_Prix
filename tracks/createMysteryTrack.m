function trackData = createMysteryTrack()
% CREATEMYSTERYTRACK  Generate the AI Grand Prix mystery/championship track.
%
%   ╔════════════════════════════════════════════════════════╗
%   ║  INSTRUCTOR FILE — DO NOT DISTRIBUTE TO STUDENTS      ║
%   ║  Run this on the evaluation machine to generate       ║
%   ║  tracks/mysteryTrack.mat before the championship.     ║
%   ╚════════════════════════════════════════════════════════╝
%
%   trackData = createMysteryTrack()
%
%   A technically demanding circuit (~290 m) different from the practice
%   track.  Features:
%     M1  Short start straight     (East,  35 m)
%     M2  Tight right 90°  r=8 m   — sharp entry corner
%     M3  Medium straight          (South, 45 m)
%     M4  Left  45°  r=18 m        — long sweeping left
%     M5  Straight                 (SE,    25 m)
%     M6  Right 135°  r=8 m        — tight right hairpin-ish
%     M7  Straight                 (NE,    30 m)
%     M8  Left  90°  r=12 m        — medium left
%     M9  Straight                 (NW,    40 m)
%     M10 Right 180°  r=9 m        — closing hairpin
%
%   Track width: 5 m
%
%   See also: evaluateAll, Track

    trackWidth = 5.0;
    res        = 0.5;

    pts = zeros(0, 2);
    x = 0;  y = 0;  h = 0;

    % --- circuit segments ---
    [pts, x, y, h] = segStraight(pts, x, y, h, 35,    res);          % M1
    [pts, x, y, h] = segArc    (pts, x, y, h, -pi/2,  8,    res);    % M2  tight right
    [pts, x, y, h] = segStraight(pts, x, y, h, 45,    res);          % M3
    [pts, x, y, h] = segArc    (pts, x, y, h, +pi/4,  18,   res);    % M4  sweeping left
    [pts, x, y, h] = segStraight(pts, x, y, h, 25,    res);          % M5
    [pts, x, y, h] = segArc    (pts, x, y, h, -3*pi/4, 8,   res);    % M6  tight right
    [pts, x, y, h] = segStraight(pts, x, y, h, 30,    res);          % M7
    [pts, x, y, h] = segArc    (pts, x, y, h, +pi/2,  12,   res);    % M8  medium left
    [pts, x, y, h] = segStraight(pts, x, y, h, 40,    res);          % M9
    [pts, x, y, h] = segArc    (pts, x, y, h, -pi,    9,    res);    % M10 closing hairpin %#ok<ASGLU>

    % Close loop
    pts(end+1, :) = pts(1, :);

    % Smooth / resample
    diffs   = diff(pts, 1, 1);
    segLens = sqrt(sum(diffs.^2, 2));
    cumD    = [0; cumsum(segLens)];

    nFinal  = round(cumD(end) / res);
    sUnif   = linspace(0, cumD(end-1), nFinal)';

    cx = interp1(cumD, pts(:,1), sUnif, 'pchip');
    cy = interp1(cumD, pts(:,2), sUnif, 'pchip');
    centreline = [cx, cy];

    N    = size(centreline, 1);
    next = mod((1:N)', N) + 1;
    tang = centreline(next,:) - centreline;
    tLen = sqrt(sum(tang.^2, 2));
    tang = tang ./ tLen;
    normals = [-tang(:,2), tang(:,1)];

    halfW          = trackWidth / 2;
    leftBoundary   = centreline + halfW * normals;
    rightBoundary  = centreline - halfW * normals;

    segD      = sqrt(sum(diff(centreline([1:end,1],:)).^2, 2));
    cumDist   = [0; cumsum(segD(1:end-1))];
    lapLength = cumDist(end) + segD(end);

    sfPt = centreline(1,:);
    sfN  = normals(1,:);
    startFinishLine = [sfPt - halfW*sfN, sfPt + halfW*sfN];

    trackData.centreline      = centreline;
    trackData.width           = trackWidth;
    trackData.normals         = normals;
    trackData.leftBoundary    = leftBoundary;
    trackData.rightBoundary   = rightBoundary;
    trackData.cumDist         = cumDist;
    trackData.lapLength       = lapLength;
    trackData.startFinishLine = startFinishLine;
    trackData.startFinishIdx  = 1;
    trackData.name            = 'Mystery Track';
end

% ======================================================================
%  Local segment builders (duplicated for self-contained file)
% ======================================================================

function [pts, xE, yE, hE] = segStraight(pts, x, y, h, len, res)
    nPts   = max(2, ceil(len / res) + 1);
    s      = linspace(0, len, nPts)';
    newPts = [x + s.*cos(h), y + s.*sin(h)];
    if ~isempty(pts), newPts = newPts(2:end,:); end
    pts = [pts; newPts];
    xE = x + len*cos(h); yE = y + len*sin(h); hE = h;
end

function [pts, xE, yE, hE] = segArc(pts, x, y, h, dh, radius, res)
    arcLen = abs(dh) * radius;
    nPts   = max(3, ceil(arcLen / res) + 1);
    cDir   = h + sign(dh)*pi/2;
    cx     = x + radius*cos(cDir);
    cy     = y + radius*sin(cDir);
    sa     = atan2(y-cy, x-cx);
    ea     = sa + dh;
    angles = linspace(sa, ea, nPts)';
    newPts = [cx + radius*cos(angles), cy + radius*sin(angles)];
    if ~isempty(pts), newPts = newPts(2:end,:); end
    pts = [pts; newPts];
    xE = cx + radius*cos(ea);
    yE = cy + radius*sin(ea);
    hE = atan2(sin(h+dh), cos(h+dh));
end
