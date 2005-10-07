function [x] = spm_inv_phi(y)
% inverse logistic function
% FORMAT [y] = spm_inv_phi(x)
%
% x   = log((y + 1)./(1 - y));
%___________________________________________________________________________

% apply
%---------------------------------------------------------------------------
x   = log(y./(1 - y));

