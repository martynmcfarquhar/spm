function prepare = spm_cfg_eeg_prepare
% configuration file for the prepare tool
%_______________________________________________________________________
% Copyright (C) 2012 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: spm_cfg_eeg_prepare.m 5339 2013-03-21 10:32:30Z vladimir $

rev = '$Rev: 5339 $';

D = cfg_files;
D.tag = 'D';
D.name = 'File Name';
D.filter = 'mat';
D.num = [1 1];
D.help = {'Select the M/EEG mat file.'};

defaulttype = cfg_const;
defaulttype.tag = 'defaulttype';
defaulttype.name = 'Set channel types to default';
defaulttype.val  = {1};
defaulttype.help = {'Reset all channel types to default'};

newtype = cfg_menu;
newtype.tag = 'newtype';
newtype.name = 'New channel type';
newtype.labels = {'EEG', 'EOG', 'ECG', 'EMG', 'LFP', 'PHYS', 'Other'};
newtype.val = {'Other'};
newtype.values = {'EEG', 'EOG', 'ECG', 'EMG', 'LFP', 'PHYS', 'Other'};
newtype.help = {'Select the new channel type to set'};

settype = cfg_branch;
settype.tag = 'settype';
settype.name = 'Set channel type';
settype.val = {spm_cfg_eeg_channel_selector, newtype};
settype.help = {'Select the new channel type to set'};

rawmeg = cfg_files;
rawmeg.tag = 'rawmeg';
rawmeg.name = 'Select MEG dataset';
rawmeg.filter = 'any';
rawmeg.num = [1 1];
rawmeg.help = {'Select the MEG dataset to copy sensors from'};

loadmegsens = cfg_branch;
loadmegsens.tag = 'loadmegsens';
loadmegsens.name = 'Load MEG sensors';
loadmegsens.val = {rawmeg};
loadmegsens.help = {'Reload MEG sensor representation from raw dataset'};

megfid = cfg_files;
megfid.tag = 'megfid';
megfid.name = 'Select MEG headshape file';
megfid.filter = 'any';
megfid.num = [1 1];
megfid.help = {'Select the file to read MEG headshape from'};

fidname = cfg_entry;
fidname.tag = 'fidname';
fidname.name = 'MEG fiducial label';
fidname.strtype = 's';
fidname.help = {'Label of a fiducial point as specified in the MEG dataset'};

hsname = cfg_entry;
hsname.tag = 'hsname';
hsname.name = 'Surface point label';
hsname.strtype = 's';
hsname.help = {'Label of a fiducial point as specified in the surface points file'};

matching = cfg_branch;
matching.tag = 'matching';
matching.name = 'Matching pair';
matching.help = {'Specify a matching pair of labeled point in the dataset and surface points'};
matching.val  = {fidname, hsname};

fiducials = cfg_repeat;
fiducials.tag = 'fiducials';
fiducials.name = 'Fiducials';
fiducials.help = {'Specify at least 3 matching pairs of fiducials to coregister the surface points to the sensors'};
fiducials.num  = [3 Inf];
fiducials.values  = {matching};
fiducials.val = {matching matching matching};

headshape = cfg_branch;
headshape.tag = 'headshape';
headshape.name = 'Load MEG fiducials\headshape';
headshape.val = {megfid, fiducials};
headshape.help = {'Load MEG fiducials or headshape from a file'};

nasfid = cfg_entry;
nasfid.tag = 'nasfid';
nasfid.name = 'Nasion';
nasfid.strtype = 's';
nasfid.val = {'nas'};
nasfid.help = {'Enter the nasion fiducial label'};

lpafid = cfg_entry;
lpafid.tag = 'lpafid';
lpafid.name = 'Left';
lpafid.strtype = 's';
lpafid.val = {'lpa'};
lpafid.help = {'Enter the left fiducial label'};

rpafid = cfg_entry;
rpafid.tag = 'rpafid';
rpafid.name = 'Right';
rpafid.strtype = 's';
rpafid.val = {'rpa'};
rpafid.help = {'Enter the right fiducial label'};

multimodal = cfg_branch;
multimodal.tag = 'multimodal';
multimodal.name = 'Specify MEG fiducial labels';
multimodal.val  = {nasfid, lpafid, rpafid};
multimodal.help = {'ONLY for multimodal datasets the labels of MEG fiducials should be specified.'};

defaulteegsens = cfg_branch;
defaulteegsens.tag = 'defaulteegsens';
defaulteegsens.name = 'Assign default EEG sensors';
defaulteegsens.val  = {multimodal};
defaulteegsens.help = {'Set EEG sensor locations to SPM template'};

eegsens = cfg_files;
eegsens.tag = 'eegsens';
eegsens.name = 'Select EEG sensors file';
eegsens.filter = 'any';
eegsens.num = [1 1];
eegsens.help = {'Select the file with EEG electrode coordinates (e.g. Polhemus or SFP)'};

nomatch = cfg_const;
nomatch.tag = 'nomatch';
nomatch.name = 'Not necessary';
nomatch.val  = {1};

megmatch = cfg_choice;
megmatch.name = 'Match fiducials to MEG';
megmatch.tag = 'megmatch';
megmatch.values = {nomatch, fiducials};
megmatch.val = {nomatch};
megmatch.help = {'Match EEG fiducials to MEG fiducials (only for multimodal datasets)'};

loadeegsens = cfg_branch;
loadeegsens.tag = 'loadeegsens';
loadeegsens.name = 'Load EEG sensors';
loadeegsens.val = {eegsens, megmatch};
loadeegsens.help = {'Load EEG electrode locations'};

refsens = cfg_branch;
refsens.tag = 'refsens';
refsens.name = 'Select reference sensors';
refsens.val = {spm_cfg_eeg_channel_selector('notype')};
refsens.help = {'Select the sensors to which the EEG recording was referenced',...
    '(select ''All'' for average reference)'};

montage = cfg_files;
montage.tag = 'montage';
montage.name = 'Select montage file';
montage.filter = 'mat';
montage.num = [1 1];
montage.help = {'Select montage file that specifies the referencing'};

seteegref = cfg_choice;
seteegref.tag = 'seteegref';
seteegref.name = 'Define EEG referencing';
seteegref.values = {refsens, montage};
seteegref.val = {refsens};
seteegref.help = {'Define the way EEG channels were derived from sensors'};

project3dEEG = cfg_const;
project3dEEG.tag = 'project3dEEG';
project3dEEG.name = 'Project EEG sensors to 2D';
project3dEEG.val  = {1};
project3dEEG.help = {'Project EEG sensor locations to 2D'};

project3dMEG = cfg_const;
project3dMEG.tag = 'project3dMEG';
project3dMEG.name = 'Project MEG sensors to 2D';
project3dMEG.val  = {1};
project3dMEG.help = {'Project MEG sensor locations to 2D'};

loadtemplate = cfg_files;
loadtemplate.tag = 'loadtemplate';
loadtemplate.name = 'Load channel template file';
loadtemplate.filter = 'mat';
loadtemplate.num = [1 1];
loadtemplate.help = {'Specify 2D channel locations by loading a template file'};

status = cfg_menu;
status.tag = 'status';
status.name = 'Status to set';
status.labels = {'GOOD', 'BAD'};
status.val = {1};
status.values = {0, 1};
status.help = {'Select the new channel type to set'};

setbadchan = cfg_branch;
setbadchan.tag = 'setbadchan';
setbadchan.name = 'Set/unset bad channels';
setbadchan.val = {spm_cfg_eeg_channel_selector, status};
setbadchan.help = {'Set or clear bad flag for channels'};

task = cfg_repeat;
task.tag = 'task';
task.name = 'Select task(s)';
task.num = [1 Inf];
task.values = {defaulttype, settype, loadmegsens, headshape,...
    defaulteegsens, loadeegsens, seteegref, project3dEEG, project3dMEG,...
    loadtemplate, setbadchan};

prepare = cfg_exbranch;
prepare.tag = 'prepare';
prepare.name = 'M/EEG Prepare';
prepare.val = {D, task};
prepare.help = {'Converts EEG/MEG data.'};
prepare.prog = @eeg_prepare;
prepare.vout = @vout_eeg_prepare;
prepare.modality = {'EEG'};

function out = eeg_prepare(job)

D = spm_eeg_load(job.D{1});
for i = 1:numel(job.task)
    S = [];
    S.D = D;
    switch  char(fieldnames(job.task{i}))
        case 'defaulttype'
            S.task = 'defaulttype';
        case 'settype'
            S.task = 'settype';
            S.type = job.task{i}.settype.newtype;
            S.ind  = D.selectchannels(spm_cfg_eeg_channel_selector(job.task{i}.settype.channels));
        case 'loadmegsens'
            S.task = 'loadmegsens';
            S.source = char(job.task{i}.loadmegsens.rawmeg{1});
        case 'headshape'
            S.task = 'headshape';
            S.source = 'convert';
            S.source = char(job.task{i}.loadmegsens.megfid{1});
            S.regfid = {};
            for j = 1:numel(job.task{i}.headshape.matching)
                S.regfid{j, 1} = job.task{i}.headshape.matching(j).hsname;
                S.regfid{j, 2} = job.task{i}.headshape.matching(j).fidname;
            end
        case 'defaulteegsens'
            S.task = 'defaulteegsens';
            S.regfid ={
                job.task{i}.defaulteegsens.multimodal.nasfid 'spmnas'
                job.task{i}.defaulteegsens.multimodal.lpafid 'spmlpa'
                job.task{i}.defaulteegsens.multimodal.lpafid 'spmrpa'
                };
        case 'loadeegsens'
            S.task = 'loadeegsens';
            S.source = 'locfile';
            
            S.sensfile = char(job.task{i}.loadeegsens.eegsens);
            if isfield(job.task{i}.loadeegsens.megmatch, 'fiducials')
                for j = 1:numel(job.task{i}.loadeegsens.megmatch.matching)
                    S.regfid{j, 1} = job.task{i}.loadeegsens.megmatch.matching(j).hsname;
                    S.regfid{j, 2} = job.task{i}.loadeegsens.megmatch.matching(j).fidname;
                end
            end
        case 'seteegref'
            S.task = 'sens2chan';
            if isfield(job.task{i}.seteegref, 'refsens')
                S.refelec = spm_cfg_eeg_channel_selector(job.task{i}.seteegref.refsens.channels);
            else
                S.montage = char(job.task{i}.seteegref.montage);
            end
        case 'project3dEEG'
            S.task = 'project3D';
            S.modality = 'EEG';
        case 'project3dMEG'
            S.task = 'project3D';
            S.modality = 'MEG';
        case 'loadtemplate'
            S.task = 'loadtemplate';
            S.P = char(job.task{i}.loadtemplate);
        case 'setbadchan'
            S.task = 'setbadchan';
            S.channels = spm_cfg_eeg_channel_selector(job.task{i}.setbadchan.channels);
            S.status   =  job.task{i}.setbadchan.status;
    end
    D = spm_eeg_prep(S);
end

save(D);

out.D = D;
out.Dfname = {fullfile(D)};

function dep = vout_eeg_prepare(job)
% Output is always in field "D", no matter how job is structured
dep = cfg_dep;
dep.sname = 'Prepared M/EEG Data';
% reference field "D" from output
dep.src_output = substruct('.','D');
% this can be entered into any evaluated input
dep.tgt_spec   = cfg_findspec({{'strtype','e'}});

dep(2) = cfg_dep;
dep(2).sname = 'Prepared Datafile';
% reference field "Dfname" from output
dep(2).src_output = substruct('.','Dfname');
% this can be entered into any file selector
dep(2).tgt_spec   = cfg_findspec({{'filter','mat'}});

