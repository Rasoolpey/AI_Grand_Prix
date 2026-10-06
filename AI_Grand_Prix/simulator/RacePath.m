classdef RacePath
% RACEPATH  A road the car races on: a closed circuit or an open strip.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   Built by buildPath from road pieces.  Points along the centreline are
%   ~0.5 m apart and each carries its distance s, heading, curvature,
%   grade (%), elevation z, grip factor (muFactor, < 1 on wet or mud) and
%   rolling-resistance factor (rollFactor, > 1 on mud).
%
%   Key methods:
%     [idx, crossErr, sProj] = course.locate(x, y, hintIdx)
%     pts = course.preview(idx, n)        n x 5: [x y grade slippery mud], ~1 m apart
%     r   = course.roadAt(idx)            alpha (rad) and muFactor at a point
%     course.checkpointLine(k) / course.finishLine()   [x1 y1 x2 y2]
%
%   See also: buildPath, RaceSimulation

    properties (SetAccess = private)
        name        string = "Path"
        type        string = "circuit"   % "circuit" or "open"
        laps        double = 1
        width       double = 5           % m
        runoff      double = 3           % m from the road edge to the barrier
        timeLimit   double = 120         % s
        s           (:,1) double         % distance along the centreline (m)
        centreline  (:,2) double
        heading     (:,1) double         % rad
        kappa       (:,1) double         % curvature 1/m (+ = left)
        grade       (:,1) double         % % (uphill +)
        z           (:,1) double         % elevation (m)
        muFactor    (:,1) double         % 1 dry, < 1 wet or mud
        rollFactor  (:,1) double         % 1 normal, > 1 mud (multiplies C_rr)
        normals     (:,2) double         % unit, pointing left
        leftBoundary  (:,2) double
        rightBoundary (:,2) double
        length      double               % lap length (circuit) / total length (open)
        finishS     double = 0           % s of the finish line
        stopBox     (1,2) double = [NaN NaN]
        checkpointS (:,1) double
        checkpointIdx (:,1) double
        finishIdx   double = 1
        ds          double               % point spacing (m)
    end

    methods
        function obj = RacePath(d)
            f = fieldnames(d);
            for i = 1:numel(f), obj.(f{i}) = d.(f{i}); end
            obj.normals = [-sin(obj.heading), cos(obj.heading)];
            hw = obj.width / 2;
            obj.leftBoundary  = obj.centreline + hw * obj.normals;
            obj.rightBoundary = obj.centreline - hw * obj.normals;
            obj.ds = mean(diff(obj.s));
            if isempty(obj.rollFactor), obj.rollFactor = ones(size(obj.s)); end
            obj.checkpointIdx = obj.indexAt(obj.checkpointS);
            obj.finishIdx = obj.indexAt(obj.finishS);
        end

        function tf = isCircuit(obj)
            tf = obj.type == "circuit";
        end

        function n = numPoints(obj)
            n = numel(obj.s);
        end

        function idx = indexAt(obj, sq)
        % Nearest centreline index to distance(s) sq.
            idx = round(sq / obj.ds) + 1;
            n = obj.numPoints();
            if obj.isCircuit()
                idx = mod(idx - 1, n) + 1;
            else
                idx = min(max(idx, 1), n);
            end
        end

        function [idx, crossErr, sProj] = locate(obj, x, y, hint)
        % LOCATE  Nearest centreline point, signed offset (+ = left) and the
        % distance along the path of the car's projection.  Searches near
        % HINT first (the previous index), then the whole path if needed.
            n = obj.numPoints();
            if nargin >= 4 && ~isempty(hint)
                w = 60;                                       % +-30 m
                if obj.isCircuit()
                    cand = mod((hint - w : hint + w) - 1, n) + 1;
                else
                    cand = max(1, hint - w) : min(n, hint + w);
                end
                [d2, k] = min((obj.centreline(cand,1) - x).^2 + (obj.centreline(cand,2) - y).^2);
                idx = cand(k);
                if d2 > (obj.width/2 + obj.runoff + 2)^2
                    [~, idx] = min((obj.centreline(:,1) - x).^2 + (obj.centreline(:,2) - y).^2);
                end
            else
                [~, idx] = min((obj.centreline(:,1) - x).^2 + (obj.centreline(:,2) - y).^2);
            end
            dx = x - obj.centreline(idx,1);
            dy = y - obj.centreline(idx,2);
            crossErr = dx * obj.normals(idx,1) + dy * obj.normals(idx,2);
            sProj = obj.s(idx) + dx * cos(obj.heading(idx)) + dy * sin(obj.heading(idx));
            if obj.isCircuit()
                sProj = mod(sProj, obj.length);
            end
        end

        function pts = preview(obj, idx, n)
        % PREVIEW  The next n centreline points, ~1 m apart, starting ~1 m
        % ahead of idx.  Columns: x, y, grade (%), slippery (1 on a wet
        % patch or mud: less grip), mud (1 on mud: more rolling resistance).
        % On an open path the list stops at the end of the road.
            step = max(1, round(1 / obj.ds));
            ii = idx + (1:n)' * step;
            if obj.isCircuit()
                ii = mod(ii - 1, obj.numPoints()) + 1;
            else
                ii = ii(ii <= obj.numPoints());
            end
            pts = [obj.centreline(ii,:), obj.grade(ii), double(obj.muFactor(ii) < 1), double(obj.rollFactor(ii) > 1)];
        end

        function obj = withTimeLimit(obj, t)
        % A copy of the path with a different time limit.
            obj.timeLimit = t;
        end

        function r = roadAt(obj, idx)
            r.alpha      = atan(obj.grade(idx) / 100);
            r.muFactor   = obj.muFactor(idx);
            r.rollFactor = obj.rollFactor(idx);
        end

        function L = checkpointLine(obj, k)
            L = obj.lineAt(obj.checkpointIdx(k));
        end

        function L = finishLine(obj)
            L = obj.lineAt(obj.finishIdx);
        end

        function L = lineAt(obj, idx)
        % A line across the road at idx, reaching the barriers on both sides.
            h = obj.width / 2 + obj.runoff;
            c = obj.centreline(idx,:);  nrm = obj.normals(idx,:);
            L = [c - h * nrm, c + h * nrm];
        end

        function plot(obj, ax)
        % PLOT  Simple top-down drawing (road shaded by height) for plotLap.
            if nargin < 2, ax = gca; end
            hold(ax, 'on');
            L = obj.leftBoundary;  R = obj.rightBoundary;
            if obj.isCircuit(), L(end+1,:) = L(1,:); R(end+1,:) = R(1,:); end
            zz = obj.z;  if obj.isCircuit(), zz(end+1) = zz(1); end
            zr = max(zz) - min(zz);  if zr < 0.1, zr = 1; end
            shade = 0.25 + 0.25 * (zz - min(zz)) / zr;          % lighter = higher
            X = [L(:,1)'; R(:,1)'];  Y = [L(:,2)'; R(:,2)'];  Z = zeros(size(X));
            C = repmat(reshape(shade, 1, [], 1), 2, 1, 3);       % true colour: leaves the colormap free
            surface(ax, X, Y, Z, C, 'EdgeColor', 'none', 'FaceColor', 'interp', 'HandleVisibility', 'off');
            plot(ax, L(:,1), L(:,2), 'w-', 'LineWidth', 1, 'HandleVisibility', 'off');
            plot(ax, R(:,1), R(:,2), 'w-', 'LineWidth', 1, 'HandleVisibility', 'off');
            mud = obj.rollFactor > 1;
            wet = obj.muFactor < 1 & ~mud;
            if any(wet)
                plot(ax, obj.centreline(wet,1), obj.centreline(wet,2), '.', 'Color', [0.3 0.6 1], ...
                    'MarkerSize', 10, 'HandleVisibility', 'off');
            end
            if any(mud)
                plot(ax, obj.centreline(mud,1), obj.centreline(mud,2), '.', 'Color', [0.65 0.45 0.25], ...
                    'MarkerSize', 12, 'HandleVisibility', 'off');
            end
            F = obj.finishLine();
            plot(ax, F([1 3]), F([2 4]), 'g-', 'LineWidth', 3, 'HandleVisibility', 'off');
            if ~isnan(obj.stopBox(1))
                for sb = obj.stopBox
                    B = obj.lineAt(obj.indexAt(sb));
                    plot(ax, B([1 3]), B([2 4]), 'y-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
            end
            axis(ax, 'equal');
        end
    end

    methods (Static)
        function [hit, frac] = crosses(p1, p2, L)
        % CROSSES  Does the move p1 -> p2 cross line L = [x1 y1 x2 y2]?
        % frac in [0,1] is where along the move it crosses.  L may be an
        % m x 4 matrix; hit and frac are then m x 1.
            rx = p2(1) - p1(1);  ry = p2(2) - p1(2);
            sx = L(:,3) - L(:,1);  sy = L(:,4) - L(:,2);
            den = rx .* sy - ry .* sx;
            qx = L(:,1) - p1(1);  qy = L(:,2) - p1(2);
            t = (qx .* sy - qy .* sx) ./ den;     % along the move
            u = (qx .* ry - qy .* rx) ./ den;     % along the line
            hit = abs(den) > 1e-12 & t > 0 & t <= 1 & u >= 0 & u <= 1;
            frac = t;
        end
    end
end
