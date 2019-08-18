%% CSC262: Feature Matching

%% Overview
% In this lab, we will explore the ways in which we could stitch two images
% taken at a slightly different location (assuming only a translational
% transformation) by detecting features and matching them together. In this
% process, we will calculate the Euclidean distances between all feature
% descriptors, sort them from shortest to longest, then threshold out
% certain features which have ambiguous neighbor features. Specifically,
% this lab asks us to compare the nearest-neighbor distance ratio to our
% own threshold. The purpose of this lab is to learn how to manipulate
% group of features detected across multiple images to produce the laIn
% this lab, we will explore the ways in which we could stitch two images
% taken at a slightly different location (assuming only a translational
% transformation) by detecting features and matching them together. In this
% process, we will calculate the Euclidean distances between all feature
% descriptors, sort them from shortest to longest, then threshold out
% certain features which have ambiguous neighbor features. Specifically,
% this lab asks us to compare the nearest-neighbor distance ratio to our
% own threshold. The purpose of this lab is to learn how to manipulate
% group of features detected across multiple images to produce the larger
% frame of the world by diving into a simple panorama technique. rger frame
% of the world by diving into a simple panorama technique.

%%

%Matching Set-Up
run ~/startup.m
%load the paor of images and convert them to doubles 
kpmatch1 = im2double(imread('/home/weinman/courses/CSC262/images/kpmatch1.png'));
kpmatch2 = im2double(imread('/home/weinman/courses/CSC262/images/kpmatch2.png'));

%% Feature Matching
% In this section, we chose one of the two images loaded as the reference
% image. We chose one feature from this reference image, and look for
% it's match in the other image. We attempt this by calculate and compare
% the Euclidean distances between our chosen feature and every features in
% the other image.

% extract keypoint locations with kpdet 
keypoint1 = kpdet(kpmatch1);
keypoint2 = kpdet(kpmatch2);

% extract keypoint descriptors from both images
feature1 = kpfeat(kpmatch1, keypoint1);
feature2 = kpfeat(kpmatch2, keypoint2);

% find the locations of the features in both images
[row1, col1] = find(keypoint1 > 0);
[row2, col2] = find(keypoint2 > 0);

% choose a feature index
k = 100;

% extract the feature as a vector
sampleFeat = feature1(k, :);
% verify that the feature is valid
% isnan(sampleFeat);

% calculate element=wse difference between ref vector and every vector from
% other image
elementDiff = (feature2 - sampleFeat).^2;
% calculate Euclidean distances between chosen feature and all features of
% the other image
EuclideanDist = sqrt((sum(elementDiff()'))');

% sort the patch distances in ascending order
[sortEuclideanDist, EuclideanIndex] = sort(EuclideanDist);

% graph the distances of the top ten closest features
figure;
bar(sortEuclideanDist(1:10));
title('Euclidean distance of top ten closest features');

% Above is our bar plot of the Eucldean distances between our chosen
% reference feature in the first image and the top ten closest features in
% the second image. Our reference image feature does appear to have a match
% in the other image. What we see is that the first feature (very left) of
% the bar plot has a very low Euclidean distance, but the second feature
% has a very high Euclidean distance. This suggests to us that the
% vectorized image feature values of the other image and that of our
% reference image feature only shares one sufficient feature point. Thus,
% the top 1 low Euclidean distance (low anti-similarity, which means high
% similarity) with the top 9 remaining high Euclidean distance (high
% anti-similarity, which means low similarity) feature points indicates
% that the top 1 image feature on the other image represents our reference
% image feature. Therefore, our bar graph shows a very good quality of the
% feature match since this is the result that we want to use to stitch the
% two images, kpmatch1 and kpmatch2.

% calculate the estimated translation from the reference point location of
% the best matching feature in other image
xr = row1(k);
xc = col1(k);

yr = row2(EuclideanIndex(1));
yc = col2(EuclideanIndex(1));

tr = xr - yr;
tc = xc - yc;

%% Visualizing Matching
% We create a visualization of the chosen feature that we match in the two
% images. We draw a line from our chosen feature in the first image to it's
% match that we found in the second image. This visualization, displayed
% below, indicated that we performed our calculation correctly, as the two
% points are indeed of the same object in the images.

% concatenate the reference image and the other image
verticalCat = cat(1, kpmatch1, kpmatch2);
% display concatenated image
figure;
imshow(verticalCat);
hold on;
% draw a line from the feature location in the reference image to the
% putative matching feature in the other image.
line([xc, yc], [xr, yr+264]);
title('Visualization of feature matching');


%%

%Feature Matching Redux
N = 280;
Threshold = 0.5;
% create a Nx2 matrix of translation estimates for all features in
% reference image

transEst = zeros(N, 2);
% rowEst = row1 - tr;
% colEst = col1 - tc; 
% transEst = cat(2, rowEst, colEst);


% for loop to iterate over all descriptors from the reference image
for i = 1:N
    % extract current feature vector from matrix
    curFeat = feature1(i, :);
    % if current feat is invalid, set translation estimate to [NaN NaN] and
    % continue
    if isnan(curFeat)
      transEst(i, :) = [NaN NaN];
      continue;
    end
    % measure the patch distance of the current ref feature to all the
    % features in other image
    curDiff = (feature2 - curFeat).^2;
    curDist = sqrt((sum(curDiff()'))');
    % sor the patch distance and retain sorte indices
    [sortcurDist, curIndex] = sort(curDist);
    % discard the match by setting the translation estimate for current
    % feature to [NaN NaN] and continue
     if (sortcurDist(1)/sortcurDist(2)) > Threshold        
         transEst(i, :) = [NaN NaN];
         continue;
     end
    % set the translational estimate of the matched features
    xrow = row1(i);
    xcol = col1(i);

    yrow = row2(curIndex(1));
    ycol = col2(curIndex(1));
    trow = xrow - yrow;
    tcol = xcol - ycol;
    % record the translational estimate in a 2D array
    transEst(i, :) = [trow tcol];
end

%% Alignment
% In this final section, we calculate a single optimal global alignment by
% finding the least squared solution to the transformation problem. Then,
% we utilize this transformation to stitch the two images, creating a
% single rudimentary panoramic image. We display this image below.

% initiate sum of column and row
sumColumn = 0;
sumRow = 0;
count = 0;
validRow = [N,1];
validCol = [N,1];
% iterate over translation estimate array to calculate the sum of valid
% rows and cols
for i = 1:N
    if isnan(transEst(i, :))
        continue;
    else 
        sumColumn = sumColumn + transEst(i, 2);
        sumRow = sumRow + transEst(i, 1);
        count = count + 1;
        validRow(i) = transEst(i, 1); 
        validCol(i) = transEst(i, 2); 
    end
end

% calculate the least squared solution by taking the mean of the
% translations
avgRow = round(sumRow / count);
avgColumn = round(sumColumn / count);

% store least squared solution in a vector
leastsqrSol = [avgRow, avgColumn];

% calculate the standard deviation of the estimate
stdRow = std(validRow(:));
stdColumn = std(validCol(:));
% average the two images under the translation of the least squared
% solution using the stich procedure
stitchedImg = stitch(kpmatch1, kpmatch2, leastsqrSol);

% display the resulting stiched image
figure;
imshow(stitchedImg);
title('Stiched image from the optimal translation');

%%
% At first viewing of the image above, the stitched result does appear to
% merge the two images well. The overlaping waterfall and the rock
% formation below it are matched by our transformation. However, we noticed
% that the transformation does not perform well in the ege of the
% overlaping area. For example, along the edge of the waterfall and the
% background, we can clearly see mismatched region on the left and right
% side. The middle of this waterfall edge does appear to be much more well
% matched. Other clear artifacts in the stiched image are the lines
% dividing the regions of the overlaping field of view. Along these lines,
% we can clearly recognize the discontinuity of the stitch. We theorize
% that these visible lines could be a direct result of the two images
% having different level of illumination. Another source of discontinuity
% is obviously the continous motion of the waterfall. Since the water
% cannot remain constant between the time interval the two images are
% taken, there must be discontinuity in the stiched image. By this same
% logic, we recognized that the rocky formation is matched well by our
% transformation, since they remain constant between the time the images
% are recorded.

%% Conclusion
% In this lab, we utilized kpdet.m and kpfeat.m functions to detect features
% and derive their feature descriptors. Then, we processed the data so that
% we filter out the invalid features and set them as NaN. We then computed
% the Euclidean distance between one feature and all the other features of
% the other image. After we sorted the distances, we used the
% nearest-neighbor ratio to filter out features which inadequately represent
% a single point on the other image. This means that there might be an
% incorrect point on the other image that has a very similar characteristics
% to the one feature. Then, we calculated the translation estimate for all
% the features in our reference image. We put this into a loop, then
% computed the same for all features. At the end, we produced a panorama
% image that stitched the two images together.

%% Acknowledgement
% We, as partners, were the only contributors to this lab. We referred to
% Piazza to figure out if the translation estimate in rows and columns
% should be rounded. The kpdet and kpfeat functions used in this lab was
% built in the previous lab by a group member. We also utilized directions,
% information, and code snippets from the Feature Matching Lab text
% written by Jerod Weinman for CSC 262: Computer Vision this semester.
% Finally, we also consulted lab write up guidelines published on the
% course website by Jerod Weinman.



