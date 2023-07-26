clear; clc; close all; dbstop if error;

u = udpport("IPV4", "LocalHost", "169.254.103.193", "LocalPort", 8080);
data = read(u, 5, "double");

write(u, "hello", "string", "169.254.158.40", 8080);
