I=imread("Key1.jpg");
id1 = idKey(I);

I=imread("Key2.jpg");
id2 = idKey(I);


if (length(id2) > length(id1))
    id1 = imresize(id1, length(id2)./length(id1));
else
    id2 = imresize(id2, length(id1)./length(id2));
end

id1 = id1(:,1);
id2 = id2(:,1);

plot(abs(id1 - id2), "r*");

diff = sum(abs(id1 - id2)) + " Failure"

function id=idKey(I)
    res = 512;

    %scale/crop image
    sz = size(I);
    scale = (res / min(sz(1:2)));
    I = imresize(I, scale);
    
    radius = res / 2;
    sz = size(I);
    yCenter = sz(1)/2;
    xCenter = sz(2)/2;
    
    xLeft = xCenter - radius;
    wdt = 2 * radius;
    yTop = yCenter - radius;
    hgt = 2 * radius;
    I = imcrop(I, [xLeft, yTop, wdt - 1, hgt]);
    
    
    %sobel on original
    I_gray = im2gray(I);
    I_sobel = edge(I_gray,"sobel");

    I_exp = I_sobel;
    h=strel("sphere",2);
    I_exp = imclose(I_exp,h);
    I_exp = imfill(I_exp,"holes");

    [theta, max_xy] = angle(I_exp, 180);
    k_len = sqrt((max_xy(1,1)-max_xy(2,1))^2 + (max_xy(1,2)-max_xy(2,2))^2)
    
    I_cut = I_sobel;
    h=strel("sphere",ceil(k_len/75));
    I_cut = imclose(I_cut,h);
    I_cut = imfill(I_cut,"holes");
    
    L = bwlabel(I_cut);
    idx = mode(L(find(L ~= 0)), 'all');
    I_cut = L == idx;
    h = strel("sphere",ceil(k_len/70));
    I_cut = imclose(I_cut,h);
    I_cut = imfill(I_cut, "holes");
    
    
    I = imoverlay(I,~I_cut,"black");
    
    %rotate image
    theta = angle(I_sobel, 180);
    theta
    I_rot = imrotate(I,theta - 90);
    
    I_gray = im2gray(I_rot);
    I_sobel = edge(I_gray,"sobel");
    
    %shear image (potentiell reverse transform)
    a = angle(I_sobel, 45)
    a = deg2rad(a);
    % shear image by a
    tform = affine2d([1 0 0; tan(a) 1 0; 0 0 1]);
    I_rot = imwarp(I_rot,tform);
    
    %cut black
    I_rot_gray = im2gray(I_rot);
    horizontalProfile = mean(I_rot_gray, 1) > 0;
    firstColumn = find(horizontalProfile, 1, 'first');
    lastColumn = find(horizontalProfile, 1, 'last');
    subImage = I_rot(:,firstColumn:lastColumn, :);
    verticalProfile = mean(I_rot_gray, 2) > 0;
    firstColumn = find(verticalProfile, 1, 'first');
    lastColumn = find(verticalProfile, 1, 'last');
    subImage = subImage(firstColumn:lastColumn, :, :);
    key = subImage;
    mask = imbinarize(im2gray(key), 0.001);
    
    horizontalProfile = mean(mask, 1);
    [m, j] = max(horizontalProfile);
    if (j < length(horizontalProfile)/2)
        mask = flipdim(mask, 2);
        key = flipdim(key, 2);
        j = length(horizontalProfile) - j;
    end
    
    verticalProfile = mean(mask, 2);
    [m, i] = max(verticalProfile);
    if (i < length(verticalProfile)/2)
        mask = flipdim(mask, 1);
        key = flipdim(key, 1);
        i = length(verticalProfile) - i;
    end
    
    
    %find extreme points
    [m, horizontalProfile] = max(mask);
    
    
    % hold on
    % plot(j,i,'g*');
    % m = horizontalProfile;
    % TF = islocalmax(m, 'MinProminence', 3) + islocalmin(m, 'MinProminence', 3);
    % 
    % heights = TF.*m;
    % nonzero = find(heights~=0);
    % extr = [nonzero; heights(nonzero)]';
    % 
    % %get key profile
    % gap = diff(extr(:,1));
    % idx = find(gap >= max(gap)*0.8);
    % gap(idx(1));
    % profile = [[0 i]; extr(1:idx(1),:)];
    % profile(:,2) = max(profile(:,2)) - profile(:,2);
    % 
    % plot(profile(:,1), i - profile(:,2),'r-',"LineWidth",3);
    % hold off
    
    profile = [1:length(horizontalProfile); max(horizontalProfile) - horizontalProfile]';
    
    simple = round(profile(:,2)/max(profile(:,2))*16);
    mode(simple);
    plat = find(simple == mode(simple));
    plat = plat(1);
    
    profile = profile(1:plat, 2);
    id = profile;
end

function [theta, max_xy]=angle(BW,max_angle)
    [H,T,R]=hough(BW);
    
    P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
    lines = houghlines(BW,T,R,P,'FillGap',5,'MinLength',7);
    max_len = 0;
    max_xy = [];
    theta = 0;
    for k = 1:length(lines)
       xy = [lines(k).point1; lines(k).point2];

       len = norm(lines(k).point1 - lines(k).point2);
       if ( len > max_len && lines(k).theta < max_angle && lines(k).theta > -max_angle)
          max_len = len;
          max_xy = xy;
          theta=lines(k).theta;
       end
    end
end
