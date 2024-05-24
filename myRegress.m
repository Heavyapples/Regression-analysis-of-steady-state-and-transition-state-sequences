% myRegress函数
function [slope, intercept] = myRegress(yS,X)
% 确保输入是列向量
yS = yS(:);
X = X(:);

meanX = mean(X);
meanY = mean(yS);
covXY = sum((X-meanX).*(yS-meanY));
varX = sum((X-meanX).^2);
slope = covXY / varX;
intercept = meanY - slope * meanX;
end