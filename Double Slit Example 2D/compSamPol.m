clc
close all
clear all
load('paramDoubleSlit');

% settings
initState = [1;1];
currentTime = 0.5;
constraintType = 2;
param.numSample = 10000;

% overwrite parameters
param.barrierSide = 0.2;
param.barrierZ = [10;-10;-10;10];
param.inputConstraint = [1 1;-1 -1];
param.stateInputConstraint_F = @(x)[-20 0;20 0];
param.stateInputConstraint_e = @(x)[-abs(x(2));-abs(x(2))];

% plot figures
figure('Name',"Sampling Policy Comparison")
edge = linspace(-0.1,0.1,40);
subplot(2,2,1)
Temp1 = plotSample(initState,currentTime,param,constraintType,'proj');
Temp12 = Temp1(1,1,:);
noiseInput1 = Temp12(:);
title("Re-Projection",'fontsize',param.fontSize)
hold on
subplot(2,2,3)
histogram(noiseInput1,edge)
title("u_1 Histogram",'fontsize',param.fontSize)
subplot(2,2,2)
Temp2 = plotSample(initState,currentTime,param,constraintType,'trandn');
Temp22 = Temp2(1,1,:);
noiseInput2 = Temp22(:);
title("Truncated Normal Distribution",'fontsize',param.fontSize)
hold on
subplot(2,2,4)
histogram(noiseInput2,edge)
title("u_1 Histogram",'fontsize',param.fontSize)
hold on

function [noiseInput] = plotSample(initState,currentTime,param,constraintType,reSamPolicy)
% plotSample function.

%% load parameters
simHorizon = currentTime:param.simInterval:param.simEnd;

%% compute trajectories and collision
[trajectory,noiseInput] = computeTrajectory(initState,simHorizon,param,constraintType,reSamPolicy);
barrierStep = find(simHorizon==param.barrierTime*max(param.barrierX));
isBarrierDetected = detectBarrier(trajectory,param,barrierStep);
feasiblePath = trajectory(:,:,~isBarrierDetected);
inFeasiblePath = trajectory(:,:,isBarrierDetected); 
cost = reshape(0.5*(feasiblePath(1,end,:).^2+feasiblePath(2,end,:).^2),[],1);
sampleWeight = (max(cost)-cost)/(max(cost)-min(cost));
numcolor = size(feasiblePath,3);
colorMat = jet(numcolor);

if numel(cost) == 0 % no feasible path
    fprintf('No Feasible Path\n');
    if numel(size(inFeasiblePath)) ~= 3
            plot3(simHorizon(1:barrierStep),inFeasiblePath(1,1:barrierStep),inFeasiblePath(2,1:barrierStep),'color','k');
            hold on
    else
        for n = 1:size(inFeasiblePath,3)
            plot3(simHorizon(1:barrierStep),inFeasiblePath(1,1:barrierStep,n),inFeasiblePath(2,1:barrierStep,n),'color','k');
            hold on
        end
    end
elseif numel(cost) == 1 % only one feasible path -> sampleWeight == NaN
    plot3(simHorizon,feasiblePath(1,:),feasiblePath(2,:),'color','r');
    hold on
else
    [~,~,bin] = histcounts(sampleWeight,linspace(0,1,numcolor));
    % plot truncated samples
    if ~isempty(feasiblePath)
        if numel(size(feasiblePath)) ~= 3
                plot3(simHorizon,feasiblePath(1,:),feasiblePath(2,:),'color',colorMat);
                hold on
        else
            for n = 1:size(feasiblePath,3)
                plot3(simHorizon,feasiblePath(1,:,n),feasiblePath(2,:,n),'color',colorMat(bin(n),:));
                hold on
            end
        end
    end
    if ~isempty(inFeasiblePath)
        if numel(size(inFeasiblePath)) ~= 3
                plot3(simHorizon(1:barrierStep),inFeasiblePath(1,1:barrierStep),inFeasiblePath(2,1:barrierStep),'color','k');
                hold on
        else
            for n = 1:size(inFeasiblePath,3)
                plot3(simHorizon(1:barrierStep),inFeasiblePath(1,1:barrierStep,n),inFeasiblePath(2,1:barrierStep,n),'color','k');
                hold on
            end
        end
    end
end

colormap(jet);
colorbar('west','Ticks',[0 1],'TickLabels',{'Low Weight','High Weight'});

% plot barrier
fill3(param.barrierTime*param.barrierX,param.barrierSide*param.barrierY,param.barrierSide*param.barrierZ,'k');
hold on

% figure settings
passRate = (1-sum(isBarrierDetected)/param.numSample)*100;
title("Sample Visualization"+" "+"(Pass Rate:"+" "+num2str(passRate,3)+"%)",'fontsize',param.fontSize)
xlabel("Time",'fontsize',param.fontSize)
ylabel("x_1",'fontsize',param.fontSize)
zlabel("x_2",'fontsize',param.fontSize)
axisLimit = axis;
axis ([0 param.simEnd -max(abs(axisLimit(3:6))) max(abs(axisLimit(3:6))) -max(abs(axisLimit(3:6))) max(abs(axisLimit(3:6)))])
hold on

% plot initial state
plot3(currentTime,initState(1),initState(2),'.k','MarkerSize',20)
hold on

end