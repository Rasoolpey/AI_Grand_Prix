function p = surface(muFactor, len, rollFactor)
% SURFACE  Mark the next LEN metres of road with a different surface.
%
%   p = road.surface(muFactor, len)              a wet patch, e.g. road.surface(0.7, 30)
%   p = road.surface(muFactor, len, rollFactor)  also multiplies the rolling resistance
%                                                (mud: use road.mud)
%
%   A marker, not a piece of road: it takes no length itself.  The patch
%   starts where the marker is placed in the piece list.  Preview points on
%   it carry slippery = 1 (column 4) and, if rollFactor > 1, mud = 1 (column 5).
%
%   See also: road.mud, road.straight, buildPath
    if nargin < 3, rollFactor = 1; end
    if ~(muFactor > 0 && muFactor <= 1 && len > 0 && rollFactor >= 1)
        error('road:surface', 'need 0 < muFactor <= 1, len > 0 and rollFactor >= 1');
    end
    p = road.piece("surface", len, 0, 0, false, muFactor, rollFactor);
end
