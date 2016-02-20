function MDP = DEM_demo_MDP_rule
% Demo of active inference for visual salience
%__________________________________________________________________________
%
% This routine uses active inference for Markov decision processes to
% illustrate epistemic foraging in the context of visual searches. Here,
% the agent has to
%
% This demonstration uses a factorised version of the MDP scheme. In
% other words, we assume a mean field approximation to the posterior over
% different hidden states (context, location, etc) � and over
% multiple modalities (what versus where).  This provides a parsimonious
% representation of posterior beliefs over hidden states � but does induce
% degree of overconfidence associated with approximate Bayesian inference.
%
% see also: DEM_demo_MDP_habits.m and spm_MPD_VB_X.m
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: DEM_demo_MDP_rule.m 6728 2016-02-20 18:07:58Z karl $

% set up and preliminaries
%==========================================================================

% second level (semantic)
%==========================================================================

% prior beliefs about initial states (in terms of counts_: D and d
%--------------------------------------------------------------------------
D{1} = [1 1 1]';        % rule:   {'left','centre','right'}
D{2} = [1 1 1]';        % what:   {'red','green','blue'}
D{3} = [0 0 0 1]';      % where:  {'left','centre','right','null'}
D{4} = [0 0 0 1]';      % report: {'red','green','blue','undecided'}

% probabilistic mapping from hidden states to outcomes: A
%--------------------------------------------------------------------------
Nf    = numel(D);
Ns    = zeros(1,Nf);
for f = 1:Nf
    Ns(f) = numel(D{f});
end
for f1 = 1:Ns(1)                     % location of trgaet colour
    for f2 = 1:Ns(2)                 % correct colour
        for f3 = 1:Ns(3)             % location of fixation
            for f4 = 1:Ns(3)         % decision
                
                % A{1} what: {'red','green','blue','null'}
                %==========================================================
                if f3 == 4, A{1}(4,f1,f2,f3,f4)  = 1;  end
                if f3 == 2, A{1}(f1,f1,f2,f3,f4) = 1;  end
                if f3 == 1
                    if f1 == 1
                        A{1}(f2,f1,f2,f3,f4) = 1;
                    else
                        A{1}(1:3,f1,f2,f3,f4) = 1/3;
                    end
                end
                if f3 == 3
                    if f1 == 3
                        A{1}(f2,f1,f2,f3,f4) = 1;
                    else
                        A{1}(1:3,f1,f2,f3,f4) = 1/3;
                    end
                end
                
                % A{2} where: {'left','centre','right','null'}
                %----------------------------------------------------------
                A{2}(f3,f1,f2,f3,f4) = 1;
                
                % A{3} feedback: {'null','right','wrong'}
                %----------------------------------------------------------
                if f4 == 4, 
                    A{3}(1,f1,f2,f3,f4) = 1;                             % undecided
                else
                    if f1 == 2 && f4 == 2,  A{3}(2,f1,f2,f3,f4) = 1; end % right
                    if f1 == 2 && f4 ~= 2,  A{3}(3,f1,f2,f3,f4) = 1; end % wrong
                    if f1 == 1 && f4 == f2, A{3}(2,f1,f2,f3,f4) = 1; end % right
                    if f1 == 1 && f4 ~= f2, A{3}(3,f1,f2,f3,f4) = 1; end % wrong
                    if f1 == 3 && f4 == f2, A{3}(2,f1,f2,f3,f4) = 1; end % right
                    if f1 == 3 && f4 ~= f2, A{3}(3,f1,f2,f3,f4) = 1; end % wrong
                end
            end
        end
    end
end
Ng    = numel(A);
for g = 1:Ng
    No(g) = size(A{g},1);
    A{g}  = double(A{g});
end

% controlled transitions: B{f} for each factor
%--------------------------------------------------------------------------
for f = 1:Nf
    B{f} = eye(Ns(f));
end

% control states B(3): where {'left','centre','right','null'}
%--------------------------------------------------------------------------
for k = 1:Ns(3)
    B{3}(:,:,k) = 0;
    B{3}(k,:,k) = 1;
end

% control states B(4): report {'red','green','blue','undecided'}
%--------------------------------------------------------------------------
for k = 1:Ns(4)
    B{4}(:,:,k) = 0;
    B{4}(k,:,k) = 1;
end

% allowable policies (specified as the next action) U
%--------------------------------------------------------------------------
U(1,1,:)  = [1 1 1 4]';         % sample left
U(1,2,:)  = [1 1 2 4]';         % sample left
U(1,3,:)  = [1 1 3 4]';         % sample left
U(1,4,:)  = [1 1 4 1]';         % return and report red
U(1,5,:)  = [1 1 4 2]';         % return and report green
U(1,6,:)  = [1 1 4 3]';         % return and report blue


% priors: (utility) C
%--------------------------------------------------------------------------
for g = 1:Ng
    C{g}  = zeros(No(g),1);
end
C{3}(2,:) =  2;                 % the agent expects to be right
C{3}(3,:) = -8;                 % and not wrong


% MDP Structure
%--------------------------------------------------------------------------
mdp.T = 5;                      % number of moves
mdp.U = U;                      % allowable policies
mdp.A = A;                      % observation model
mdp.B = B;                      % transition probabilities
mdp.C = C;                      % preferred outcomes
mdp.D = D;                      % prior over initial states
mdp.s = [1 1 4 4]';             % initial state

mdp.Aname = {'what','where','feedback'};
mdp.Bname = {'rule','colour','where','decision'};

mdp  = spm_MDP_check(mdp);


% illustrate a single trial
%==========================================================================
MDP  = spm_MDP_VB_X(mdp);

% show belief updates (and behaviour)
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 1'); clf
spm_MDP_VB_trial(MDP);

% illustrate phase-precession and responses
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 2'); clf
spm_MDP_VB_LFP(MDP,[],1);


return

subplot(3,2,3)
spm_MDP_search_plot(MDP)





% illustrate evidence accumulation and perceptual synthesis
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 3'); clf
spm_MDP_search_percept(MDP)

return

% illustrate a sequence of trials
%==========================================================================

% true initial states � with context change at trial 12
%--------------------------------------------------------------------------
clear MDP
N      = 32;
s(1,:) = ceil(rand(1,N)*3);
s(2,:) = ceil(rand(1,N)*1);
s(3,:) = ceil(rand(1,N)*2);
s(4,:) = ceil(rand(1,N)*2);

for i = 1:N
    MDP(i)   = mdp;      % create structure array
    MDP(i).s = s(:,i);   % context
end


% Solve - an example sequence
%==========================================================================
MDP  = spm_MDP_VB_X(MDP);

% illustrate behavioural responses and neuronal correlates
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 4'); clf
spm_MDP_VB_game(MDP);

% illustrate phase-amplitude (theta-gamma) coupling
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 5'); clf
spm_MDP_VB_LFP(MDP(1:8));

% illustrate behaviour in more detail
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 6'); clf;
n     = 3;
for i = 1:n*n
    subplot(n,n,i), spm_MDP_search_plot(MDP(i));
end


% illustrate the effects of epistemic and incentive salience
%==========================================================================
mdp.beta  = 1;
mdp.T     = 8;                             % maximum number of saccades

c     = (0:8)/8;
c     = -4*c;
for j = 1:length(c)
    
    % array of trials
    %----------------------------------------------------------------------
    clear MDP
    for i = 1:N
        MDP(i)           = mdp;            % create structure array
        MDP(i).C{1}(6,:) = c(j);           % salience
        MDP(i).s         = s(:,i);         % context
    end
    
    % solve and evaluate performance
    %----------------------------------------------------------------------
    MDP   = spm_MDP_VB_X(MDP);
    for i = 1:N
        o      = MDP(i).o(1,:);                       % outcomes
        P(1,i) = double(any(o == 5) & ~any(o == 6));  % accuracy
        P(2,i) = find([(o > 4), 1],1) - 1;            % number of saccades
        P(3,i) = mean(MDP(i).rt);                     % reaction time
    end
    
    % solve and evaluate performance
    %----------------------------------------------------------------------
    EQ(:,j) = mean(P,2);
end

spm_figure('GetWin','Figure 7'); clf;

subplot(3,3,1), bar(-c,EQ(1,:)*100)
xlabel('Prior preference'),ylabel('percent correct')
title('Accuracy','Fontsize',16), axis square

subplot(3,3,2), bar(-c,EQ(2,:))
xlabel('Prior preference'),ylabel('number of saccades')
title('Decision time','Fontsize',16), axis square

subplot(3,3,3), bar(-c,EQ(3,:))
xlabel('Prior preference'),ylabel('saccade duration')
title('Reaction time','Fontsize',16), axis square

% now repeat but changing prior precision
%--------------------------------------------------------------------------
b     = (0:8)/8;
b     = 1./(2*b + 1/8);
for j = 1:length(b)
    
    % array of trials
    %----------------------------------------------------------------------
    clear MDP
    for i = 1:N
        MDP(i)      = mdp;               % create structure array
        MDP(i).beta = b(j);              % prior (inverse) precision
        MDP(i).s    = s(:,i);            % context
    end
    
    % solve and evaluate performance
    %----------------------------------------------------------------------
    MDP   = spm_MDP_VB_X(MDP);
    for i = 1:N
        o      = MDP(i).o(1,:);                       % outcomes
        P(1,i) = double(any(o == 5) & ~any(o == 6));  % accuracy
        P(2,i) = find([(o > 4), 1],1) - 1;            % number of saccades
        P(3,i) = mean(MDP(i).rt);                     % reaction time
    end
    
    % solve and evaluate performance
    %----------------------------------------------------------------------
    EP(:,j) = mean(P,2);
end

subplot(3,3,4), bar(1./b,EP(1,:)*100)
xlabel('Prior precision'),ylabel('percent correct')
title('Accuracy','Fontsize',16), axis square

subplot(3,3,5), bar(1./b,EP(2,:))
xlabel('Prior precision'),ylabel('number of saccades')
title('Decision time','Fontsize',16), axis square

subplot(3,3,6), bar(1./b,EP(3,:))
xlabel('Prior precision'),ylabel('saccade duration')
title('Reaction time','Fontsize',16), axis square

save

return

it


function spm_MDP_search_plot(MDP)
% illustrates visual search graphically
%--------------------------------------------------------------------------

% locations
%--------------------------------------------------------------------------
x = [0,0;-1 -1; -1 1; 1 -1;1 1;-1,2.5;0,2.5;1,2.5];
y = x + 1/4;
r = [-1,1]/2;

% plot cues
%--------------------------------------------------------------------------
if strcmp('replace',get(gca,'Nextplot'))
    
    % load images
    %----------------------------------------------------------------------
    load MDP_search_graphics
    null = zeros(size(bird)) + 1;
    f    = MDP.s(:,1);
    
    % latent cues for this hidden state
    %----------------------------------------------------------------------
    if f(1) == 1, a = {'bird','cats';'null','null'}; end
    if f(1) == 2, a = {'bird','seed';'null','null'}; end
    if f(1) == 3, a = {'bird','null';'null','seed'}; end
    
    % flip cues according to hidden (invariants) states
    %----------------------------------------------------------------------
    if f(3) == 2, a = flipud(a); end
    if f(4) == 2, a = fliplr(a); end
    
    for i = 1:numel(a)
        image(r + x(i + 1,1),r + x(i + 1,2),eval(a{i})), hold on
    end
    
    % choices
    %----------------------------------------------------------------------
    choice = {'flee','feed','wait'};
    for i = 1:3
        if i == f(1)
            text(i - 2,2.5,choice{i},'FontWeight','Bold','color','red')
        else
            text(i - 2,2.5,choice{i})
        end
        
    end
    axis image, axis([-2,2,-2,3])
    
    % labels
    %----------------------------------------------------------------------
    for i = 1:size(x,1)
        text(y(i,1),y(i,2),num2str(i),'FontSize',12,'FontWeight','Bold','color','g')
    end
end

% Extract and plot eye movements
%--------------------------------------------------------------------------
for i = 1:numel(MDP.o(2,:))
    X(i,:) = x(MDP.o(2,i),:);
end
for j = 1:2
    T(:,j) = interp(X(:,j),8,2);
    T(:,j) = T(:,j) + spm_conv(randn(size(T(:,j))),2)/16;
end
plot(T(:,1),T(:,2),'b:')
plot(X(:,1),X(:,2),'b.','MarkerSize',8)

function spm_MDP_search_percept(MDP)
% illustrates visual search graphically
%--------------------------------------------------------------------------

% load images
%--------------------------------------------------------------------------
load MDP_search_graphics
clf

null  = zeros(size(bird)) + 1;
mask  = hamming(256);
mask  = mask*mask';
for i = 1:3
    mask(:,:,i) = mask(:,:,1);
end
x     = [0,0;-1 -1; -1 1; 1 -1;1 1;-1,2.5;0,2.5;1,2.5];
r     = [-1,1]/2;
try
    d = MDP.D;
catch
    d = MDP.d;
end
Nf    = numel(d);
for f = 1:Nf
    Ns(f) = numel(d{f});
end

% plot cues
%--------------------------------------------------------------------------
Ni    = 1:size(MDP.xn{1},1);
Nx    = length(Ni);
Ne    = find([MDP.o(1,:) > 4,1],1) - 1;
for k = 1:Ne
    for i = 1:Nx
        
        % movie over peristimulus time
        %------------------------------------------------------------------
        subplot(2,1,1)
        for j = 1:4
            S{j} = zeros(size(bird));
        end
        for f1 = 1:Ns(1)
            for f2 = 1:Ns(2)
                for f3 = 1:Ns(3)
                    for f4 = 1:Ns(4)
                        
                        % latent cues for this hidden state
                        %--------------------------------------------------
                        if f1 == 1, a = {'bird','cats';'null','null'}; end
                        if f1 == 2, a = {'bird','seed';'null','null'}; end
                        if f1 == 3, a = {'bird','null';'null','seed'}; end
                        
                        % flip cues according to hidden (invariants) states
                        %--------------------------------------------------
                        if f3 == 2, a = flipud(a); end
                        if f4 == 2, a = fliplr(a); end
                        
                        % mixture
                        %--------------------------------------------------
                        p     = MDP.xn{1}(Ni(i),f1,1,k)*MDP.xn{3}(Ni(i),f3,1,k)*MDP.xn{4}(Ni(i),f4,1,k);
                        for j = 1:4
                            S{j} = S{j} + eval(a{j})*p;
                        end
                    end
                end
            end
        end
        
        % image
        %------------------------------------------------------------------
        hold off
        for j = 1:numel(S)
            imagesc(r + x(j + 1,1),r + x(j + 1,2),S{j}/max(S{j}(:))), hold on
        end
        
        % stimulus
        %------------------------------------------------------------------
        d   = (1 - exp(1 - i));
        if     MDP.o(1,k) == 1
            imagesc(r,r,null.*mask*d)
        elseif MDP.o(1,k) == 2
            imagesc(r,r,bird.*mask*d)
        elseif MDP.o(1,k) == 3
            imagesc(r,r,seed.*mask*d)
        elseif MDP.o(1,k) == 4
            imagesc(r,r,cats.*mask*d)
        end
        
        % save
        %------------------------------------------------------------------
        axis image, axis([-2,2,-2,2]), drawnow
        M((k - 1)*Nx + i) = getframe(gca);
        
    end
    
    
    % static pictures
    %----------------------------------------------------------------------
    subplot(2,Ne,Ne + k),hold off
    for j = 1:numel(S)
        imagesc(r + x(j + 1,1),r + x(j + 1,2),S{j}/max(S{j}(:))), hold on
    end
    
    % stimulus
    %------------------------------------------------------------------
    if     MDP.o(1,k) == 1
        imagesc(r,r,null.*mask)
    elseif MDP.o(1,k) == 2
        imagesc(r,r,bird.*mask)
    elseif MDP.o(1,k) == 3
        imagesc(r,r,seed.*mask)
    elseif MDP.o(1,k) == 4
        imagesc(r,r,cats.*mask)
    end
    
    for j = 1:k
        X(j,:) = x(MDP.o(2,j),:);
    end
    plot(X(:,1),X(:,2),'b.','MarkerSize',8)
    
    % save
    %------------------------------------------------------------------
    axis image, axis([-2,2,-2,2]), drawnow
    
end

% Extract and plot eye movements
%--------------------------------------------------------------------------
subplot(2,1,1)
set(gca,'Userdata',{M,16})
set(gca,'ButtonDownFcn','spm_DEM_ButtonDownFcn')
title('Scene construction','FontSize',16)
title('Percept (click axis for movie)')
