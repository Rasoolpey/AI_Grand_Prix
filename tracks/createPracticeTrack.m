function trackData = createPracticeTrack()
% CREATEPRACTICETRACK  Generate the AI Grand Prix practice track.
%
%   trackData = createPracticeTrack()
%
%   Builds a closed circuit from chained arc and straight segments,
%   resamples to uniform point spacing, then computes normals and
%   track boundaries.
%
%   Circuit layout (~325 m total):
%     S1  Straight 70 m       — long start/finish straight (East)
%     S2  Right 90°  r=20 m   — mild right-hand sweep
%     S3  Straight 50 m       — fast back section (South)
%     S4  Right 180° r=10 m   — tight hairpin (heading reversal)
%     S5  Straight 40 m       — return straight (North)
%     S6  Left  90°  r=15 m   — left-hand sweep
%     S7  Straight 55 m       — back straight (West)
%     S8  Right 180° r=7.5 m  — closing hairpin (loops back to start)
%
%   Track width: 5 m
%   Centreline point spacing: ~0.5 m
%
%   See also: Track, practiceRace

    trackWidth = 5.0;    % metres
    res        = 0.5;    % target point spacing (metres)

    % ------------------------------------------------------------------
    % Build centreline from chained segments
    % Convention: dh > 0 = left (CCW), dh < 0 = right (CW)
    % ------------------------------------------------------------------
    pts = zeros(0, 2);
    x = 0;  y = 0;  h = 0;      % start at origin, heading East

    [pts, x, y, h] = segStraight(pts, x, y, h, 70,   res);  % S1
    [pts, x, y, h] = segArc    (pts, x, y, h, -pi/2, 20,   res);  % S2
    [pts, x, y, h] = segStraight(pts, x, y, h, 50,   res);  % S3
    [pts, x, y, h] = segArc    (pts, x, y, h, -pi,   10,   res);  % S4 hairpin
    [pts, x, y, h] = segStraight(pts, x, y, h, 40,   res);  % S5
    [pts, x, y, h] = segArc    (pts, x, y, h, +pi/2, 15,   res);  % S6
    [pts, x, y, h] = segStraight(pts, x, y, h, 55,   res);  % S7
    [pts, x, y, h] = segArc    (pts, x, y, h, -pi,   7.5,  res);  % S8 hairpin %#ok<ASGLU>

    % Close the loop (connect back to start)
    pts(end+1, :) = pts(1, :);

    % ------------------------------------------------------------------
    % Remove consecutive near-duplicate points
    % (the circuit closes geometrically, so the last arc point lands
    %  very close to pts(1,:) — this avoids zero-length segments that
    %  cause cumD to have duplicate values and interp1 to error.)
    % ------------------------------------------------------------------
    segD = sqrt(sum(diff(pts, 1, 1).^2, 2));
    keep = [true; segD > 1e-9];
    pts  = pts(keep, :);

    % ------------------------------------------------------------------
    % Smooth and resample to uniform spacing
    % ------------------------------------------------------------------
    diffs   = diff(pts, 1, 1);
    segLens = sqrt(sum(diffs.^2, 2));
    cumD    = [0; cumsum(segLens)];

    nFinal  = round(cumD(end) / res);
    sUnif   = linspace(0, cumD(end-1), nFinal)';   % don't double-count closing point

    cx = interp1(cumD, pts(:,1), sUnif, 'pchip');
    cy = interp1(cumD, pts(:,2), sUnif, 'pchip');
    centreline = [cx, cy];

    % ------------------------------------------------------------------
    % Tangents, normals, boundaries
    % ------------------------------------------------------------------
    N    = size(centreline, 1);
    next = mod((1:N)', N) + 1;

    tang   = centreline(next,:) - centreline;
    tLen   = sqrt(sum(tang.^2, 2));
    tang   = tang ./ tLen;                    % unit tangents

    normals = [-tang(:,2), tang(:,1)];        % left-pointing unit normals

    halfW          = trackWidth / 2;
    leftBoundary   = centreline + halfW * normals;
    rightBoundary  = centreline - halfW * normals;

    % ------------------------------------------------------------------
    % Cumulative distance along resampled centreline
    % ------------------------------------------------------------------
    segD    = sqrt(sum(diff(centreline([1:end, 1], :)).^2, 2));
    cumDist = [0; cumsum(segD(1:end-1))];
    lapLength = cumDist(end) + segD(end);   % approximate total length

    % ------------------------------------------------------------------
    % Start/finish line — perpendicular at index 1 (the origin)
    % ------------------------------------------------------------------
    sfPt = centreline(1, :);
    sfN  = normals(1, :);
    startFinishLine = [sfPt - halfW*sfN, sfPt + halfW*sfN];   % [x1 y1 x2 y2]

    % ------------------------------------------------------------------
    % Pack output struct
    % ------------------------------------------------------------------
    trackData.centreline      = centreline;
    trackData.width           = trackWidth;
    trackData.normals         = normals;
    trackData.leftBoundary    = leftBoundary;
    trackData.rightBoundary   = rightBoundary;
    trackData.cumDist         = cumDist;
    trackData.lapLength       = lapLength;
    trackData.startFinishLine = startFinishLine;
    trackData.startFinishIdx  = 1;
    trackData.name            = 'Practice Track';

end

% =======================================================================
%  Local segment builders
% =======================================================================

function [pts, xE, yE, hE] = segStraight(pts, x, y, h, len, res)
% Append a straight of given length along heading h.
    nPts   = max(2, ceil(len / res) + 1);
    s      = linspace(0, len, nPts)';
    newPts = [x + s.*cos(h),  y + s.*sin(h)];
    if ~isempty(pts)
        newPts = newPts(2:end, :);    % skip duplicate start point
    end
    pts = [pts; newPts];
    xE  = x + len * cos(h);
    yE  = y + len * sin(h);
    hE  = h;
end

function [pts, xE, yE, hE] = segArc(pts, x, y, h, dh, radius, res)
% Append an arc turning by dh radians.
%   dh > 0 → left / CCW    dh < 0 → right / CW
%   radius: arc radius (m)
%
%   Centre of curvature is at 90° left (dh>0) or right (dh<0) of heading.

    arcLen = abs(dh) * radius;
    nPts   = max(3, ceil(arcLen / res) + 1);

    % Centre of curvature (left of heading for CCW, right for CW)
    cDir = h + sign(dh) * pi/2;
    cx   = x + radius * cos(cDir);
    cy   = y + radius * sin(cDir);

    % Angle from centre to car at start/end
    startAngle = atan2(y - cy, x - cx);
    endAngle   = startAngle + dh;       % + for CCW, − for CW

    angles = linspace(startAngle, endAngle, nPts)';
    newPts = [cx + radius.*cos(angles), cy + radius.*sin(angles)];

    if ~isempty(pts)
        newPts = newPts(2:end, :);
    end
    pts = [pts; newPts];

    xE = cx + radius * cos(endAngle);
    yE = cy + radius * sin(endAngle);
    hE = atan2(sin(h + dh), cos(h + dh));   % normalise to [−π, π]
end
