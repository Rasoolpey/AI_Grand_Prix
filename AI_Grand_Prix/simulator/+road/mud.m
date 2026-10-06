function p = mud(len)
% MUD  Mark the next LEN metres of road as mud.
%
%   p = road.mud(len)                   e.g. road.mud(40)
%
%   Mud is slippery AND sticky:
%     grip            mu   x 0.6   (like a wet patch: eqs. 5, 6)
%     rolling loss    C_rr x 4     (eq. 4: F_roll = 4 C_rr N)
%   A marker, not a piece of road: it takes no length itself.  Preview
%   points on mud carry slippery = 1 (column 4) and mud = 1 (column 5).
%
%   See also: road.surface, buildPath
    p = road.surface(0.6, len, 4);
end
