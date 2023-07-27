function [success] = handshake(socket, role, targetIP, port)
%HANDSHAKE Summary of this function goes here
%   Detailed explanation goes here

if ~ismember(role, ["tx", "rx"])
    error("Role has to be 'tx' or 'rx'");
end

if strcmpi(role, "tx")
    write(socket, 1, "uint8", targetIP, port);
    data = read(socket, 1, "uint8");
    if isempty(data)
        success = false;
        return;
    end
    success = true;
    
else
    data = read(socket, 1, "uint8");
    if isempty(data)
        success = false;
        return;
    
    success = true;
    write(socket, 1, "uint8", targetIP, port);
    end
end
end
