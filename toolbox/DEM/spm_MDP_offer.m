function spm_MDP_offer
% Demo for active inference with limited offer game
%__________________________________________________________________________
%
% This demonstration routine uses variational Bayes to minimise the free
% energy to model decision-making. The particular focus here is on
% decisions that are time-sensitive, requiring an explicit representation
% of future states. The example considered here represents a limited offer
% game, where a low offer can be converted to a high offer, which may or
% may not occur. Furthermore, offers may be withdrawn. The objective is
% to understand model choices about accepting or declining the current
% offer in terms of active inference, under prior beliefs about future
% states. The model is specified in a fairly general way in terms of
% probability transition matrices and beliefs about future states. The
% particular inversion scheme used here is spm_MDP_select, which uses a
% mean-field approximation between hidden control and hidden states. It is
% assumed that the agent believes that it will select a particular action
% (accept or decline) at a particular time.
%
% We run an exemplar game, examine the distribution of time to acceptance
% as a function of different beliefs (encoded by parameters of the
% underlying Markov process) and demonstrate how the model can be used to
% produce trial-specific changes in uncertainty � or how one can use
% behaviour to identify the parameters used by a subject.
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_MDP.m 4804 2012-07-26 13:14:18Z karl $
 
% set up and preliminaries
%==========================================================================
T     = 16;                           % number of offers
Pa    = 1/2;                          % probability of a high offer
Pb    = 1/8;                         % probability of withdrawn offer
Plos  = @(t,Pb)(1 - (1 - Pb).^t);
Pwin  = @(T,Pa)(1 - (1 - Pa)^(1/T));
   
% transition probabilities (B{1} - decline; B{2} - accept)
%--------------------------------------------------------------------------
for t = 1:T
    
    a       = Pwin(T,Pa);
    b       = Plos(t,Pb);
    B{t,1}  = [(1 - a + a*b - b) 0 0 0;
                b                1 0 0;
                0                0 1 0;
                a*(1 - b)        0 0 1];
    
    B{t,2}  = [ 0 0 0 0;
                0 1 0 0;
                1 0 1 0;
                0 0 0 1];
end
      
 
% initial state
%--------------------------------------------------------------------------
S     = [1 0 0 0]';
 
% priors over final state (exp(utility))
%--------------------------------------------------------------------------
C     = [1 1 2 3]';
 
% MDP Structure
%==========================================================================
MDP.T = T;                          % process depth (the horizon)
MDP.S = S;                          % initial state
MDP.B = B;                          % transition probabilities (priors)
MDP.C = C;                          % terminal cost probabilities (priors)
 
% Generate process (with continuous low offers)
%==========================================================================
 
% True transition probabilities (retaining low offer for all trials)
%--------------------------------------------------------------------------
G{1,1}  = [1 0 0 0;
           0 1 0 0;
           0 0 1 0;
           0 0 0 1];
 
G{1,2}  = G{1,1};
MDP.G   = G;


% solve - an example game
%==========================================================================
MDP.plot   = 3;                     % plot convergence
% spm_MDP_select(MDP);
 
 
% probability distribution over time to act: P(1,:) is no action
%--------------------------------------------------------------------------
PrT        = @(P)[1 cumprod(P(1,1:end - 1))].*P(2,:);
PrA        = @(P)P(2,:);
MDP.plot   = 0;                        % plot convergence
MDP.lambda = 1/16;                     % action sensitivity (free energy)
beta       = 1;                        % action sensitivity (utilitiy)


% illustrate dependency on latency w.r.t. parameters
%==========================================================================
spm_figure('GetWin','Figure 1'); clf
 

% Precision of beliefs about final state
%--------------------------------------------------------------------------
DP    = MDP;
C     = [1 1 2 4]';
p     = linspace(0,12,16);

for i = 1:length(p)
    
    % probability of action
    %----------------------------------------------------------------------
    DP.C      = C*p(i);
    PF(:,:,i) = spm_MDP_select(DP);
    PE(:,:,i) = spm_MDP_select(DP,beta);
    
    % expected utility
    %----------------------------------------------------------------------
    UF(i,:)   = PrU(PrT(PF(:,:,i)),DP.B,DP.C);
    UE(i,:)   = PrU(PrT(PE(:,:,i)),DP.B,DP.C);

end
 
subplot(2,2,1)
imagesc(1:(T - 1),p,(1 - PF))
xlabel('latency (offers)','FontSize',12)
ylabel('Precision of beliefs','FontSize',12)
title('Precision (FE)','FontSize',16)
axis square


% compare with expected utility
%--------------------------------------------------------------------------
subplot(2,2,2)
imagesc(PE)
imagesc(1:(T - 1),p,(1 - PE))
xlabel('latency (offers)','FontSize',12)
ylabel('Precision of beliefs','FontSize',12)
title('Precision (EU)','FontSize',16)
axis square


% beliefs about final state
%--------------------------------------------------------------------------
DP    = MDP;
C     = [1 1 2 4]';
p     = linspace(0,8,16);

for i = 1:length(p)
    DP.C      = C;
    DP.C(3)   = p(i);
    PF(i,:)   = PrY(spm_MDP_select(DP));
    PE(i,:)   = PrY(spm_MDP_select(DP,beta));
end
 
subplot(2,2,3)
imagesc(1:(T - 1),p,(1 - PF))
xlabel('latency (offers)','FontSize',12)
ylabel('Utility of high offer','FontSize',12)
title('Terminal utility (FE)','FontSize',16)
axis square


% compare with expected utility
%--------------------------------------------------------------------------
subplot(2,2,4)
imagesc(PE)
imagesc(1:(T - 1),p,(1 - PE))
xlabel('latency (offers)','FontSize',12)
ylabel('Utility of high offer','FontSize',12)
title('Terminal utility (EU)','FontSize',16)
axis square





return
 
% high offer
%--------------------------------------------------------------------------
p     = linspace(0,1/2,32);
DP  = MDP; clear Py str
for i = 1:length(p)
    
    % transition probabilities
    %----------------------------------------------------------------------
    for t = 1:T
        a   = Pwin(T,p(i));
        b   = Plos(t,Pb);
        DP.B{t,1}([1 2 4],1) = [1 - a + a*b - b; b; a*(1 - b)];        
    end
    
    P       = spm_MDP_select(DP);
    Py(i,:) = PrY(P);
    str{i}  = num2str(p(i));
end
 
subplot(2,2,1)
imagesc(Py)
imagesc(1:(T - 1),p,(1 - Py))
xlabel('latency (offers)','FontSize',12)
ylabel('P(high offer)','FontSize',12)
title('high offer probability ','FontSize',16)
axis square
 
% offer withdrawal
%--------------------------------------------------------------------------
p     = linspace(1/16,1,32);
DP  = MDP; clear Py str
for i = 1:length(p)
    
    % transition probabilities
    %----------------------------------------------------------------------
    for t = 1:T
        a   = Pwin(T,Pa);
        b   = Plos(t,p(i));
        DP.B{t,1}([1 2 4],1) = [1 - a + a*b - b; b; a*(1 - b)];      
    end
    
    P       = spm_MDP_select(DP);
    Py(i,:) = PrY(P);
    str{i}  = num2str(p(i));
end
 
subplot(2,2,2)
imagesc(Py)
imagesc(1:(T - 1),p,(1 - Py))
xlabel('latency (offers)','FontSize',12)
ylabel('P(withdrawal)','FontSize',12)
title('offer withdrawal','FontSize',16)
axis square
 
 
% beliefs about final state
%--------------------------------------------------------------------------
p     = linspace(0,16,32);
DP  = MDP; clear Py str
for i = 1:length(p)
    DP.C(4) = p(i);
    P         = spm_MDP_select(DP);
    Py(i,:)   = PrY(P);
    str{i}    = num2str(p(i));
end
 
subplot(2,2,3)
imagesc(Py)
imagesc(1:(T - 1),p,(1 - Py))
xlabel('latency (offers)','FontSize',12)
ylabel('Belief in high offer','FontSize',12)
title('Behaviour and terminal cost','FontSize',16)
axis square

 
return
 
% Changes in uncertainty (Entropy) over successive choices
%==========================================================================
spm_figure('GetWin','Figure 2'); clf
 
P  = spm_MDP_select(MDP);
 
 
% uncertainty about current action
%--------------------------------------------------------------------------
H  = sum(-P.*log(P),1);
 
subplot(2,2,1)
plot(1:length(H),H,'.','MarkerSize',16), hold on
plot(1:length(H),H,':'), hold off
xlabel('latency','FontSize',12)
ylabel('Entropy','FontSize',12)
title('current action','FontSize',16)
axis square
 
 
% uncertainty about future states
%--------------------------------------------------------------------------
j  = 1:(T - 1);
H  = sum(-Q(:,j).*log(Q(:,j)));  
 
subplot(2,2,2)
plot(1:length(H),H,'.','MarkerSize',16), hold on
plot(1:length(H),H,':'), hold off
xlabel('latency','FontSize',12)
ylabel('Entropy','FontSize',12)
title('future states','FontSize',16)
axis square
 
 
return
 
 
 
% simulate multiple trials and record when an offer was accepted
%==========================================================================
spm_figure('GetWin','Figure 3'); clf
 
% trials
%--------------------------------------------------------------------------
for i = 1:32
    [P,Q,R,S,U] = spm_MDP_select(MDP);
    try
        Y(i) = find(U(2,:),1);
    end
    fprintf('trial %0.00f\n',i);
end
 
% probability distribution over time to act
%--------------------------------------------------------------------------
Py    = PrY(P);
 
 
% plot
%--------------------------------------------------------------------------
subplot(2,2,1)
hist(Y,1:T);
xlabel('choice latency','FontSize',12)
ylabel('sample frequnecy','FontSize',12)
title('sample distribution of latencies','FontSize',16)
axis square
 
subplot(2,2,2)
bar(Py)
xlabel('choice latency','FontSize',12)
ylabel('probability','FontSize',12)
title('predicted probability','FontSize',16)
axis square
 
 
% Infer prior beliefs from observed responses (meta-modelling)
%==========================================================================
p     = linspace(1/32,1/2,32);
DP  = MDP;
for i = 1:length(p);
    
    % transition probabilities
    %----------------------------------------------------------------------
    for t = 1:T
        a = Pwin(T,Pa);
        b = Plos(t,p(i));
        DP.B{t,1}([1 2 4],1) = [1 - a + a*b - b; b; a*(1 - b)];       
    end
    
    % get likelihood for this parameter
    %----------------------------------------------------------------------
    P     = spm_MDP_select(DP);
    Py    = PrY(P);
    L(i)  = sum(log(Py(Y)));
    
end
 
% approximate the MAP with the ML and use the Laplace assumption
%--------------------------------------------------------------------------
[l i] = max(L);
dp    = p(2) - p(1);
dLdpp = (L(i + 1) - L(i) - L(i) + L(i - 1))/(dp^2);
Cp    = inv(-dLdpp);
Ep    = p(i);
 
 
% plot likelihood
%--------------------------------------------------------------------------
subplot(2,2,3)
plot(p,L)
xlabel('latency','FontSize',12)
ylabel('probabaility','FontSize',12)
title('log-likelihood','FontSize',16)
axis square
    
% plot posterior
%--------------------------------------------------------------------------
subplot(2,2,4)
plot(p,spm_Npdf(p,Ep,Cp)), hold on
plot([Pb Pb],[0 8],':'),   hold off
xlabel('latency','FontSize',12)
ylabel('probability','FontSize',12)
title('posterior probability','FontSize',16)
axis square


return


% expected utility
%--------------------------------------------------------------------------
function EC = PrU(P,B,C)

Ns    = size(C,1);
Nt    = size(P,2);
Na    = size(P,1);
PT    = 0;
for j = 1:Na
    for t = 1:Nt
        H = sparse(1,1,1,Ns,1);
        for k = 1:Nt
            if k == t
                H = B{k,1 + j}*H;
            else
                H = B{k,1}*H;
            end
            
        end
        PT = PT + P(j,t)*H;
    end
end
EC = PT'*C;







