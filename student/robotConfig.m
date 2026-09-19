% =========================================================================
% robotConfig.m — Controller Tuning Parameters
% =========================================================================
%
% This file defines tunable hyperparameters for your autonomous controller.
%
% The AI agent can edit this file to tune your controller's behaviour.
%
% RULES:
%   - You may change the VALUES below
%   - You may add new fields for your own controller parameters
%   - Do NOT change vehicle physics — those are fixed in the simulator
%
% HOW TO USE:
%   These values are passed to controller.m as the 'config' argument.
%   Access them inside controller.m with:  config.fieldName
%
% =========================================================================

% --- Look-ahead distance (metres) ---
% Controls how far ahead the controller looks when computing steering.
% Longer look-ahead = smoother but slower cornering response.
% Shorter look-ahead = sharper response but can oscillate.
config.lookaheadDistance = 2.0;

% --- Target speed (m/s) ---
% The speed the controller tries to maintain.
% Maximum allowed by physics: 10 m/s.
% Start conservative — reliability matters more than speed.
config.targetSpeed = 2.5;

% =========================================================================
% Add your own parameters below as your controller evolves.
% Example:
%   config.corneringSpeedReduction = 0.6;   % fraction to reduce speed in corners
%   config.steeringGain = 1.5;              % proportional gain for steering
%   config.brakingLookahead = 5.0;          % distance to start braking before corner
% =========================================================================
