function [f,J,Q] = spm_fx_sep(x,u,P,M)
% state equations for a neural mass model of erps
% FORMAT [f,J,D] = spm_fx_sep(x,u,P,M)
% FORMAT [f,J]   = spm_fx_sep(x,u,P,M)
% FORMAT [f]     = spm_fx_sep(x,u,P,M)
% x      - state vector
%   x(:,1) - voltage (spiny stellate cells)
%   x(:,2) - voltage (pyramidal cells) +ve
%   x(:,3) - voltage (pyramidal cells) -ve
%   x(:,4) - current (spiny stellate cells)    depolarizing
%   x(:,5) - current (pyramidal cells)         depolarizing
%   x(:,6) - current (pyramidal cells)         hyperpolarizing
%   x(:,7) - voltage (inhibitory interneurons)
%   x(:,8) - current (inhibitory interneurons) depolarizing
%   x(:,9) - voltage (pyramidal cells)
%
% f        - dx(t)/dt  = f(x(t))
% J        - df(t)/dx(t)
% D        - delay operator dx(t)/dt = f(x(t - d))
%                                    = D(d)*f(x(t))
%
% Prior fixed parameter scaling [Defaults]
%
%  M.pF.E = [32 16 4];           % extrinsic rates (forward, backward, lateral)
%  M.pF.G = [1 1/2 1/4 1/4]*256; % intrinsic rates (g1, g2 g3, g4)
%  M.pF.D = [2 32];              % propagation delays (intrinsic, extrinsic)
%  M.pF.H = [4 32];              % receptor densities (excitatory, inhibitory)
%  M.pF.T = [2 8];               % synaptic constants (excitatory, inhibitory)
%  M.pF.R = [1 1/2];             % parameter of static nonlinearity
%
% This is just a faster version of spm_fx_erp
%
%__________________________________________________________________________
% David O, Friston KJ (2003) A neural mass model for MEG/EEG: coupling and
% neuronal dynamics. NeuroImage 20: 1743-1755
%___________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_fx_sep.m 4232 2011-03-07 21:01:16Z karl $
 
 
% get dimensions and configure state variables
%--------------------------------------------------------------------------
n  = length(P.A{1});         % number of sources
x  = spm_unvec(x,M.x);       % neuronal states
 
% [default] fixed parameters
%--------------------------------------------------------------------------
E  = [32 16 4];              % extrinsic rates (forward, backward, lateral)
G  = [1 1 1/4 1/4]*128;      % intrinsic rates (g1 g2 g3 g4)
D  = [2 32];                 % propagation delays (intrinsic, extrinsic)
H  = [4 32];                 % receptor densities (excitatory, inhibitory)
T  = [4 8];                  % synaptic constants (excitatory, inhibitory)
R  = [1 0];                  % parameters of static nonlinearity
   
% [specified] fixed parameters
%--------------------------------------------------------------------------
try, E  = M.pF.E; end
try, G  = M.pF.G; end
try, D  = M.pF.D; end
try, H  = M.pF.H; end
try, T  = M.pF.T; end
try, R  = M.pF.R; end
 
 
% test for free parameters on intrinsic connections
%--------------------------------------------------------------------------
try
    G = G.*exp(P.G);
end
G     = ones(n,1)*G;
 
% exponential transform to ensure positivity constraints
%--------------------------------------------------------------------------
A{1}  = exp(P.A{1})*E(1);
A{2}  = exp(P.A{2})*E(2);
A{3}  = exp(P.A{3})*E(3);
C     = exp(P.C);
 
% intrinsic connectivity and parameters
%--------------------------------------------------------------------------
Te    = T(1)*exp(-P.Q + P.T)/1000;     % excitatory time constants
Ti    = T(2)*exp(-P.Q)/1000;           % inhibitory time constants
Hi    = H(2)*exp( P.Q);                % inhibitory receptor density
He    = H(1)*exp( P.Q + P.H);          % excitatory receptor density
 
% pre-synaptic inputs: s(V)
%--------------------------------------------------------------------------
R(1)  = R(1).*exp(P.S(1));
R(2)  = R(2)  + P.S(2);
S     = 1./(1 + exp(-R(1)*(x - R(2)))) - 1./(1 + exp(R(1)*R(2)));
 
% exogenous input
%==========================================================================
U     = C*u(:);
 
 
% State: f(x)
%==========================================================================
 
% Supra-granular layer (inhibitory interneurons): Voltage & depolarizing current
%--------------------------------------------------------------------------
f(:,7) = x(:,8);
f(:,8) = (He.*((A{2} + A{3})*S(:,9) + G(:,3).*S(:,9)) - 2*x(:,8) - x(:,7)./Te)./Te;
 
% Granular layer (spiny stellate cells): Voltage & depolarizing current
%--------------------------------------------------------------------------
f(:,1) = x(:,4);
f(:,4) = (He.*((A{1} + A{3})*S(:,9) + G(:,1).*S(:,9) + U) - 2*x(:,4) - x(:,1)./Te)./Te;
 
% Infra-granular layer (pyramidal cells): depolarizing current
%--------------------------------------------------------------------------
f(:,2) = x(:,5);
f(:,5) = (He.*((A{2} + A{3})*S(:,9) + G(:,2).*S(:,1)) - 2*x(:,5) - x(:,2)./Te)./Te;
 
% Infra-granular layer (pyramidal cells): hyperpolarizing current
%--------------------------------------------------------------------------
f(:,3) = x(:,6);
f(:,6) = (Hi.*(G(:,4).*S(:,7) + U/8) - 2*x(:,6) - x(:,3)./Ti)./Ti;
 
% Infra-granular layer (pyramidal cells): Voltage
%--------------------------------------------------------------------------
f(:,9) = x(:,5) - x(:,6);
f      = spm_vec(f)*1.1;
 
if nargout == 1; return, end
 
 
% Jacobian: J = df(x)/dx
%==========================================================================
J  = spm_diff('spm_fx_sep',x,u,P,M,1);
 
if nargout == 2; return, end
 
 
% delays
%==========================================================================
% Delay differential equations can be integrated efficiently (but
% approximately) by absorbing the delay operator into the Jacobian
%
%    dx(t)/dt     = f(x(t - d))
%                 = Q(d)f(x(t))
%
%    J(d)         = Q(d)df/dx
%--------------------------------------------------------------------------
 
De = D(2).*exp(P.D)/1000;
Di = D(1)/1000;
De = (1 - speye(n,n)).*De;
Di = (1 - speye(9,9)).*Di;
De = kron(ones(9,9),De);
Di = kron(Di,speye(n,n));
D  = Di + De;
 
% Implement: dx(t)/dt = f(x(t - d)) = inv(1 + D.*dfdx)*f(x(t))
%                     = Q*f = Q*J*x(t)
%--------------------------------------------------------------------------
Q  = inv(speye(length(J)) + D.*J);
 
 
return
 
% notes and alpha function (kernels)
%==========================================================================
% x   = t*exp(k*t)
% x'  = exp(k*t) + k*t*exp(k*t)
%     = exp(k*t) + k*x
% x'' = 2*k*exp(k*t) + k^2*t*exp(k*t)
%     = 2*k*(x' - k*x) + k^2*x
%     = 2*k*x' - k^2*x