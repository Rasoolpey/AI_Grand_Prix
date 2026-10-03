function p = chicane(offset, len, dir, grade)
% CHICANE  Step sideways by OFFSET and back again over LEN metres (4 arcs).
%
%   p = road.chicane(offset, len)          first kink to the left
%   p = road.chicane(offset, len, "R")     first kink to the right
%   p = road.chicane(offset, len, dir, grade)
%
%   The road leaves and rejoins the original line with the same heading.
%   Each half (len/2) is an S-bend made of two equal arcs.
%
%   See also: road.corner, road.straight, buildPath
    if nargin < 3 || isempty(dir), dir = "L"; end
    if nargin < 4 || isempty(grade), grade = 0; end
    if ~(offset > 0 && len > 0), error('road:chicane', 'offset and len must be > 0'); end
    l = len / 2;                          % forward length of one S-bend
    th = 2 * atan(offset / l);            % angle of each arc
    R  = l / (2 * sin(th));               % radius of each arc
    a  = rad2deg(th);
    other = "R"; if upper(string(dir)) == "R", other = "L"; end
    p = [road.corner(R, a, dir, grade), road.corner(R, a, other, grade), ...
         road.corner(R, a, other, grade), road.corner(R, a, dir, grade)];
end
