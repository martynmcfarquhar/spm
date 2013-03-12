function job = spm_rewrite_job(job)
% Rewrite a job for SPM12
%__________________________________________________________________________
% Copyright (C) 2012-2013 Wellcome Trust Centre for Neuroimaging

% $Id: spm_rewrite_job.m 5320 2013-03-12 19:06:48Z guillaume $


try
    job.spatial.preproc.data;
    fprintf('Conversion Segment -> Old Segment\n');                     %-#
    job = struct('tools', struct('oldseg', job.spatial.preproc));
end

try
    job.spatial.normalise.est.subj(1).source ;
    fprintf('Conversion Normalise:Est -> Old Normalise:Est\n');         %-#
    job = struct('tools', struct('oldnorm', job.spatial.normalise));
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
end

try
    job.tools.preproc8;
    fprintf('Conversion Tools:New Segment -> Spatial:Segment\n');       %-#
    job = struct('spatial',struct('preproc',job.tools.preproc8));
end

try
    job.tools.sendmail;
    job = struct('util', job.tools);
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
