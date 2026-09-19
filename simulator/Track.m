classdef Track
% TRACK  Race track representation for the AI Grand Prix simulator.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   Holds centreline, boundaries, normals, and distances.
%   Provides spatial queries used by RaceSimulation and plotLap.
%
%   Construction:
%     trackData = createPracticeTrack();   % or createMysteryTrack()
%     track     = Track(trackData);
%
%   Key methods:
%     track.findNearest(x, y)              → [idx, crossErr, onTrack]
%     track.getPreviewPoints(x,y,h,n)      → nPts×2 [x,y]
%     track.checkStartFinish(x1,y1,x2,y2) → logical
%     track.plot(ax)                       → draws track on axes

    % ------------------------------------------------------------------ %
    %  Properties                                                         %
    % ------------------------------------------------------------------ %
    properties (GetAccess = public, SetAccess = private)
        centreline      (:,2) double    % Nx2 [x, y] centreline points
        width           (1,1) double    % track width (m)
        normals         (:,2) double    % Nx2 unit normals, left of travel direction
        leftBoundary    (:,2) double    % Nx2 left edge
        rightBoundary   (:,2) double    % Nx2 right edge
        cumDist         (:,1) double    % Nx1 cumulative arc-length (m)
        lapLength       (1,1) double    % total lap distance (m)
        startFinishLine (1,4) double    % [x1 y1 x2 y2] finish-line segment
        startFinishIdx  (1,1) double = 1
        name            (1,:) char   = 'Track'
    end

    % ------------------------------------------------------------------ %
    %  Constructor                                                        %
    % ------------------------------------------------------------------ %
    methods

        function obj = Track(trackData)
        % TRACK(trackData)  Construct from a track data struct.
        %
        %   trackData: struct produced by createPracticeTrack() or
        %              createMysteryTrack().  Required fields:
        %     .centreline, .width, .normals, .leftBoundary,
        %     .rightBoundary, .cumDist, .lapLength,
        %     .startFinishLine, .startFinishIdx
            obj.centreline      = trackData.centreline;
            obj.width           = trackData.width;
            obj.normals         = trackData.normals;
            obj.leftBoundary    = trackData.leftBoundary;
            obj.rightBoundary   = trackData.rightBoundary;
            obj.cumDist         = trackData.cumDist;
            obj.lapLength       = trackData.lapLength;
            obj.startFinishLine = trackData.startFinishLine;
            obj.startFinishIdx  = trackData.startFinishIdx;
            if isfield(trackData, 'name')
                obj.name = trackData.name;
            end
        end

        % -------------------------------------------------------------- %
        %  Spatial queries                                                %
        % -------------------------------------------------------------- %

        function [nearestIdx, crossErr, onTrack] = findNearest(obj, x, y)
        % FINDNEAREST  Find nearest centreline point and signed cross-track error.
        %
        %   [idx, crossErr, onTrack] = track.findNearest(x, y)
        %
        %   crossErr > 0 : car is to the LEFT  of centreline
        %   crossErr < 0 : car is to the RIGHT of centreline
        %   onTrack      : true when |crossErr| <= width/2

            dx = obj.centreline(:,1) - x;
            dy = obj.centreline(:,2) - y;
            [~, nearestIdx] = min(dx.^2 + dy.^2);

            n = obj.normals(nearestIdx, :);
            toVeh = [x - obj.centreline(nearestIdx,1), ...
                     y - obj.centreline(nearestIdx,2)];
            crossErr = dot(toVeh, n);
            onTrack  = abs(crossErr) <= (obj.width / 2);
        end

        % -------------------------------------------------------------- %
        function pts = getPreviewPoints(obj, x, y, ~, nPoints)
        % GETPREVIEWPOINTS  Return the next nPoints centreline waypoints.
        %
        %   pts = track.getPreviewPoints(x, y, heading, nPoints)
        %   pts : nPoints×2 [x, y]

            [nearestIdx, ~, ~] = obj.findNearest(x, y);
            N = size(obj.centreline, 1);
            % Look-ahead indices (wrapped)
            ii = mod((nearestIdx : nearestIdx + nPoints - 1) - 1, N) + 1;
            pts = obj.centreline(ii, :);
        end

        % -------------------------------------------------------------- %
        function crossed = checkStartFinish(obj, x1, y1, x2, y2)
        % CHECKSTARTFINISH  True if vehicle segment [p1→p2] crosses S/F line.
        %
        %   Used to detect lap completion.
        %   Requires the vehicle to have MOVED since last check (p1 ≠ p2).

            sx1 = obj.startFinishLine(1); sy1 = obj.startFinishLine(2);
            sx2 = obj.startFinishLine(3); sy2 = obj.startFinishLine(4);
            crossed = Track.segmentsIntersect(x1, y1, x2, y2, sx1, sy1, sx2, sy2);
        end

        % -------------------------------------------------------------- %
        function plot(obj, ax)
        % PLOT(ax)  Draw the full track on the given axes handle.
        %
        %   Draws: filled track surface, white boundaries, dashed centreline,
        %   and green start/finish line.

            if nargin < 2, ax = gca; end
            hold(ax, 'on');

            % Close the boundaries for fill
            n  = size(obj.centreline, 1);
            lX = [obj.leftBoundary(:,1);  obj.leftBoundary(1,1)];
            lY = [obj.leftBoundary(:,2);  obj.leftBoundary(1,2)];
            rX = [obj.rightBoundary(:,1); obj.rightBoundary(1,1)];
            rY = [obj.rightBoundary(:,2); obj.rightBoundary(1,2)];

            % Fill track surface (dark grey)
            fill(ax, [lX; flipud(rX)], [lY; flipud(rY)], ...
                [0.22 0.22 0.22], 'EdgeColor', 'none', 'HandleVisibility', 'off');

            % Kerb hatching along boundaries (alternating colours)
            kerbLen = 3;  % metres per kerb block
            nKerb   = floor(obj.lapLength / kerbLen);
            halfW   = obj.width / 2;
            kerbW   = 0.5;  % metres
            for k = 0:nKerb-1
                d = k * kerbLen;
                [~, i1] = min(abs(obj.cumDist - d));
                [~, i2] = min(abs(obj.cumDist - min(d + kerbLen, obj.lapLength)));
                col = [1 1 1] * (0.6 + 0.4*mod(k,2));  % alternate white/grey
                % Left kerb
                kLX = [obj.leftBoundary(i1,1), obj.leftBoundary(i2,1), ...
                       obj.leftBoundary(i2,1) - kerbW*obj.normals(i2,1), ...
                       obj.leftBoundary(i1,1) - kerbW*obj.normals(i1,1)];
                kLY = [obj.leftBoundary(i1,2), obj.leftBoundary(i2,2), ...
                       obj.leftBoundary(i2,2) - kerbW*obj.normals(i2,2), ...
                       obj.leftBoundary(i1,2) - kerbW*obj.normals(i1,2)];
                fill(ax, kLX, kLY, col, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                % Right kerb
                kRX = [obj.rightBoundary(i1,1), obj.rightBoundary(i2,1), ...
                       obj.rightBoundary(i2,1) + kerbW*obj.normals(i2,1), ...
                       obj.rightBoundary(i1,1) + kerbW*obj.normals(i1,1)];
                kRY = [obj.rightBoundary(i1,2), obj.rightBoundary(i2,2), ...
                       obj.rightBoundary(i2,2) + kerbW*obj.normals(i2,2), ...
                       obj.rightBoundary(i1,2) + kerbW*obj.normals(i1,2)];
                fill(ax, kRX, kRY, col, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            end

            % White boundary lines
            plot(ax, [lX; lX(1)], [lY; lY(1)], 'w-', 'LineWidth', 1.5, ...
                'HandleVisibility', 'off');
            plot(ax, [rX; rX(1)], [rY; rY(1)], 'w-', 'LineWidth', 1.5, ...
                'HandleVisibility', 'off');

            % Dashed centreline
            cX = [obj.centreline(:,1); obj.centreline(1,1)];
            cY = [obj.centreline(:,2); obj.centreline(1,2)];
            plot(ax, cX, cY, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5, ...
                'HandleVisibility', 'off');

            % Start/finish line (green)
            plot(ax, [obj.startFinishLine(1), obj.startFinishLine(3)], ...
                     [obj.startFinishLine(2), obj.startFinishLine(4)], ...
                     'g-', 'LineWidth', 3, 'HandleVisibility', 'off');
        end

    end % methods (public)

    % ------------------------------------------------------------------ %
    %  Private static geometry helpers                                    %
    % ------------------------------------------------------------------ %
    methods (Static, Access = private)

        function tf = segmentsIntersect(ax, ay, bx, by, cx, cy, dx, dy)
        % Robust segment intersection test using cross-product signs.
            d1 = Track.cross2(dx-cx, dy-cy, ax-cx, ay-cy);
            d2 = Track.cross2(dx-cx, dy-cy, bx-cx, by-cy);
            d3 = Track.cross2(bx-ax, by-ay, cx-ax, cy-ay);
            d4 = Track.cross2(bx-ax, by-ay, dx-ax, dy-ay);

            tf = ( ((d1>0&&d2<0)||(d1<0&&d2>0)) && ...
                   ((d3>0&&d4<0)||(d3<0&&d4>0)) );
        end

        function c = cross2(ux, uy, vx, vy)
            c = ux*vy - uy*vx;
        end

    end % methods (static)
end % classdef
