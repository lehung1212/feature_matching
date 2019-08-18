function features = kpfeat(image, keypoints)
% KPFEAT Returns the matrix of feature desriptors from a list of keypoints.
%
% FEATURES = KPFEAT(IMAGE, KEYPOINTS) where IMAGE is the double-converted
% grayscale input image. KEYPOINTS the corresponding logical matrix of keypoint
% feature detections the same dimensions as the input image. The function
% returns an N by 64 matrix of feature descriptors, where N is the number
% of detected keypoints. The contents of the row in the matrix might be
% NaN, since some keypoints may be out of bounds within the input image.

[rows, cols] = find(keypoints);

total_points = length(find(keypoints));

m = zeros([total_points 64]);

g = gkern(5^2);

convImg = conv2(g, g, image, 'same');

downsampled = convImg(1:5:end, 1:5:end);
[downsampled_y, downsampled_x] = size(downsampled);

for k = 1:total_points
    
    point_y = rows(k);
    point_x = cols(k);
    
    x_down = round(point_x / 5);
    y_down = round(point_y / 5);
    
    TL_OFFSET = 3;
    BR_OFFSET = 4;
    
    x_tl = x_down - TL_OFFSET;
    y_tl = y_down - TL_OFFSET;
    
    x_br = x_down + BR_OFFSET;
    y_br = y_down + BR_OFFSET;
    
    if (x_tl < 1 || y_tl < 1 || x_br > downsampled_x || y_br > downsampled_y)
        m(k, :) = NaN;
        continue;
    end

    region = downsampled(y_tl:y_br, x_tl:x_br);
 
    region_mean = mean(region(:));
    region_bias = region - region_mean;
    region_std = std(region_bias(:));
    region_normalized = region_bias ./ region_std;
   
    m(k, :) = region_normalized(:);
end
features = m;
end