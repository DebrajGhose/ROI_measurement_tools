% find out what the patch size of stuff is
clear all
close all
allfilenames = {'2018115_patchsize_22715_2'};
genotype = '22715'; % make sure this is the same as what you are using above!
stacksize = 15;
threshhold = 200;
radius = 10;
load(filename);

allpixels = [];

for filename = allfilenames
    
    for cell = size(myROIs,2) %go through all marked ROIs
        
        
        for stack = 1:stacksize
            
            
            im = imread(['.\Data\', char(filename) , '_w2Confocal 561.TIF'],stack);
            close all;
            imagesc(im);
            circ = drawcircle('Center',myROIs{cell},'Radius',radius);
            BW = createMask(circ,im);
            pixels = im(BW);
            allpixels = [allpixels;pixels];
        end
        
    end
    
end


save(['Pixel_values',genotype],allpixels);

propix = allpixels(allpixels>threshhold);
histogram(propix)




