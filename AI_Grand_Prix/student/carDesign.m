function car = carDesign()
% CARDESIGN  Choose the parts of your car.  ⭐ YOUR FILE (with controller.m)
%
%   Budget: 80 credits.  An unknown option or an over-budget car cannot race.
%   Run  garage  to see your car, its numbers and its cost.
%
%   Part      Options (cost)                                   Changes
%   motor     "2kW" (10)   "3.5kW" (20)    "5.5kW" (35)        acceleration (P in eq. 2)
%   battery   "45Wh" (10)  "70Wh" (18)     "100Wh" (30)        energy for endurance (eq. 8)
%   tyres     "hard" (5)   "medium" (12)   "soft" (20)         grip mu vs rolling loss C_rr (eqs. 4-6)
%   aero      "none" (0)   "lowdrag" (10)  "downforce" (20)    drag vs downforce (eqs. 3, 6)
%   gearing   "short"      "medium"        "long"   (free)     pull from standstill vs top speed (eq. 2)
%
%   Every part except gearing adds mass (eq. 1).  Full numbers: PHYSICS.md.
%
%   RULE: before you change a part, write down the trade-off you expect
%   (what gets better, what gets worse, on which path) - then test it.

    car.team    = "Team Name";        % shown on race day
    car.colour  = [0.95 0.35 0.10];   % RGB, each 0-1
    car.motor   = "3.5kW";
    car.battery = "70Wh";
    car.tyres   = "medium";
    car.aero    = "lowdrag";
    car.gearing = "medium";
end
