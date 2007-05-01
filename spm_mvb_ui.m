function [MVB] = spm_mvb_ui(xSPM,SPM,hReg)
% multivariate Bayes (Baysian decoding of a contrast)
% FORMAT [MVB] = spm_mvb_ui(xSPM,SPM,hReg)
%__________________________________________________________________________


%-Get figure handles and set title
%--------------------------------------------------------------------------
Fmvb = spm_figure('GetWin','MVB');
if isempty(Fmvb)
    Fmvb =  spm_figure('Create','MVB','Multivariate Bayes');
else
    clf
end

%-Get contrast
%--------------------------------------------------------------------------
contrast = SPM.xCon(xSPM.Ic).name;
c        = SPM.xCon(xSPM.Ic).c(:,1);

%-Get VOI name
%--------------------------------------------------------------------------
name   = ['MVB_' spm_input('name','-8','s',contrast)];

%-Get current location {mm}
%--------------------------------------------------------------------------
xyzmm  = spm_results_ui('GetCoords');

%-Specify search volume
%--------------------------------------------------------------------------
str    = sprintf(' at [%.0f,%.0f,%.0f]',xyzmm(1),xyzmm(2),xyzmm(3));
SPACE  = spm_input('Search volume...','0','m',...
		{['Sphere',str],['Box',str],'Image'},['S','B','I']);
Q      = ones(1,size(xSPM.XYZmm,2));

switch SPACE

	case 'S' %-Sphere
	%---------------------------------------------------------------
	D     = spm_input('radius of VOI {mm}','!+1');
	str   = sprintf('%0.1fmm sphere',D);
	j     = find(sum((xSPM.XYZmm - xyzmm*Q).^2) <= D^2);

	case 'B' %-Box
	%---------------------------------------------------------------
	D     = spm_input('box dimensions [k l m] {mm}','!+1');
	str   = sprintf('%0.1f x %0.1f x %0.1f mm box',D(1),D(2),D(3));
	j     = find(all(abs(xSPM.XYZmm - xyzmm*Q) <= D(:)*Q/2));

	case 'I' %-Mask Image
	%---------------------------------------------------------------
	Msk   = spm_select(1,'image','Image defining search volume');
	D     = spm_vol(Msk);
	str   = sprintf('image mask: %s',spm_str_manip(Msk,'a30'));
	XYZ   = D.mat \ [xSPM.XYZmm; ones(1, size(xSPM.XYZmm, 2))];
	j     = find(spm_sample_vol(D, XYZ(1,:), XYZ(2,:), XYZ(3,:),0) > 0);

end

% get explanatory variables (data)
%--------------------------------------------------------------------------
XYZ  = xSPM.XYZmm(:,j);
Y    = spm_get_data(SPM.xY.VY,xSPM.XYZ(:,j));

if ~length(Y)
    warndlg({'No voxels in this VOI';'Please use a larger volume'})
    return
end


%-Get model[s]
%--------------------------------------------------------------------------
str       = {'sparse','smooth','singular','support'};
Ip        = spm_input('model (spatial prior)','!+1','m',str);
priors    = str{Ip};


% MVB defined
%==========================================================================
spm('Pointer','Watch')

%-Get target and confounds
%--------------------------------------------------------------------------
X   = SPM.xX.X;
X0  = X*(speye(length(c)) - c*pinv(c));
try
    X0 = [X0 SPM.xX.K.X0];
end
X   = X*c;

% randomise to check specificity
%--------------------------------------------------------------------------
% R   = speye(size(X0,1)) - X0*pinv(X0);
% X   = spm_phase_shuffle(R*X);

% serial correlations
%--------------------------------------------------------------------------
V   = SPM.xVi.V;

% invert
%==========================================================================
U        = spm_mvb_U(Y,priors,X0,XYZ);
M        = spm_mvb(X,Y,X0,U,V,8);
M.priors = priors;

% assemble results
%--------------------------------------------------------------------------
MVB.contrast = contrast;
MVB.name     = name;
MVB.c        = c;
MVB.M        = M;
MVB.X        = X;
MVB.Y        = Y;
MVB.X0       = X0;
MVB.XYZ      = XYZ;
MVB.V        = V;
MVB.VOX      = xSPM.M;
MVB.xyzmm    = xyzmm;


% display
%==========================================================================
spm_mvb_display(MVB)

% save
%--------------------------------------------------------------------------
if spm_matlab_version_chk('7') >= 0
	save(fullfile(SPM.swd,name),'-V6','MVB')
else
	save(fullfile(SPM.swd,name),'MVB')
end

%-Reset title
%--------------------------------------------------------------------------
spm('FigName',['SPM{',xSPM.STAT,'}: Results']);
spm('Pointer','Arrow')



