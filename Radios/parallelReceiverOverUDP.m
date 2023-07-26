clear; clc; close all; dbstop if error;

setPath();

%% PARAMETRAGE

MyIP = "169.254.176.201";
targetIP = "169.254.158.40";
port = 8080;


udpPort = udpport("IPV4", "LocalHost", MyIP, "LocalPort", port);

imgRxOSDMOverUDP(udpPort, targetIP, port);