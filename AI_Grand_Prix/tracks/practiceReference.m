function tref = practiceReference(name)
% PRACTICEREFERENCE  Reference times (T_ref) for the practice paths.
%
%   tref = practiceReference(name)     NaN if not set
%
%   T_ref = the measured time of the reference car with the reference
%   controller on this path (set by the instructor).  Your score on a path
%   is  min(120, 100 * T_ref / your total time).  Race-day paths have their
%   own T_ref, measured the same way.  (Measured 2026-10-03, catalogue g3.)
    switch lower(string(name))
        case "drag",      tref = 10.81;
        case "technical", tref = 29.50;
        case "endurance", tref = 125.73;
        case "wet",       tref = 26.29;
        otherwise,        tref = NaN;
    end
end
