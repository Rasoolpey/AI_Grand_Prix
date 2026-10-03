function p = surface(muFactor, len)
% SURFACE  Mark the next LEN metres of road with a grip factor (a wet patch).
%
%   p = road.surface(muFactor, len)     e.g. road.surface(0.7, 30)
%
%   A marker, not a piece of road: it takes no length itself.  The patch
%   starts where the marker is placed in the piece list.  Preview points
%   on it carry wet = 1.
%
%   See also: road.straight, buildPath
    if ~(muFactor > 0 && muFactor <= 1 && len > 0)
        error('road:surface', 'need 0 < muFactor <= 1 and len > 0');
    end
    p = road.piece("surface", len, 0, 0, false, muFactor);
end
