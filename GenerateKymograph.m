%read and display series of tiff images

clear all
close all

filename = 'Stablized C1-rcc103_s3-1';
cellname = '_1';
load(['ROI_',filename,cellname]) %load ROI files that you created

kymograph= [];

for t = frames(1):frames(end)
    
    myimage = imread( [ filename , '.tif'],t);
    
    linedrawn = ROI{t};
    
    %[cx,cy,Intensity] = improfile(myimage,linedrawn(:,1),linedrawn(:,2),200);

    [r,Intensity] = avgline(linedrawn,myimage,200);
    
    kymograph = [kymograph ; Intensity' ];
    
end


imagesc(kymograph); colormap gray;
blurkym = imgaussfilt(kymograph,1);
blurkym = (blurkym-min(blurkym(:)))./(max(blurkym(:))-min(blurkym(:))); %normalize
thresh = 0.38; blurkym(blurkym<=thresh)=0; blurkym(blurkym>thresh)=1;

figure
imagesc(blurkym); colormap gray;


%% use this function if improfile plots look too noisy.
% This samples points that are perpendicular to the line you drew and
% averages.
function [distance,avgprofile] = avgline(linedrawn,myimage,num)

vector = [linedrawn(2:end,:)-linedrawn(1:end-1,:)];
th = cart2pol( vector(:,1) ,vector(:,2)  );

[deltaxn,deltayn] = pol2cart(th-pi/2,1);
[deltaxp,deltayp] = pol2cart(th+pi/2,1);

deltaxn = [deltaxn;deltaxn(end)]; deltayn = [deltayn;deltayn(end)];
deltaxp = [deltaxp;deltaxp(end)]; deltayp = [deltayp;deltayp(end)];

linen = linedrawn + [deltaxn,deltayn]; %lines on either side of my current line
linep = linedrawn + [deltaxp,deltayp];

[cx,cy,intensity] = improfile(myimage,linedrawn(:,1),linedrawn(:,2),num);
[cx1,cy1,intensity1] = improfile(myimage,linedrawn(:,1),linedrawn(:,2),num);
[cx2,cy2,intensity2] = improfile(myimage,linedrawn(:,1),linedrawn(:,2),num);

avgprofile = [intensity , intensity1 , intensity2 ];
avgprofile = mean(intensity,2);

% while you're at it calculate distance covered by the line you drew

vect = [cx(2:end)-cx(1:end-1) , cy(2:end)-cy(1:end-1)];

[~,r] = cart2pol(vect(:,1),vect(:,2));

distance = cumsum(r);
distance = [0; distance];

end