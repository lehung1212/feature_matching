function logic_detect = kpdet(img)
% KPDET finds the logical detection of a given image.
%
%  LOGIC_DETECT = KPDET(IMG) Computes the determinant and trace matrices of
%  the image IMG, and using a threshold to eliminate weaker responses in
%  the ratio of the determinant and trace to find the logical detection.
run ~/startup.m
img = im2double(img); % make sure it's a double

% get kernels for blurring and finding components of directional derivative
gauss = gkern(1);
gauss1deriv = gkern(1,1);
blurKern = gkern(1.5^2);

xDirectional = conv2(gauss, gauss1deriv, img, 'same');
yDirectional = conv2(gauss1deriv, gauss, img, 'same');

% find elements of the A matrix
Ix2blurred = conv2(blurKern, blurKern, xDirectional.^2, 'same');
Iy2blurred = conv2(blurKern, blurKern, yDirectional.^2, 'same');
IxIyblurred = conv2(blurKern, blurKern, xDirectional.*yDirectional, 'same');

det = Ix2blurred .* Iy2blurred - IxIyblurred.^2;
trace = Ix2blurred + Iy2blurred;

% get determinant component divided by trace matrix
det_tr = det ./ trace;

threshold = 5.24e-4;

% apply threshold to image, isolating highly localizable points
m = maxima(det_tr);
% figure;
% imshow(m, []);
% 
t = (det_tr > threshold);
% figure;
% imshow(t, []);

logic_detect = maxima(m & t);

end

