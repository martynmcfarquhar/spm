function spm_eeg_invert_display(D,PST,Ndip)
% Displays conditional expectation of response (J)
% FORMAT spm_eeg_invert_display(D,PST,Ndip)
% FORMAT spm_eeg_invert_display(D,XYZ,Ndip)
% D    - 3D structure (ReML estimation of response (J) )
% PST  - perstimulus time (ms) - defaults to the PST of max abs(J)
%      - [Start Stop] (ms)     - invokes a movie of CSD
% XYZ  - dipole location of interest
%
% Ndip - number of dipole to display (default 512)
%__________________________________________________________________________


% Number of dipoles to display
%==========================================================================
try, PST;  catch, PST  = [];  end
try, Ndip, catch, Ndip = 512; end 

% D - SPM data structure
%==========================================================================
model = D.inv{D.val};
try
    disp(model.inverse);
catch
    warndlg('please invert model')
    return
end

% get solution and spatiotemporal basis
%--------------------------------------------------------------------------
J      = model.inverse.J;
T      = model.inverse.T;
qC     = model.inverse.qC;
Is     = model.inverse.Is;
Nd     = model.inverse.Nd;
Nt     = model.inverse.Nt;
pst    = model.inverse.pst;
R2     = model.inverse.R2;
F      = model.inverse.F;

% - project J onto pst
%--------------------------------------------------------------------------
J      = J*T';

% display
%==========================================================================
Fgraph = spm_figure('GetWin','Graphics');
figure(Fgraph);clf
vert   = model.mesh.tess_mni.vert;

% movie
%--------------------------------------------------------------------------
if length(PST) == 2
    
    
    % get signficant voxels
    %----------------------------------------------------------------------
    Nb     = 170;
    [i j1] = min(abs(pst - PST(1)));
    [i j2] = min(abs(pst - PST(2)));
    jt     = fix(linspace(j1,j2,Nb));
    J      = abs(J(:,jt));
    Z      = max(J,[],2)./(Nt*sqrt(qC));
    [T j]  = sort(-Z);
    js     = j(1:Ndip);
    
    J      = J(js,:);
    XYZ    = vert(Is(js),:)';
    Jmax   = max(max(J));
    Jmin   = min(min(J));
    XYZ    = [XYZ [ones(1,Nb)*(-128); ([1:Nb] - 100); ones(1,Nb)*(-64)]];
    
    % MIP
    %----------------------------------------------------------------------
    subplot(2,1,1)
    for j = 1:Nb
        SCL      = ones(Nb,1)*Jmin;
        SCL(1:j) = Jmax;
        figure(Fgraph)
        spm_mip([J(:,j); SCL],XYZ,6);
        axis image
        title({sprintf('PPM at %i most signficant voxels',Ndip),...
               sprintf('from %i to %i ms',fix(PST(1)),fix(PST(2)))})
        drawnow
    end
    return
end

% maximum response at XYZ
%--------------------------------------------------------------------------
if length(PST) == 3
    [i js] = min(sum([vert(Is,1) - PST(1), ...
                      vert(Is,2) - PST(2), ...
                      vert(Is,3) - PST(3)].^2,2));
    [i jt] = max(abs(J(js,:)));
    
% maximum response at PST
%--------------------------------------------------------------------------
elseif length(PST) == 1
    [i jt] = min(abs(pst - PST));
    [i js] = max(abs(J(:,jt)));
    
% maximum response and confidence intervals
%--------------------------------------------------------------------------
else
    [i js] = max(max(abs(J),[],2));
    [i jt] = max(abs(J(js,:)));
end
Jt    = J(js,:);                     % over time
ci    = Nt*sqrt(qC(js))*1.64;
Js    = J(:,jt);                     % over sources
Jmax  = abs(sparse(Is,1,Js,Nd,1));
PST   = fix(pst(jt));
XYZ   = fix(vert(Is(js),:));


% response over time
%--------------------------------------------------------------------------
subplot(2,1,1)
plot(pst,Jt,pst,Jt + ci,':',pst,Jt - ci,':',[PST PST],[-4 4]*ci)
xlabel('time  ms')
title({'estimated response (90% intervals)', ...
       sprintf('at %i, %i, %i mm',XYZ(1),XYZ(2),XYZ(3))})
axis square

% PPM
%==========================================================================
subplot(2,1,2)
Z     = abs(Js)./(Nt*sqrt(qC));
[T i] = sort(-Z);
try
    i = i(1:Ndip);
end
PP    = fix(100*(1 - spm_Ncdf(T(i(end)))));

spm_mip(Jmax(Is(i)),vert(Is(i),:)',6);
axis image
title({sprintf('PPM at %i ms (%i percent confidence)',PST,PP), ...
       sprintf('%i dipoles',length(i)), ...
       sprintf('Variance explained %.2f (percent)',R2), ...
       sprintf('log-evidence = %.1f',F)})
drawnow

