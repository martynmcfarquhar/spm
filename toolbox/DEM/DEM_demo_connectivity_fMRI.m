function DEM_demo_connectivity_fMRI
% Demonstration of DCM for fMRI�CSD with hierarchical constraints
%__________________________________________________________________________
% This demonstration routine illustrates the inversion of resting state
% fMRI timeseries using a generative model of the adjacency matrix. This
% model is based upon an embedding space of dimensions the in which the
% (log) connectivity among nodes is a (radial basis) function of their
% metric separation. This generative model of connectivity requires a
% hierarchical constraints on the edges and therefore uses the expectation
% aand maximisation step of dynamic expectationmaximisation. Here, the
% hidden causes at the first level are the effective connectivity and the
% hidden causes at the second level are the locations in embedding states.
%
% Simulated timeseries are generated and inverted under typical priors.
% This routine that performs a model space search over precisions on the
% hierarchical constraints and the dimensionality of the embedding space.
% This illustrates: (i) the increase in model evidence afforded by
% hierarchical constraints (when they are true) and (ii) the optimal
% prior precision that reflects the amplitude of random variations in
% connectivity about the constraints. (iii) Finally,the search over moral
% dimension illustrates how Bayesian model comparison can identify the
% dimensionality of the metric space generating hierarchical connectivity.
% 
% The model space search can take about 20 min and is enabled by deleting
% the return command in the script.
%__________________________________________________________________________
% Copyright (C) 2010 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: DEM_demo_connectivity_fMRI.m 5817 2013-12-23 19:01:36Z karl $

% Simulate timeseries
%==========================================================================
rng('default')

% DEM Structure: create random inputs
% -------------------------------------------------------------------------
ED    = 3;                               % embedding dimensional
T     = 1024;                            % number of observations (scans)
TR    = 2;                               % repetition time or timing
n     = 6;                               % number of regions or nodes
t     = (1:T)*TR;                        % observation times
% v     = randn(ED,n)/8;                 % location in scaling space
% [u s] = spm_svd(v'*v);                 % in orthogonal coordinates
% v     = sqrt(s)*u';


% emprical (MAP) esimates
% -------------------------------------------------------------------------
v = [
   -0.1906    0.2706    0.3484   -0.3860   -0.5534   -0.4246
    0.1577   -0.1542   -0.6075   -0.1325   -0.3871   -0.2227
   -0.0865   -0.0811    0.4158    0.1186    0.0111   -0.1946
    0.1530   -0.1626   -0.0782   -0.2557    0.6035   -0.2670];

v = v(1:ED,1:n);

% priors
% -------------------------------------------------------------------------
options.nmax       = 8;                % effective number of notes

options.two_state  = 0;
options.induced    = 1;
options.stochastic = 0;
options.nonlinear  = 0;
options.embedding  = ED;
options.backwards  = 0;
options.precision  = 6;
options.Nmax       = 64;

A   = ones(n,n);
B   = zeros(n,n,0);
C   = zeros(n,n);
D   = zeros(n,n,0);


% true parameters (reciprocal connectivity)
% -------------------------------------------------------------------------
[pE,pC,x]  = spm_dcm_fmri_priors(A,B,C,D,options);
pP         = spm_dcm_fmri_graph_gen([],v,pE);
pP.A       = pP.A + randn(size(pP.A))*exp(-4); disp(pP.A)
pP.C       = eye(n,n);
pP.transit = randn(n,1)*exp(-4);

% simulate response to endogenous fluctuations
%==========================================================================

% integrate states
% -------------------------------------------------------------------------
U.u  = spm_rand_mar(T,n,1/2)/4;      % endogenous fluctuations
U.dt = TR;
M.f  = 'spm_fx_fmri';
M.x  = x;
x    = spm_int_J(pP,M,U);

% haemodynamic observer
% -------------------------------------------------------------------------
for i = 1:T
    y(i,:) = spm_gx_fmri(spm_unvec(x(i,:),M.x),[],pP)';
end

% observation noise process
% -------------------------------------------------------------------------
e    = spm_rand_mar(T,n,1/2)/8;

% show simulated response
%--------------------------------------------------------------------------
i = 1:256;
spm_figure('Getwin','Figure 1'); clf
subplot(2,2,1)
plot(t(i),U.u(i,:))
title('Endogenous fluctuations','FontSize',16)
xlabel('Time (seconds)')
ylabel('Amplitude')
axis square

subplot(2,2,2), hold off
plot(t(i),x(i,n + 1:end),'c'), hold on
plot(t(i),x(i,1:n)), hold off
title('Hidden states','FontSize',16)
xlabel('Time (seconds)')
ylabel('Amplitude')
axis square

subplot(2,2,3)
plot(t(i),y(i,:),t(i),e(i,:),':')
title('Hemodynamic response and noise','FontSize',16)
xlabel('Time (seconds)')
ylabel('Amplitude')
axis square

% nonlinear system identification (DCM for CSD) over subjects
%==========================================================================
DCM.options = options;

DCM.a    = ones(n,n);
DCM.b    = zeros(n,n,0);
DCM.c    = zeros(n,1);
DCM.d    = zeros(n,n,0);

DCM.Y.y  = y + e;
DCM.Y.dt = TR;
DCM.U.u  = zeros(T,1);
DCM.U.dt = TR;

% nonlinear system identification (Variational Laplace)
% =========================================================================

% classical
% -------------------------------------------------------------------------
DCM  = spm_dcm_fmri_csd(DCM);


% post hoc esimatation of scaling space
% -------------------------------------------------------------------------
% [u s]         = spm_svd(DCM.Ep.A);
% DCM.options.v = sqrt(s)*u';

% hierarchical
% -------------------------------------------------------------------------
DEM  = spm_dcm_fmri_csd_DEM(DCM);


% summary
% -------------------------------------------------------------------------
spm_figure('Getwin','Figure 2'); clf

j   = find(pP.A);
Ep  = DEM.Ep.A(j);
Qp  = DCM.Ep.A(j);
Cp  = DEM.Cp(j,j);
Pp  = pP.A(:);

subplot(2,1,1); hold off
spm_plot_ci(Ep(:),Cp), hold on
bar(Pp,1/2,'k'), hold off
title('True and MAP connections','FontSize',16)
axis square

j   = find(eye(n,n));

subplot(2,1,2); cla
plot(pP.A(:),DEM.Ep.A(:),'b.','MarkerSize',32),    hold on
plot(pP.A(:),DCM.Ep.A(:),'c.','MarkerSize',16),    hold on
plot(pP.A(j),DEM.Ep.A(j),'r.','MarkerSize',32), hold on
plot(pP.A(j),DCM.Ep.A(j),'m.','MarkerSize',16), hold on
plot([-0.2 .3],[-0.2 .3],'k:'), hold on
title('MAP vs. true','FontSize',16)
xlabel('true')
ylabel('estimate')
axis square
legend ('hierarchical','conventional')


% proximity space
%==========================================================================
spm_figure('Getwin','Figure (MAP)'); clf
u      = spm_unvec(DEM.DEM.qU.v{3},v);

subplot(2,1,1)
spm_dcm_graph_functional(u)
title('Estimated','FontSize',16)

subplot(2,1,2)
spm_dcm_graph_functional(v)
title('True','FontSize',16)

% eturn if called as a demo - otherwise perform model search
%--------------------------------------------------------------------------
if ~exist('DCM_stochastic.mat','file')
    return
end


% search over precision of hidden causes
%==========================================================================
V     = 4:8;
F     = [];
R     = [];
for i = 1:length(V)
    
    % invert
    %======================================================================
    DCM.options.precision = V(i);
    DCM.options.embedding = ED;
    DEM = spm_dcm_fmri_csd_DEM(DCM);
    
    % RMS
    % ---------------------------------------------------------------------
    R(end + 1,1) = paper_rms(DEM.Ep.A,pP.A);
    
    % free energy
    % ---------------------------------------------------------------------
    F(end + 1,1) = DEM.F;
    
    
    % repeat with precise full priors
    %======================================================================
    DCM.options.embedding = 0;
    DEM = spm_dcm_fmri_csd_DEM(DCM);
    
    % correlation
    % ---------------------------------------------------------------------
    R(end,2)     = paper_rms(DEM.Ep.A,pP.A);
    
    % free energy
    % ---------------------------------------------------------------------
    F(end,2)     = DEM.F;
    
end


% summary
% -----------------------------------------------------------------
spm_figure('Getwin','Figure 3'); clf

subplot(2,2,1);
bar(V,F - min(F(:)) + 16)
title('log-evidence and precision','FontSize',16)
xlabel('prior log-precision')
ylabel('free energy')
axis square

subplot(2,2,3);
bar(V,R), hold on
plot(V,V*0 + 0.05,'r:'), hold off
title('accuracy','FontSize',16)
xlabel('prior log-precision')
ylabel('root mean square error')
axis square
legend ('D > 0','D = 0')


% search over embedding dimension
%==========================================================================
D     = 0:4;
DF    = [];
DR    = [];
for i = 1:length(D)

    % invert
    %======================================================================
    DCM.options.precision = 6;
    DCM.options.embedding = D(i);
    DEM = spm_dcm_fmri_csd_DEM(DCM);
        
    % RMS
    % ---------------------------------------------------------------------
    DR(end + 1,1)   = paper_rms(DEM.Ep.A,pP.A);
    
    % free energy
    % ---------------------------------------------------------------------
    DF(end + 1,1)   = DEM.F;
    
end
    

% summary
% -----------------------------------------------------------------
spm_figure('Getwin','Figure 3');

RF  = DF - min(DF(:)) + 16;

subplot(2,2,2); cla
bar(D,RF),                                              hold on
plot(D,D - D + max(RF),'r',D,D - D + max(RF) - 3,'r:'), hold off
title('log-evidence and embedding','FontSize',16)
xlabel('embedding dimension')
ylabel('free energy')
axis square

subplot(2,2,4);
bar(D,DR),               hold on
plot(D,D*0 + 0.05,'r:'), hold off
title('accuracy','FontSize',16)
xlabel('embedding dimension')
ylabel('root mean square error')
axis square


% load empirical DCM for search over precision and embedding dimension
%==========================================================================
try
    load DCM_stochastic
catch
    return
end

n     = DCM.n;
DCM.a = ones(n,n);
DCM.b = zeros(n,n,0);
DCM.d = zeros(n,n,0);
DCM.options = options;

% classical esimatation of scaling space
% -------------------------------------------------------------------------
% DCM           = spm_dcm_fmri_csd(DCM);
% [u s]         = spm_svd(DCM.Ep.A);
% DCM.options.v = sqrt(s)*u';


% search over precision of hidden causes
%==========================================================================
eF    = [];
for i = 1:length(V)
    
    % invert
    %======================================================================
    DCM.options.precision = V(i);
    DCM.options.embedding = 2;
    DEM = spm_dcm_fmri_csd_DEM(DCM);
    
    % free energy
    % ---------------------------------------------------------------------
    eF(end + 1,1) = DEM.F;
    
    
    % repeat with precise full priors
    %======================================================================
    DCM.options.embedding = 0;
    DEM = spm_dcm_fmri_csd_DEM(DCM);
    
    % free energy
    % ---------------------------------------------------------------------
    eF(end,2) = DEM.F;
    
end


% summary
% -------------------------------------------------------------------------
spm_figure('Getwin','Figure 4'); clf

subplot(2,2,1);
bar(V,eF - min(eF(:)) + 16)
title('precision (empirical)','FontSize',16)
xlabel('prior precision ')
ylabel('free energy')
axis square


% search over embedding dimension
%==========================================================================
eDF   = [];
for i = 1:length(D)

    % invert
    %======================================================================
    DCM.options.precision = 6;
    DCM.options.embedding = D(i);
    DEM = spm_dcm_fmri_csd_DEM(DCM);
            
    % free energy
    % ---------------------------------------------------------------------
    eDF(end + 1,1)   = DEM.F;
    
end
    

% summary
% -------------------------------------------------------------------------
spm_figure('Getwin','Figure 4');

eRF  = eDF - min(eDF(:)) + 16;

subplot(2,2,2); cla
bar(D,eRF),                                               hold on
plot(D,D - D + max(eRF),'r',D,D - D + max(eRF) - 3,'r:'), hold off
title('embedding (empirical)','FontSize',16)
xlabel('embedding dimension')
ylabel('free energy')
axis square

% get functional space
%==========================================================================
spm_figure('Getwin','Figure 5'); clf

subplot(2,1,1)
title('Scaling spaces','FontSize',16)
u = spm_unvec(DEM.DEM.qU.v{3},DEM.DEM.M(3).v);
spm_dcm_graph_functional(u)


    
% and save matlab file
% -------------------------------------------------------------------------
save paper



return


function rms = paper_rms(A,B)
% Root mean square difference in (% extrinsic connectivity)
% -------------------------------------------------------------------------
D   = A - B;
% D   = D - diag(diag(D));
D   = D(find(D));
rms = sqrt(mean(D.^2));

return



% NOTES: illustrate the ill-posed nature of the problem
%==========================================================================
M     = DCM.M;
U     = DCM.U;
M.x   = zeros(n,5); 

nA    = 32;
pA    = linspace(-.4,.4,nA);
Y     = [];
P     = [];
for i = 1:nA
    for j = 1:nA
        
        % map from parameter space to data space
        %------------------------------------------------------------------
        pp           = pP;
        pp.A(1,2)    = pA(i);
        pp.A(2,1)    = pA(j);
        Y(:,end + 1) = spm_vec(spm_csd_fmri_mtf(pp,M,U));
        P(:,end + 1) = spm_vec(pp.A);
        
    end
end

% distance measures
%--------------------------------------------------------------------------
Up      = P([2 (n + 1)],:)';
[Uy Sy] = spm_svd(spm_detrend(Y'));
Uy      = real(Uy);

Cp    = Up;
for i = 1:2
    Cp(:,i) = Up(:,i) - min(Up(:,i));
    Cp(:,i) = 0.001 + Cp(:,i)./(max(Cp(:,i))*1.1);
end


% graphics
%--------------------------------------------------------------------------
spm_figure('Getwin','Figure 6'); clf

subplot(2,1,1), cla
for  i = 1:nA*nA
    plot(Up(i,1),Up(i,2),'.','Markersize',32,'Color',[1/2 Cp(i,1) Cp(i,2)]), hold on
end
axis square
title('Parameter space','FontSize',16)
xlabel('Forward connection')
ylabel('Backward connection')
axis square

subplot(2,1,2), cla
for  i = 1:nA*nA
    plot3(Uy(i,1),Uy(i,2),Uy(i,3),'.','Markersize',32,'Color',[1/2 Cp(i,1) Cp(i,2)]), hold on
end
axis square
title('Data space','FontSize',16)
xlabel('1st PC')
ylabel('2nd PC')
ylabel('3rd PC')
axis square

return


