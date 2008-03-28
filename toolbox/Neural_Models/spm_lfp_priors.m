function [varargout] = spm_lfp_priors(A,B,C,L,J)
% prior moments for a neural mass model of ERPs
% FORMAT [pE,pC] = spm_lfp_priors(A,B,C,L,J)
% FORMAT [M]     = spm_lfp_priors(A,B,C,L,J)
% FORMAT           spm_lfp_priors(A,B,C,L,J)
%
% A{3},B{m},C    - binary constraints on extrinsic connectivity
% L              - lead field structure or number of sources
% J              - contributing sources
%
% pE - prior expectation
%
% synaptic parameters
%--------------------------------------------------------------------------
%    pE.T - synaptic time constants
%    pE.H - synaptic densities
%    pE.R - activation function parameters
%
% spatial parameters
%--------------------------------------------------------------------------
%    pE.Lpos - position
%    pE.L    - moment (orientation), mode or gain parameters:
%    pE.J    - contributing states
%
% connectivity parameters
%--------------------------------------------------------------------------
%    pE.A - extrinsic - coupling
%    pE.B - extrinsic - trial-dependent
%    pE.C - extrinsic - stimulus input
%    pE.G - intrinsic
%    pE.D - extrinsic delays
%    pE.I - intrinsic delays
%
% input and noise parameters
%--------------------------------------------------------------------------
%    pE.a - amplitude of AR component
%    pE.b - amplitude of IID component
%    pE.c - amplitude of noise (spectral density)
%
%--------------------------------------------------------------------------
%
% pC - prior covariances: cov(spm_vec(pE))
%
% Because priors are specified under log normal assumptions, most
% parameters are simply scaling coefficients with a prior expectation
% and variance of one.  After log transform this renders pE = 0 and
% pC = 1;  The prior expectations of what they scale are specified in
% spm_lfp_fx
%__________________________________________________________________________
%
% David O, Friston KJ (2003) A neural mass model for MEG/EEG: coupling and
% neuronal dynamics. NeuroImage 20: 1743-1755
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_lfp_priors.m 1277 2008-03-28 18:36:49Z karl $
 
% defaults
%--------------------------------------------------------------------------
if nargin < 3                                       % a single source model
    A   = {0 0 0};
    B   = {0};
    C   = 1;
end
n   = size(C,1);                                    % number of sources
if nargin < 4
    L   = n;
end
 
% disable log zero warning
%--------------------------------------------------------------------------
warning('off','MATLAB:log:logOfZero');
 
 
% parameters for electromagnetic forward model
%==========================================================================
[E pC] = spm_L_priors(L);
 
% source-specific contribution to LFP
%--------------------------------------------------------------------------
try, J; catch, J  = sparse(1,[1 7 9],[0.2 0.2 0.6],1,13); end
 
% source-specific contribution to LFP
%--------------------------------------------------------------------------
E.J   = J;                 V.J = J/64;               % contributing states
 
 
% parameters for neural-mass forward model
%==========================================================================
 
% sigmoid parameters
%--------------------------------------------------------------------------
E.R   = [0 0];             V.R = [1 1]/8;
 
% set intrinsic [excitatory] time constants
%--------------------------------------------------------------------------
E.T   = log(ones(n,2));    V.T = ones(n,2)/8;      % time constants
E.H   = log(ones(n,1));    V.H = ones(n,1)/16;     % synaptic density

% set intrinsic connections
%--------------------------------------------------------------------------
E.G   = log(ones(n,5));    V.G = ones(n,5)/16;     % intrinsic connections
 
 
% set extrinsic connectivity
%--------------------------------------------------------------------------
Q     = sparse(n,n);
for i = 1:length(A)
      A{i} = ~~A{i};
    E.A{i} = log(A{i} + eps);                      % forward
    V.A{i} = A{i}/2;                               % backward
    Q      = Q | A{i};                             % and lateral connections
end
 
for i = 1:length(B)
      B{i} = ~~B{i};
    E.B{i} = 0*B{i};                               % input-dependent scaling
    V.B{i} = B{i}/2;
    Q      = Q | B{i};
end
C      = ~~C;
E.C    = C*32 - 32;                                % where inputs enter
V.C    = C/32;
 
% set endogenous inputs (neuronal) and noise
%--------------------------------------------------------------------------
E.a    = 0;               V.a = 1/16;              % amplitude input AR
E.b    = 0;               V.b = 0;                 % amplitude input IID
E.c    = [0 0];           V.c = [1/16 1/16];       % amplitude noise AR
E.d    = [0 0];           V.d = [1/16 1/16];       % amplitude noise IID
                                                   % specific and common
 
% set delay
%--------------------------------------------------------------------------
E.D    = sparse(n,n);     V.D = Q/16;              % extrinsic delays
E.I    = 0;               V.I = 1/32;              % intrinsic delays
 
% prior covariances
%--------------------------------------------------------------------------
pE     = E;
pV     = spm_vec(V);
pV     = diag(sparse(pV));
pC     = spm_cat(diag({pC,pV}));
 
% prior moments if two arguments
%--------------------------------------------------------------------------
warning('on','MATLAB:log:logOfZero');

if nargout == 2, varargout{1} = pE; varargout{2} = pC; return, end
 
 
% Model specification
%==========================================================================
M.f      = 'spm_fx_lfp';
M.g      = 'spm_gx_erp';
M.x      = sparse(n,13);
M.pE     = pE;
M.pC     = pC;
M.m      = length(B);
M.n      = n*13;
M.l      = size(pE.L,1);
M.IS     = 'spm_int_L';
 
if nargout == 1, varargout{1} = M; return, end
 
% compute impulse response
%--------------------------------------------------------------------------
N       = 128;
U.dt    = 2/1000;
U.u     = sparse(1,1,1/U.dt,N,M.m);
y       = feval(M.IS,M.pE,M,U);
plot([1:N]*U.dt*1000,y)
 
 
return
 
% demo for log-normal pdf
%--------------------------------------------------------------------------
x    = [1:64]/16;
for i = [2 16]
    v = 1/i;
    p = 1./x.*exp(-log(x).^2/(2*v))/sqrt(2*pi*v);
    plot(x,p)
    text(x(16),p(16),sprintf('variance = 1/%i',1/v))
    hold on
end
xlabel('scaling')
ylabel('density')
grid on
hold off
