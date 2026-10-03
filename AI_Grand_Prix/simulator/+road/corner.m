function p = corner(R, angleDeg, dir, grade)
% CORNER  A constant-radius corner (an arc).
%
%   p = road.corner(R, angleDeg, dir)
%   p = road.corner(R, angleDeg, dir, grade)
%
%   R         radius of the centreline (m)
%   angleDeg  how far the road turns (degrees, > 0)
%   dir       "L" (left, counter-clockwise) or "R" (right)
%   grade     road grade in % (uphill +), default 0
%
%   buildPath adds clothoid transitions automatically, so curvature
%   changes smoothly into and out of the corner.
%
%   See also: road.straight, road.chicane, buildPath
    if nargin < 4 || isempty(grade), grade = 0; end
    if ~(R > 0 && angleDeg > 0), error('road:corner', 'R and angleDeg must be > 0'); end
    switch upper(string(dir))
        case "L", sgn = 1;
        case "R", sgn = -1;
        otherwise, error('road:corner', 'dir must be "L" or "R"');
    end
    p = road.piece("corner", R * deg2rad(angleDeg), sgn / R, grade);
end
