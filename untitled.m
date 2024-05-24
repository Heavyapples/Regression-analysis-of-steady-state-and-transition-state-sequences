data = readtable('data4IOT.txt', 'Delimiter', ',', 'HeaderLines', 1, 'ReadVariableNames', false);
S = data{:, 3}; % 获取第三列温度数据，并赋值给变量S
% 一阶差分
numData=length(S);
diffFlag=zeros(1,numData);
apxI=0.1;
i=1;
diffFlag(1)=1;
while i<numData
    i=i+1;
    if abs(S(i-1)-S(i))<apxI
        diffFlag(i)=1;
    end
end
% 生成片段集apxIFrameIndex
apxIFrameIndex=cell(1);
apxIFrameLength=[];
i=1;
k=0;
minStableLength=2;
while i<numData
    while diffFlag(i)==0 && i<numData
        i=i+1;
    end
    if diffFlag(i)==0
        i=i+1;
    end

    if i<numData
        locBuffer=[];
        while diffFlag(i)==1 && i<numData
            locBuffer=[ locBuffer i];
            i=i+1;
        end
        if diffFlag(i)==1
            locBuffer=[ locBuffer i];
            i=i+1;
        end
        kf=length(locBuffer);
        if kf>= minStableLength
            k=k+1;
            apxIFrameIndex{k}= locBuffer;
            apxIFrameLength(k)=length(locBuffer);% 代码调试
        end
    end
end
clear i k locBuffer
% 生成事件序列片段

apxIFrameNum=length(apxIFrameIndex); % 稳态序列数量
eventIndex=cell(1);
k=0;
beginLoc=1;
for i=1:1: apxIFrameNum
    currentFrameIndex=apxIFrameIndex{i};
    firstLoc=currentFrameIndex(1);
    if firstLoc>beginLoc
        tmp.idBuffer=beginLoc:1:firstLoc;
        tmp.flag=0; % 迁移态
        k=k+1;
        eventIndex{k}=tmp;
        beginLoc=currentFrameIndex(end);
    end
    tmp.flag=1;
    tmp.idBuffer=currentFrameIndex;
    k=k+1;
    eventIndex{k}=tmp;
    beginLoc=currentFrameIndex(end);
end
if beginLoc<numData
    tmp.flag=0;
    tmp.idBuffer= beginLoc:1:numData;
    k=k+1;
    eventIndex{k}=tmp;
end
clear beginLoc currentFrameIndex firstLoc i k fullFlag locBuffer tmp tmpFrame
clear apxIFrameNum apxIFrameIndex apxIFrameLength
% 测试代码
eventNum= length(eventIndex);
eventLength=zeros (1, eventNum);
eventType=zeros(1, eventNum);
eventFeature=zeros (2,eventNum);
eventSta=zeros(3,eventNum);
for i=1:1:eventNum
    eventType(i)= eventIndex{i}.flag;
    eventLength(i)=length(eventIndex{i}.idBuffer);

    % 确保输入是列向量
    yS = S(eventIndex{i}.idBuffer)';
    X = (1:eventLength(i))';

    [slope, intercept ]= myRegress(yS,X);

    % 调试信息
    disp(['Event ', num2str(i), ': Slope size = ', num2str(size(slope)), ', Intercept size = ', num2str(size(intercept))]);

    eventIndex{i}.slope = slope;
    eventIndex{i}.intercept= intercept;
    eventFeature(1,i)=slope;
    eventFeature(2,i)=intercept;
    eventIndex{i}.mean=mean(S(eventIndex{i}.idBuffer));
    eventIndex{i}.std=std(S(eventIndex{i}.idBuffer));
    eventSta(1,i)= eventIndex{i}.mean;
    eventSta(2,i) = eventIndex{i}.std;
    eventSta(3,i)= eventIndex{i}.flag;
end
clear i
