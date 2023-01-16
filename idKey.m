classdef idKey
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties 
        Frame 
        res = 512
        closeMaskConstant = 150      
        closeMaskConstant2 = 75

        FrameCutMask                    % Cutet key
        FrameCut

        theta
        alpha

        k_len

        FrameRot

        FrameKey
        FrameKeyMask
        FrameLabel

        Validity
        isValid = false

        keyProfile
        ID

        extr

        EdgeFrame
    end

    properties (Access = private)

    end


    methods
        function obj = calculate(obj)

            % scale/crop image
            sz = size(obj.Frame);
            scale = (obj.res / min(sz(1:2)));
            obj.Frame = imresize(obj.Frame, scale);
    
            radius = obj.res / 2;
            sz = size(obj.Frame);
            yCenter = sz(1)/2;
            xCenter = sz(2)/2;
    
            xLeft = xCenter - radius;
            wdt = 2 * radius;
            yTop = yCenter - radius;
            hgt = 2 * radius;
            obj.Frame = imcrop(obj.Frame, [xLeft, yTop, wdt - 1, hgt]);I_gray = im2gray(obj.Frame);

            % Rauschen
            zentrum = obj.res/512*300;

            imtrans = fft2(I_gray);
            imtrans = fftshift(imtrans);

            amp = abs(imtrans);
            Htrans = log10(1+amp);
            

            filtfuerH=fspecial("gaussian",zentrum,(zentrum-1)/6+0.2);
            filtfuerH=1-freqz2(filtfuerH,size(Htrans));
            
            Htrans = freqz2(filtfuerH,size(Htrans));

            Htrans = Htrans.*filtfuerH;

%            Htrans = ma < Htrans;

            Htrans=1-Htrans;

            imtransf=imtrans.*Htrans;

            I_gray=ifftshift(imtransf);
            I_gray=ifft2(I_gray);
            I_gray=real(I_gray);

    
            %EdgeFrame on original
            [~,threshold] = edge(I_gray,'canny');
            fudgeFactor = 4;
            I_EdgeFrame = edge(I_gray,'canny',threshold * fudgeFactor);
            obj.EdgeFrame = I_EdgeFrame;

            I_exp = I_EdgeFrame;
            h=strel("sphere",2);
            I_exp = imclose(I_exp,h);
            I_exp = imfill(I_exp,"holes");

            [~, max_xy] = obj.angleKey(I_exp, 180);
            obj.k_len = sqrt((max_xy(1,1)-max_xy(2,1))^2 + (max_xy(1,2)-max_xy(2,2))^2);
    
            obj.FrameCutMask = I_EdgeFrame;
            h=strel("sphere",ceil(obj.k_len / obj.closeMaskConstant ));
            obj.FrameCutMask = imclose(obj.FrameCutMask,h);
            obj.FrameCutMask = imfill(obj.FrameCutMask,"holes");
    
            L = bwlabel(obj.FrameCutMask);
            s = regionprops(logical(L),'centroid');
            cmap = cool(numel(s));
            cmap = cmap(randperm(size(cmap, 1)), :);
            mapped = L;
            for k = 1:numel(s)
                mapped = imoverlay(mapped,L == k, cmap(k,1:3));
            end
            obj.FrameLabel = mapped;

            idx = mode(L(L ~= 0), 'all');
            obj.FrameCutMask = L == idx;
            h = strel("sphere",ceil(obj.k_len / obj.closeMaskConstant2));   
            obj.FrameCutMask = imclose(obj.FrameCutMask,h);                                        % Wo für war das noch mal
            obj.FrameCutMask = imfill(obj.FrameCutMask, "holes");
            
            
            obj.FrameCut = imoverlay( obj.Frame , ~obj.FrameCutMask,"black");
            


            %rotate image
            h=strel("sphere",10);
            obj.theta = obj.angleKey(I_EdgeFrame.*imdilate(obj.FrameCutMask,h), 180);
            
            obj.FrameRot = imrotate( obj.FrameCut , obj.theta - 90);
            
            I_gray = im2gray(obj.FrameRot);
            I_EdgeFrame = edge(I_gray,"sobel");
            
            %shear image (potentiell reverse transform)
            obj.alpha = obj.angleKey(I_EdgeFrame, 45);
            a = deg2rad(obj.alpha);

            % shear image by a
            tform = affine2d([1 0 0; tan(a) 1 0; 0 0 1]);
            obj.FrameRot = imwarp(obj.FrameRot,tform);
            
            %cut black
            I_rot_gray = im2gray(obj.FrameRot);
            horizontalProfile = mean(I_rot_gray, 1) > 0;
            firstColumn = find(horizontalProfile, 1, 'first');
            lastColumn = find(horizontalProfile, 1, 'last');
            subImage = obj.FrameRot(:,firstColumn:lastColumn, :);
            verticalProfile = mean(I_rot_gray, 2) > 0;
            firstColumn = find(verticalProfile, 1, 'first');
            lastColumn = find(verticalProfile, 1, 'last');
            subImage = subImage(firstColumn:lastColumn, :, :);

            obj.FrameKey = subImage;
            obj.FrameKeyMask = imbinarize(im2gray(obj.FrameKey), 0.001);

            
            horizontalProfile = mean(obj.FrameKeyMask, 1);
            [~, j] = max(horizontalProfile);
            if (j < length(horizontalProfile)/2)
                obj.FrameKeyMask = flipdim(obj.FrameKeyMask, 2);
                obj.FrameKey = flipdim(obj.FrameKey, 2);
                j = length(horizontalProfile) - j;
            end
            
            verticalProfile = mean(obj.FrameKeyMask, 2);
            [~, i] = max(verticalProfile);
            if (i < length(verticalProfile)/2)
                obj.FrameKeyMask = flipdim(obj.FrameKeyMask, 1);
                obj.FrameKey = flipdim(obj.FrameKey, 1);
                i = length(verticalProfile) - i;
            end

            % Check validity
            sizeMask = size(obj.FrameKeyMask);

            Mask = zeros(sizeMask);
            Mask((sizeMask(1)*1/2) : (sizeMask(1)*3/4),(sizeMask(2)*1/10) : (sizeMask(2)*9/10)) = 1;

            obj.Validity = sum(Mask.*obj.FrameKeyMask,"all")/sum(Mask,"all");

            % Validity is high enough and key is at least 1.5x as wide as high
            if obj.Validity < 0.6 || sizeMask(2) < 1.5*sizeMask(1)
                obj.isValid = false;

                obj.FrameKeyMask = imoverlay(obj.FrameKeyMask, Mask, "red");

                return;
            else
                obj.isValid = true;
            end
            
            
            %find extreme points
            [~, horizontalProfile] = max(obj.FrameKeyMask);
            i = 1;
            horizontalProfileMirror = max(horizontalProfile) - horizontalProfile;

            while (i < length(horizontalProfile) && horizontalProfileMirror(i) < max(horizontalProfile)-max(horizontalProfile)/1.7)
                 i = i+1;
            end

            horizontalProfile=horizontalProfile(1:i);

            m =[horizontalProfile -horizontalProfile];

            TF = islocalmax(m, 'MinProminence', 1,'MaxNumExtrema',10);
            TF = TF(1:length(TF)/2) + TF(length(TF)/2+1:length(TF));
            heights = TF.*horizontalProfile;
            nonzero = find(heights~=0);
            heights = max(horizontalProfile) - heights;
            obj.extr = [nonzero; heights(nonzero)]';


            obj.keyProfile = max(horizontalProfile) - horizontalProfile;

            x = obj.extr(:,2) - min(obj.extr(:,2));
            x = x/max(x);
            x = num2str(round(x*9)');

            obj.ID = erase(x," ");
        end

        function [theta, max_xy]=angleKey(obj,BW,max_angle)
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
    end
end