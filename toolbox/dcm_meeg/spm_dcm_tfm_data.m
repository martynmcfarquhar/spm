function DCM = spm_dcm_tfm_data(DCM)
% gets cross-spectral density data-features using a wavelet trsnaform
% FORMAT DCM = spm_dcm_tfm_data(DCM)
% DCM    -  DCM structure
% requires
%
%    DCM.xY.Dfile        - name of data file
%    DCM.M.U             - channel subspace
%    DCM.options.trials  - trial to evaluate
%    DCM.options.Tdcm    - time limits
%    DCM.options.Fdcm    - frequency limits
%    DCM.options.D       - Down-sampling
%
% sets
%
%    DCM.xY.pst     - Peristimulus Time [ms] sampled
%    DCM.xY.dt      - sampling in seconds [s] (down-sampled)
%    DCM.xY.U       - channel subspace
%    DCM.xY.y       - cross spectral density over channels
%    DCM.xY.csd     - cross spectral density over channels
%    DCM.xY.erp     - event-related average over channels
%    DCM.xY.It      - Indices of time bins
%    DCM.xY.Ic      - Indices of good channels
%    DCM.xY.Hz      - Frequency bins
%    DCM.xY.code    - trial codes evaluated
%    DCM.xY.Rft     - Wavelet number or ratio of frequency to time
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_tfm_data.m 4768 2012-06-11 17:06:55Z karl $

% Set defaults and Get D filename
%-------------------------------------------------------------------------
try
    Dfile = DCM.xY.Dfile;
catch
    errordlg('Please specify data and trials');
    error('')
end

% ensure spatial modes have been computed (see spm_dcm_csd)
%-------------------------------------------------------------------------
try
    DCM.M.U;
catch
    DCM.M.U = spm_dcm_eeg_channelmodes(DCM.M.dipfit,DCM.options.Nmodes);
end

% load D
%--------------------------------------------------------------------------
try
    D = spm_eeg_load(Dfile);
catch
    try
        [~,f]        = fileparts(Dfile);
        D            = spm_eeg_load(f);
        DCM.xY.Dfile = fullfile(pwd,f);
    catch
        try
            [f,p]        = uigetfile('*.mat','please select data file');
            name         = fullfile(p,f);
            D            = spm_eeg_load(name);
            DCM.xY.Dfile = fullfile(name);
        catch
            warndlg([Dfile ' could not be found'])
            return
        end
    end
end


% Modality 
%--------------------------------------------------------------------------
if ~isfield(DCM.xY, 'modality')
    [mod, list] = modality(D, 0, 1);
    
    if isequal(mod, 'Multimodal')
        qstr = 'Only one modality can be modelled at a time. Please select.';
        if numel(list) < 4
            
            % Nice looking dialog
            %--------------------------------------------------------------
            options         = [];
            options.Default = list{1};
            options.Interpreter = 'none';
            DCM.xY.modality = questdlg(qstr, 'Select modality', list{:}, options);
            
        else
            
            % Ugly but can accomodate more buttons
            %--------------------------------------------------------------
            ind = menu(qstr, list);
            DCM.xY.modality = list{ind};
        end
    else
        DCM.xY.modality = mod;
    end
end

% channel indices (excluding bad channels)
%--------------------------------------------------------------------------
if ~isfield(DCM.xY, 'Ic')
    DCM.xY.Ic  = setdiff(D.meegchannels(DCM.xY.modality), D.badchannels);
end

Ic        = DCM.xY.Ic;
Nm        = size(DCM.M.U,2);
DCM.xY.Ic = Ic;

% options
%--------------------------------------------------------------------------
try, DT    = DCM.options.D;      catch, DT    = 1;             end
try, trial = DCM.options.trials; catch, trial = D.nconditions; end
try, Rft   = DCM.options.Rft;    catch, Rft   = 4;             end

% check data are not oversampled (< 4ms)
%--------------------------------------------------------------------------
if DT/D.fsample < 0.004
    DT            = ceil(0.004*D.fsample);
    DCM.options.D = DT;
end


% get peristimulus times
%--------------------------------------------------------------------------
try
    
    % time window and bins for modelling
    %----------------------------------------------------------------------
    DCM.xY.Time = 1000*D.time;               % Samples (ms)
    T1          = DCM.options.Tdcm(1);
    T2          = DCM.options.Tdcm(2);
    [~, T1]     = min(abs(DCM.xY.Time - T1));
    [~, T2]     = min(abs(DCM.xY.Time - T2));
    
    % Time [ms] of down-sampled data
    %----------------------------------------------------------------------
    It          = (T1:DT:T2)';               % indices - bins
    DCM.xY.pst  = DCM.xY.Time(It);           % PST
    DCM.xY.It   = It;                        % Indices of time bins
    DCM.xY.dt   = DT/D.fsample;              % sampling in seconds
    Nb          = length(It);                % number of bins
    
catch
    errordlg('Please specify time window');
    error('')
end

% get frequency range
%--------------------------------------------------------------------------
try
    Hz1     = DCM.options.Fdcm(1);          % lower frequency
    Hz2     = DCM.options.Fdcm(2);          % upper frequency
catch
    pst     = DCM.xY.pst(end) - DCM.xY.pst(1);
    Hz1     = max(ceil(2*1000/pst),4);
    if Hz1 < 8;
        Hz2 = 48;
    else
        Hz2 = 128;
    end
end


% Frequencies
%--------------------------------------------------------------------------
Hz  = fix(Hz1:Hz2);                         % Frequencies
Nf  = length(DCM.xY.Hz);                    % number of frequencies
Ne  = length(trial);                        % number of ERPs

% get induced responses (use previous CSD results if possible)
%==========================================================================
try
    if length(DCM.xY.csd) == Ne;
        if all(size(DCM.xY.csd{1}) == [Nb Nf Nm Nm])
            if DCM.xY.Rft  == Rft;
                DCM.xY.y  = spm_cond_units(DCM.xY.csd);
                % return
            end
        end
    end
end

% Cross spectral density for each trial type
%==========================================================================
condlabels = D.condlist;
for e = 1:Ne;
    
    % trial indices
    %----------------------------------------------------------------------
    c = D.pickconditions(condlabels{trial(e)});
    
    % use only the first 512 trial
    %----------------------------------------------------------------------
    try c = c(1:512); end
    
    
    % evoked response
    %----------------------------------------------------------------------
    Nt    = length(c);
    Y     = zeros(Nb,Nm,Nt);
    P     = zeros(Nb,Nf,Nm,Nm);
    Q     = zeros(Nb,Nf,Nm,Nm);
    
    for k = 1:Nt
        Y(:,:,k) = full(double(D(Ic,It,c(k))'*DCM.M.U));
    end

    
    % store
    %----------------------------------------------------------------------
    erp{e} = mean(Y,3);
    
    % induced response
    %----------------------------------------------------------------------
    for k = 1:Nt
        
        fprintf('\nevaluating condition %i (trial %i)',e,k)
        G     = spm_morlet(Y(:,:,k) - erp{e},Hz*DCM.xY.dt,Rft);
        for i = 1:Nm
            for j = 1:Nm
                P(:,:,i,j) = (G(:,:,i).*conj(G(:,:,j)));
            end
        end
        Q = Q + P;
    end
    
    % normalise induced responses
    %--------------------------------------------------------------------------
    Vm    = mean(mean(squeeze(var(Y,[],3))));
    Vs    = mean(diag(squeeze(mean(squeeze(mean(Q))))));
    Q     = Vm*Q/Vs;
    
    % store
    %----------------------------------------------------------------------
    csd{e} = Q;
    
end

% place cross-spectral density in xY.y
%==========================================================================
[csd,scale] = spm_cond_units(csd);
DCM.xY.erp  = spm_unvec(spm_vec(erp)*sqrt(scale),erp);
DCM.xY.csd  = csd;
DCM.xY.y    = csd;
DCM.xY.U    = DCM.M.U;
DCM.xY.code = condlabels(trial);
DCM.xY.Rft  = Rft;
DCM.xY.Hz   = Hz;

return

% plot responses
%--------------------------------------------------------------------------
spm_dcm_tfm_response(DCM.xY,DCM.xY.pst,DCM.xY.Hz);



