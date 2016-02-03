function job = spm_rewrite_job(job)
% Rewrite a batch job for SPM12
%__________________________________________________________________________
% Copyright (C) 2012-2014 Wellcome Trust Centre for Neuroimaging

% $Id: spm_rewrite_job.m 6711 2016-02-03 15:25:43Z peter $


try
    job.spatial.preproc.data;
    fprintf('Conversion Segment -> Old Segment\n');                     %-#
    job = struct('tools', struct('oldseg', job.spatial.preproc));
    if ~spm_existfile(spm_file(job.tools.oldseg.opts.tpm{1},'number',''))
        fprintf('You might have to manually update the tissue probability maps in Old Segment to:\n');
        TPM = spm_get_defaults('old.preproc.tpm');
        fprintf('    %s\n',TPM{:});
    end
end

try
    job.spatial.normalise.est.subj(1).source ;
    fprintf('Conversion Normalise:Est -> Old Normalise:Est\n');         %-#
    job = struct('tools', struct('oldnorm', job.spatial.normalise));
    if ~spm_existfile(spm_file(job.tools.oldnorm.est.eoptions.template{1},'number',''))
        fprintf('You might have to manually update the template image in Old Normalise:Est.\n');
    end
end

try
    job.spatial.normalise.write.subj(1).matname;
    fprintf('Conversion Normalise:Write -> Old Normalise:Write\n');     %-#
    job = struct('tools', struct('oldnorm', job.spatial.normalise));
end

try
    job.spatial.normalise.estwrite.subj(1).source;
    fprintf('Conversion Normalise:EstWrite -> Old Normalise:EstWrite\n');%-#
    job = struct('tools', struct('oldnorm', job.spatial.normalise));
    if ~spm_existfile(spm_file(job.tools.oldnorm.estwrite.eoptions.template{1},'number',''))
        fprintf('You might have to manually update the template image in Old Normalise:EstWrite.\n');
    end
end

try
    job.tools.preproc8;
    fprintf('Conversion Tools:New Segment -> Spatial:Segment\n');       %-#
    job = struct('spatial',struct('preproc',job.tools.preproc8));
    if ~spm_existfile(spm_file(job.spatial.preproc.tissue(1).tpm{1},'number',''))
        fprintf('You might have to manually update the tissue probability maps in Segment to:\n');
        fprintf('    %s\n',fullfile(spm('dir'),'tpm','TPM.nii'));
    end
    if numel(job.spatial.preproc.warp.reg) == 1
        job.spatial.preproc.warp = rmfield(job.spatial.preproc.warp,'reg');
    end
end

try
    for i=1:numel(job.stats.con.consess)
        try
            con = job.stats.con.consess{i}.tcon.convec;
            job.stats.con.consess{i}.tcon = rmfield(job.stats.con.consess{i}.tcon,'convec');
            job.stats.con.consess{i}.tcon.weights = con;
        end
        try
            con = job.stats.con.consess{i}.fcon.convec;
            job.stats.con.consess{i}.fcon = rmfield(job.stats.con.consess{i}.fcon,'convec');
            job.stats.con.consess{i}.fcon.weights = con;
        end
        try
            job.stats.con.consess{i}.fcon.weights{1};
            fprintf('Conversion to new syntax: Contrast Manager:F-contrast\n'); %-#
            try
                con = cat(1,job.stats.con.consess{i}.fcon.weights{:});
            catch
                fprintf('Error concatenating F-contrast vectors.\n');   %-#
            end
            job.stats.con.consess{i}.fcon.weights = con;
        end
    end
end

try
    if isequal(job.stats.results.print, true)
        job.stats.results.print = spm_get_defaults('ui.print');
    end
end

try
    job.stats.results.conspec(1).mask.thresh;
    for i=1:numel(job.stats.results.conspec)
        if isempty(job.stats.results.conspec(i).mask)
            job.stats.results.conspec(i).mask = struct('none',1);
        else
            job.stats.results.conspec(i).mask = struct('contrast',job.stats.results.conspec(i).mask);
        end
    end
end

try
    D = job.dcm.fmri.estimate.dcmmat;
    for i=1:numel(D)
        job.dcm.estimate.dcms.model(i).dcmmat = D(i);
    end
    job.dcm.estimate = rmfield(job.dcm.estimate,'dcmmat');
    job.dcm.estimate.output_type.output_separate = struct([]);
    job.dcm.estimate.est_type = 3;
end

try
    job.stats.bms.bms_dcm;
    job = struct('dcm',struct('bms',struct('inference',job.stats.bms.bms_dcm)));
    for i=1:numel(job.dcm.bms.inference.sess_dcm)
        job.dcm.bms.inference.sess_dcm{i}.dcmmat = job.dcm.bms.inference.sess_dcm{i}.mod_dcm;
        job.dcm.bms.inference.sess_dcm{i} = rmfield(job.dcm.bms.inference.sess_dcm{i},'mod_dcm');
    end
end

try
    job.tools.sendmail;
    job = struct('util', job.tools);
end

try
    job.util.spm_surf;
    job = struct('util', struct('render', struct('extract',job.util.spm_surf)));
end

try
    job.util.dicom;
    job.util = struct('import', job.util);
end
try
    job.util.minc;
    job.util = struct('import', job.util);
end
try
    job.util.ecat;
    job.util = struct('import', job.util);
end

try
    job.tools.fieldmap;
    opts = {'presubphasemag','realimag','phasemag','precalcfieldmap'};
    imgs{1} = {'phase','magnitude'};
    imgs{2} = {'shortreal','shortimag','longreal','longimag'};
    imgs{3} = {'shortphase','shortmag','longphase','longmag'};
    imgs{4} = {'precalcfieldmap','magfieldmap'};
    for j=1:numel(opts)
        try
            job.tools.fieldmap.(opts{j});
            job.tools.fieldmap = struct('calculatevdm',job.tools.fieldmap.(opts{j}));
            for i=1:numel(job.tools.fieldmap.calculatevdm.subj)
                for k=1:numel(imgs{j})
                    job.tools.fieldmap.calculatevdm.subj(i).data.(opts{j}).(imgs{j}{k}) = job.tools.fieldmap.calculatevdm.subj(i).(imgs{j}{k});
                end
            end
            job.tools.fieldmap.calculatevdm.subj = rmfield(job.tools.fieldmap.calculatevdm.subj,imgs{j});
        end
    end
end

try
    util = char(fieldnames(job.util));
    if ismember(util, {'cdir','md','deletefiles','movefile'})
        ws = warning('off','backtrace');
        warning(['spm.util.%s was DEPRECATED in SPM8 and has now been REMOVED.\n' ...
            'Please update your batches to use BasicIO instead.'],util);
        warning(ws);
        %job = struct([]);
    end
end
