function joinRace(serverIP, serverPort)
% JOINRACE  Connect to the AI Grand Prix championship network race server.
%
%   ╔══════════════════════════════════════════════════════════╗
%   ║  PHASE 7 — Network Race (Optional / Post-Workshop MVP)   ║
%   ║  This file is a STUB. TCP networking not yet implemented.║
%   ╚══════════════════════════════════════════════════════════╝
%
%   USAGE (when network race is enabled by instructor):
%     joinRace                         % uses defaults: localhost:9000
%     joinRace('192.168.1.100', 9000)
%
%   WHAT THIS WILL DO (once implemented):
%     1. Connect to the instructor's TCP race server
%     2. Register this team's controller
%     3. In a loop: receive obs → call controller(obs,config) → send command
%     4. Display live race updates from the server
%
%   Your controller.m does not need to change for the network race.
%   The obs struct and command format are identical.
%
%   See also: practiceRace, controller.m

    if nargin < 1, serverIP   = 'localhost'; end
    if nargin < 2, serverPort = 9000;        end

    % ------------------------------------------------------------------ %
    %  Setup                                                              %
    % ------------------------------------------------------------------ %
    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'));
    addpath(fullfile(thisDir, 'student'));

    config = struct();
    try
        config = robotConfig();
    catch
    end

    % ------------------------------------------------------------------ %
    %  Stub message                                                       %
    % ------------------------------------------------------------------ %
    fprintf('\n');
    fprintf('========================================================\n');
    fprintf('  AI GRAND PRIX — Network Race Client\n');
    fprintf('  Server : %s:%d\n', serverIP, serverPort);
    fprintf('========================================================\n');
    fprintf('\n');
    fprintf('  ⚠  Network race (Phase 7) is not yet implemented.\n');
    fprintf('\n');
    fprintf('  This function will:\n');
    fprintf('    1. Open a TCP socket to the instructor server\n');
    fprintf('    2. Send your team name for registration\n');
    fprintf('    3. Loop: recv obs JSON → controller() → send command JSON\n');
    fprintf('\n');
    fprintf('  Your controller.m interface is UNCHANGED for the network race.\n');
    fprintf('  When Phase 7 is ready, replace this stub with the TCP client.\n');
    fprintf('\n');
    fprintf('  For now: use practiceRace() to develop and test your controller.\n');
    fprintf('========================================================\n\n');

    % ------------------------------------------------------------------ %
    %  TODO: TCP implementation skeleton (for future expansion)          %
    % ------------------------------------------------------------------ %
    %
    %  t = tcpclient(serverIP, serverPort, 'Timeout', 5);
    %
    %  % Register
    %  teamName = input('Enter your team name: ', 's');
    %  writeline(t, jsonencode(struct('type', 'register', 'team', teamName)));
    %
    %  % Race loop
    %  while true
    %      raw    = readline(t);
    %      msg    = jsondecode(raw);
    %      if strcmp(msg.type, 'obs')
    %          obs.position      = msg.position;
    %          obs.heading       = msg.heading;
    %          obs.speed         = msg.speed;
    %          obs.previewPoints = msg.previewPoints;
    %          obs.trackWidth    = msg.trackWidth;
    %          obs.dt            = msg.dt;
    %          cmd               = controller(obs, config);
    %          writeline(t, jsonencode(cmd));
    %      elseif strcmp(msg.type, 'finish')
    %          fprintf('Lap complete! Time: %.2f s\n', msg.lapTime);
    %          break;
    %      end
    %  end
    %  clear t;

end
