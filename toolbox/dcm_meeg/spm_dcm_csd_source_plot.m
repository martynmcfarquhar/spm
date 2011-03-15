function [G] = spm_dcm_csd_source_plot(model,s,pF)
% Spectral response (G) of a single source neural mass model
% FORMAT [G] = spm_dcm_csd_source_plot(model,s)
%
% model - 'ERP', 'SEP', 'CMC', 'LFP', 'NMM' or 'MFM'
% s     - indices of hidden neuronal states to plot
% pF    - fixed parameters
%
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_csd_source_plot.m 4232 2011-03-07 21:01:16Z karl $


% Create model
%==========================================================================
try, s; catch,s = [1 2 3 7]; end

% prior moments on parameters
%--------------------------------------------------------------------------
pE = spm_dcm_neural_priors({0,0,0},{},1,model);


% intial states and equations of motion
%--------------------------------------------------------------------------
[x,f] = spm_dcm_x_neural(pE,model);

% create DCM
%--------------------------------------------------------------------------
M.f  = f;
M.x  = x;
M.n  = length(spm_vec(x));


% compute spectral density
%==========================================================================

% frequencies of interest
%--------------------------------------------------------------------------
N    = 256;
dt   = 1/N;
If   = 1:N/2;
f    = [1:N/2]';
w    = f(If);

% exogenous (neuronal) inputs
%--------------------------------------------------------------------------
M.u  = 0;

% fixed parameters
%--------------------------------------------------------------------------
try, M.pF  = pF; end

% spectrum of innovations (Gu)
%--------------------------------------------------------------------------
Gu   = f.^(-1)*8;


% get delay operator
%--------------------------------------------------------------------------
try
    [fx dfdx D] = feval(M.f,M.x,M.u,pE,M);
catch
    D = 1;
end

% augment and bi-linearise (with delays)
%--------------------------------------------------------------------------
[M0,M1,L] = spm_bireduce(M,pE,D);

% compute modulation transfer function using FFT of the kernels
%--------------------------------------------------------------------------
[K0,K1]   = spm_kernels(M0,M1,L,N,dt);
[N,nc,nu] = size(K1);


% [cross]-spectral density
%--------------------------------------------------------------------------
ns    = length(s);
G     = zeros(N/2,ns,ns);
for i = 1:ns
    for j = i:ns
        for k = 1:nu
            Si       = fft(K1(:,s(i),k));
            Sj       = fft(K1(:,s(j),k));
            Gij      = Si.*conj(Sj);
            Gij      = Gij([1:N/2] + 1).*Gu;
            G(:,i,j) = G(:,i,j) + Gij;
        end
        
        % Graphics
        %==================================================================
        subplot(ns,ns,(i - 1)*ns + j)
        plot(abs(G(:,i,j)))
        xlabel('frequency')
        axis square
        
    end
end
drawnow






