function course = loadPath(name)
% LOADPATH  Get a practice path by name.
%
%   course = loadPath(name)
%
%   name: "drag" | "technical" | "endurance" | "mud" | "wet"
%
%   See also: practiceRace, buildPath
    switch lower(string(name))
        case {"drag", "c1"},       course = practiceDrag();
        case {"technical", "c2"},  course = practiceTechnical();
        case {"endurance", "c3"},  course = practiceEndurance();
        case {"mud", "c4"},        course = practiceMud();
        case "wet",                course = practiceWet();
        otherwise
            error('loadPath:unknown', 'Unknown path "%s". Use "drag", "technical", "endurance", "mud" or "wet".', name);
    end
end
