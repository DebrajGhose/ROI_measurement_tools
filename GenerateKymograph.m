%read and display series of tiff images

clear all
close all

filename = 'GhoseFRAP_17966_202_R3D';
load(['ROI_',filename,'.mat']) %load ROI files that you created

kymograph= [];

for t = 1:41
    
    myimage = imread( [ filename , '.tif'],t);
    
    linedrawn = ROI{t};
    
    [cx,cy,Intensity] = improfile(myimage,linedrawn(:,1),linedrawn(:,2),200);

    kymograph = [kymograph ; Intensity' ];
    
end


imagesc(kymograph); colormap gray;


%% incomplete -- use this function if improfile plots look too noisy.
% This samples points that are perpendicular to the line you drew and
% averages.
function [avgprofile] = avgline(linedrawn,myimage)



vector = [linedrawn(2:end,:)-linedrawn(1:end-1,:)];
th = cart2pol( vector(:,1) ,vector(:,2)  );


[deltaxn,deltayn] = pol2cart(th-pi/2,1);
[deltaxp,deltayp] = pol2cart(th+pi/2,1);

deltaxn = [deltaxn;deltaxn(end)]; deltayn = [deltayn;deltayn(end)];
deltaxp = [deltaxp;deltaxp(end)]; deltayp = [deltayp;deltayp(end)];

linen = linedrawn + [deltaxn,deltayn]; %lines on either side of my current line
linep = linedrawn + [deltaxp,deltayp];


end