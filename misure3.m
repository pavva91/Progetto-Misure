%% Load (rgb)image by user
[fname,path] = uigetfile('.jpg', 'Select an image');
fname = strcat(path,fname);
[data,map] = imread(fname);  

figure, imshow(data), title('Original image');

%% Looking for some info about the image
infodata = imfinfo(fname);
switch infodata.ColorType
    case 'indexed'
        rgbImage = ind2rgb(data,map);
        rgbImage = uint8(255 * rgbImage);
        grayImage = rgb2gray(rgbImage);
    case 'truecolor'
        rgbImage = data;
        grayImage = rgb2gray(rgbImage);
    case 'grayscale'
        grayImage = data;
end

%% Use a median filter to filter out noise
grayImage = medfilt2(grayImage, [3 3]);
figure, imshow(grayImage), title('Grayscale image');

%% Convert the resulting grayscale image into a binary image:
% - Method: adaptive -> method used to binarize image
% - ForegroundPolarity: bright -> indicate that the foreground is brighter
%   than background
% - Sensivity: 0.1 -> Sensitivity factor for adaptive thresholding
%   specified as a value in the range [0 1]. 
%   A high sensitivity value leads to thresholding more pixels as foreground,
%   at the risk of including some background pixels.
bwImage = imbinarize(grayImage, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.45);
bwImage2 = imcomplement(bwImage);

% Remove objects smaller than 500px and greather 5000px
% bwImage = xor(bwareaopen(bwImage,400), bwareaopen(bwImage,5000));
figure, imshow(bwImage), title('Binary image');
figure, imshow(bwImage2), title('White over black image');

ans1 = 'Yes';
while (strcmpi(ans1, 'Yes'))
    msg1 = sprintf('Do you want to remove objects smaller than x pixels and bigger than y pixels?');
    ans1 = questdlg(msg1, 'Answer', 'Yes', 'No', 'Yes');
    if strcmpi(ans1, 'Yes')       
        prompt = {'Smaller than ...','Bigger than ...'};
        dlg_title = 'Input';
        num_lines = 1;
        defaultans = {'500','5000000'};
        ans2 = inputdlg(prompt, dlg_title, num_lines, defaultans);
        bwImage2 = xor(bwareaopen(bwImage2,str2double(ans2(1))), bwareaopen(bwImage2,str2double(ans2(2))));
        imshow(bwImage2), title('W/B image');
    end
end

% Find connected components in binary image
bw = bwconncomp(bwImage2, 8);
numObjects = bw.NumObjects;

% Get a set of properties for each labeled region:
% - Area: number of pixel in the region
% - BoundingBox: smallest rectangle containing the region, 1*4 vector that
%   contain x and y of upper left corner, width and heigth of rectangle
% - Centroid: center of mass of the region
stats = regionprops(bw, 'Area', 'BoundingBox', 'Centroid');

batot = zeros(1);
bbtot = zeros(1,4);
bctot = zeros(1,2);
A = zeros(1,2);
B = zeros(1,2);
C = zeros(1,2);
D = zeros(1,2);
E = zeros(1,2);
F = zeros(1,2);
G = zeros(1,2);
H = zeros(1,2);
L = zeros(1,2);
LRAP = zeros(1);
result = rgbImage;

for object = 1:length(stats)
    ba = stats(object).Area;
    bb = stats(object).BoundingBox;
    bc = stats(object).Centroid;
    
    % Save value of ba,bb,bc into different matrix
    batot(object,1) = ba;
    for b = 1:4
        bbtot(object,b) = bb(1,b);
    end
    for c = 1:2
        bctot(object,c) = bc(1,c);
    end
    
    % Find value of rectangular box and save it on the total matrix
    a = [bb(1,1) bb(1,2)];
    b = [bb(1,1)+bb(1,3) bb(1,2)];
    c = [bb(1,1)+bb(1,3) bb(1,2)+bb(1,4)];
    d = [bb(1,1) bb(1,2)+bb(1,4)];
    
    A(object,1) = a(1,1);
    A(object,2) = a(1,2);
    B(object,1) = b(1,1);
    B(object,2) = b(1,2);    
    C(object,1) = c(1,1);
    C(object,2) = c(1,2);    
    D(object,1) = d(1,1);
    D(object,2) = d(1,2);
    
    %% Find value of polygon box
    % E
    ye = a(1,2);
    dec = ye;
    ye = ceil(ye);
    dec = ye-dec;
    
    x1 = 0;
    x2 = 0;
    for x = fix(a(1,1)):fix(b(1,1))
        if and(bwImage2(ye,x)==1, x1==0)
            x1=x;
        elseif and(bwImage2(ye,x)==1, x1~=0) 
            if or(x2==0, x>x2)
                x2=x;
            end
        end
    end
    if x2==0
        x2=x1;
    end
    
%     xe = x2 - ( (x2 - x1) / 2 ) + dec;
    xe = max(x1,x2);
    xe = xe + dec;
    ye = ye - dec;
    e = [xe ye];
    e1 = [x1 ye];
    e2 = [x2 ye];
       
    % F
    xf = b(1,1);
    dec = xf;
    xf = fix(xf);
    dec = dec-xf;
    
    y1 = 0;
    y2 = 0;
    for y = fix(b(1,2)):fix(c(1,2))
        if and(bwImage2(y,xf)==1, y1==0)
            y1=y;
        elseif and(bwImage2(y,xf)==1, y1~=0)
            if or(y2==0, y>y2)
                y2=y;
            end
        end
    end
    if y2==0
        y2=y1;
    end
    
    xf = xf + dec;
%     yf = y2 - ( (y2 - y1) / 2 ) + dec;
    yf = max(y1,y2);
    yf = yf + dec;
    f = [xf yf];
    f1 = [xf y1];
    f2 = [xf y2];
    
    % G
    yg = a(1,2)+bb(1,4);
    dec = yg;
    yg = fix(yg);
    dec = dec-yg;
    
    x1 = 0;
    x2 = 0;
    for x = fix(a(1,1)):fix(b(1,1))
        if and(bwImage2(yg,x)==1, x1==0)
            x1=x;
        elseif and(bwImage2(yg,x)==1, x1~=0)
            if or(x2==0, x>x2)
                x2=x;
            end
        end
    end
    if x2==0
        x2=x1;
    end
    
%     xg = x2 - ( (x2 - x1) / 2 ) + dec;
    xg = min(x1,x2);
    xg = xg - dec;
    yg = yg + dec;
    g = [xg yg];
    g1 = [x1 yg];
    g2 = [x2 yg];
        
    % H
    xh = b(1,1)-bb(1,3);
    dec = xh;
    xh = ceil(xh);
    dec = xh-dec;
    
    y1 = 0;
    y2 = 0;
    for y = fix(b(1,2)):fix(c(1,2))
        if and(bwImage2(y,xh)==1, y1==0)
            y1=y;
        elseif and(bwImage2(y,xh)==1, y1~=0)
            if or(y2==0, y>y2)
                y2=y;
            end
        end
    end
    if y2==0
        y2=y1;
    end
    
    xh = xh - dec;
%     yh = y2 - ( (y2 - y1) / 2 ) + dec;
    yh = min(y1,y2);
    yh = yh - dec;
    h = [xh yh];
    h1 = [xh y1];
    h2 = [xh y2];
    
    E(object,1) = e(1,1);
    E(object,2) = e(1,2);
    F(object,1) = f(1,1);
    F(object,2) = f(1,2);
    G(object,1) = g(1,1);
    G(object,2) = g(1,2);
    H(object,1) = h(1,1);
    H(object,2) = h(1,2);
    
    % Bound the object in a polygon box
    % insertShape(image, shape, position, characteristics, charact_value)
%     polygon = [e(1,1) e(1,2) f(1,1) f(1,2) g(1,1) g(1,2) h(1,1) h(1,2)];
    polygon = [e1(1,1) e1(1,2) e2(1,1) e2(1,2) f1(1,1) f1(1,2) f2(1,1) f2(1,2) g2(1,1) g2(1,2) g1(1,1) g1(1,2)  h2(1,1) h2(1,2) h1(1,1) h1(1,2)];
    result = insertShape(result, 'Polygon', polygon, 'Color', 'green', 'LineWidth', 2);
%     result2 = insertShape(result, 'Rectangle', bb, 'Color', 'blue', 'LineWidth', 2);
    % insertText(image, position, pos_value, characteristics, charact_value)
    % default -> BoxColor:yellow - FontColor: black
    result = insertText(result, [bb(1,1)-15 bb(1,2)], object, 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'green');

    % Define the length of the sides of the polygon from e1 to h1
    L(object,1) = pdist([e1;e2],'euclidean');
    L(object,2) = pdist([e2;f1],'euclidean');
    L(object,3) = pdist([f1;f2],'euclidean');
    L(object,4) = pdist([f2;g2],'euclidean');
    L(object,5) = pdist([g2;g1],'euclidean');
    L(object,6) = pdist([g1;h2],'euclidean');
    L(object,7) = pdist([h2;h1],'euclidean');
    L(object,8) = pdist([h1;e1],'euclidean');
    LRAP(object,1) = max(L(object,:)) / min(L(object,:));
    
    % riformulazione LRAP: tolgo i 4 lati piu corti dal min per avere i
    % "veri" 4 lati
    % B = sort(L,2);
    % LRAP(object,1) = max(L(object,:)) / B(object,5);
    
    % Find the max length of the sides
    lmax = [1 L(object,1)];
    lmax2 = [1 L(object,1)];
    for l = 1:8
        test = L(object,l);
        if test > lmax(:,2)
            clear lmax2;
            lmax2 = lmax;
            clear lmax;
            lmax = [l test];
        elseif test > lmax2(:,2)
            clear lmax2;
            lmax2 = [l test];
        end
    end
    switch lmax(1)
        case 1
            xvm = (e1(1,1) + e2(1,1)) / 2;
            yvm = (e1(1,2) + e2(1,2)) / 2;
        case 2
            xvm = (e2(1,1) + f1(1,1)) / 2;
            yvm = (e2(1,2) + f1(1,2)) / 2;
        case 3
            xvm = (f1(1,1) + f2(1,1)) / 2;
            yvm = (f1(1,2) + f2(1,2)) / 2;
        case 4
            xvm = (f2(1,1) + g2(1,1)) / 2;
            yvm = (f2(1,2) + g2(1,2)) / 2;
        case 5
            xvm = (g2(1,1) + g1(1,1)) / 2;
            yvm = (g2(1,2) + g1(1,2)) / 2;
        case 6
            xvm = (g1(1,1) + h2(1,1)) / 2;
            yvm = (g1(1,2) + h2(1,2)) / 2;
        case 7
            xvm = (h2(1,1) + h1(1,1)) / 2;
            yvm = (h2(1,2) + h1(1,2)) / 2;
        case 8
            xvm = (h1(1,1) + e1(1,1)) / 2;
            yvm = (h1(1,2) + e1(1,2)) / 2;
    end
    vm1 = [xvm yvm];
    switch lmax2(1)
        case 1
            xvm2 = (e1(1,1) + e2(1,1)) / 2;
            yvm2 = (e1(1,2) + e2(1,2)) / 2;
        case 2
            xvm2 = (e2(1,1) + f1(1,1)) / 2;
            yvm2 = (e2(1,2) + f1(1,2)) / 2;
        case 3
            xvm2 = (f1(1,1) + f2(1,1)) / 2;
            yvm2 = (f1(1,2) + f2(1,2)) / 2;
        case 4
            xvm2 = (f2(1,1) + g2(1,1)) / 2;
            yvm2 = (f2(1,2) + g2(1,2)) / 2;
        case 5
            xvm2 = (g2(1,1) + g1(1,1)) / 2;
            yvm2 = (g2(1,2) + g1(1,2)) / 2;
        case 6
            xvm2 = (g1(1,1) + h2(1,1)) / 2;
            yvm2 = (g1(1,2) + h2(1,2)) / 2;
        case 7
            xvm2 = (h2(1,1) + h1(1,1)) / 2;
            yvm2 = (h2(1,2) + h1(1,2)) / 2;
        case 8
            xvm2 = (h1(1,1) + e1(1,1)) / 2;
            yvm2 = (h1(1,2) + e1(1,2)) / 2;
    end
    vm2 = [xvm2 yvm2];
    
    % Draw the line useful to the hands of the baxter
    % *** come alternativa potrei tracciare la linea tra il lato pi� lungo
    % e il centroid dell'oggetto
    result = insertShape(result, 'Line', [vm1 vm2], 'Color', 'white', 'LineWidth', 2);
    
    % Line Valerio:
    switch lmax(1) % cos� definiti trovo l'angolo orientato in senso orario
        case 1 % yl per ora INUTILE
            xl = e1(1,1) - e2(1,1);
            yl = e1(1,2) - e2(1,2);
        case 2
            xl = -(e2(1,1) - f1(1,1));
            yl = e2(1,2) - f1(1,2);
        case 3
            xl = f1(1,1) - f2(1,1);
            yl = f1(1,2) - f2(1,2);
        case 4
            xl = -(f2(1,1) - g2(1,1));
            yl = f2(1,2) - g2(1,2);
        case 5
            xl = g2(1,1) - g1(1,1);
            yl = g2(1,2) - g1(1,2);
        case 6
            xl = g1(1,1) - h2(1,1);
            yl = g1(1,2) - h2(1,2);
        case 7
            xl = h2(1,1) - h1(1,1);
            yl = h2(1,2) - h1(1,2);
        case 8
            xl = -(e1(1,1) - h1(1,1));
            yl = e1(1,2) - h1(1,2);
    end
    
    % orientazione lmax, alpha
    cosAlpha = xl/lmax(2);
    alpha = acosd(cosAlpha);
    
    
    switch lmax2(1) % trovo angolo orientato in senso orario
        case 1 % yl per ora INUTILE
            xl = e1(1,1) - e2(1,1);
            yl = e1(1,2) - e2(1,2);
        case 2
            xl = -(e2(1,1) - f1(1,1));
            yl = e2(1,2) - f1(1,2);
        case 3
            xl = f1(1,1) - f2(1,1);
            yl = f1(1,2) - f2(1,2);
        case 4
            xl = -(f2(1,1) - g2(1,1));
            yl = f2(1,2) - g2(1,2);
        case 5
            xl = g2(1,1) - g1(1,1);
            yl = g2(1,2) - g1(1,2);
        case 6
            xl = g1(1,1) - h2(1,1);
            yl = g1(1,2) - h2(1,2);
        case 7
            xl = h2(1,1) - h1(1,1);
            yl = h2(1,2) - h1(1,2);
        case 8
            xl = -(e1(1,1) - h1(1,1));
            yl = e1(1,2) - h1(1,2);
    end
    
    % orientazione lmax2, beta
    cosBeta = xl/lmax2(2);
    beta = acosd(cosBeta);
    
    % calcolo DELTA dei due lati lunghi
    deltaAlphaBeta = abs(abs(alpha)-abs(beta));
    maxAngle = max([alpha beta]);
    if or(or(and(lmax(1)==6,lmax2(1)==8),and(lmax(1)==8,lmax2(1)==6)),or(and(lmax(1)==4,lmax2(1)==2),and(lmax(1)==2,lmax2(1)==4)))
        if maxAngle==alpha
            omega = 180 - alpha;
            deltaAlphaBeta = abs(abs(omega) + abs(beta));
        end
        if maxAngle==beta
            omega = 180 - beta;
            deltaAlphaBeta = abs(abs(alpha) + abs(omega));
        end     
    end
    if or(or(or(and(lmax(1)==8,lmax2(1)==4),and(lmax(1)==4,lmax2(1)==8)),or(and(lmax(1)==6,lmax2(1)==4),and(lmax(1)==4,lmax2(1)==6))),or(and(lmax(1)==8,lmax2(1)==2),and(lmax(1)==2,lmax2(1)==8))) % se i lati max adiacenti sono il 4/6 o 2/8 rifaso di 90
            deltaAlphaBeta = abs(abs(alpha)-abs(beta));
    end
    
    % trovo orientazione ERRATA
%     if and(deltaAlphaBeta<45,deltaAlphaBeta>10)
%         if or(or(or(and(lmax(1)==8,lmax2(1)==6),and(lmax(1)==2,lmax2(1)==6)),or(and(lmax(1)==2,lmax2(1)==8),and(lmax(1)==4,lmax(1)==8))),or(and(lmax(1)==6,lmax2(1)==4),and(lmax(1)==4,lmax2(1)==2)))
%             
%             orientation = (alpha+beta)/2;
%             if maxAngle==alpha
%                 orientation = alpha + deltaAlphaBeta/2;
%             else
%                 orientation = beta + deltaAlphaBeta/2;
%             end
%         else
%             if maxAngle==alpha
%                 orientation = alpha - deltaAlphaBeta/2;
%             else
%             orientation = beta - deltaAlphaBeta/2;
%             end
%         end
%     else
%         orientation = alpha;
%     end
    

% SOLUZIONE CORRETTA 
% orientamento oggetto
    if deltaAlphaBeta<45
        orientation = (alpha+beta)/2;
    else
        orientation = alpha;
    end
    
    
    
%     if or((lmax(1)+2) == lmax2(1),(lmax(1)-2) == lmax2(1))
%         %if LRAP(object)<50 % da sosstituire con confronto alpha-beta <45�
%         
%         if or(or(and(lmax(1)==6,lmax2(1)==4),and(lmax(1)==4,lmax2(1)==6)),or(and(lmax(1)==8,lmax2(1)==2),and(lmax(1)==2,lmax2(1)==8))) % se i lati max adiacenti sono il 4/6 o 2/8 rifaso di 90
%             deltaAlphaBeta = abs(abs(alpha)-abs(beta));
%             if deltaAlphaBeta < 45
%                 alpha = alpha + beta + 90;
%             end
%         else
%             alpha = alpha + beta;
%         end
%     end
    

% STAMPA A VIDEO
    
    % print alpha in degrees
    printOrientation = 180-orientation; % inverto verso angolo (come trigonometria, senso antiorario)
    result = insertText(result, [bb(1,1)-15 bb(1,2)-30], printOrientation, 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'green');
    
    % creo punti per "mirino"
    
    x1 = bc(1,1)-lmax(2)/2*cosd(orientation);
    y1 = bc(1,2)-lmax(2)/2*sind(orientation);
    linepoint1 = [x1 y1];
    x2 = bc(1,1)+lmax(2)/2*cosd(orientation);
    y2 = bc(1,2)+lmax(2)/2*sind(orientation);
    linepoint2 = [x2 y2];
    x3 = bc(1,1)-lmax(2)/4*cosd(orientation+90);
    y3 = bc(1,2)-lmax(2)/4*sind(orientation+90);
    linepoint3 = [x3 y3];
    x4 = bc(1,1)+lmax(2)/4*cosd(orientation+90);
    y4 = bc(1,2)+lmax(2)/4*sind(orientation+90);
    linepoint4 = [x4 y4];
    
    % print orientation cross
    result = insertShape(result, 'Line', [linepoint1 bc linepoint2], 'Color', 'red', 'LineWidth', 2);
    result = insertShape(result, 'Line', [linepoint3 bc linepoint4], 'Color', 'red', 'LineWidth', 2);
    
    % Fine Valerio
end

% Match the objects
% Case 1: three objects
if numObjects == 3
    batot2 = batot;
    LRAP2 = LRAP;
    [obj3,index3] = min(batot2);
    batot2(index3) = 9999999;
    LRAP2(index3) = 9999999;
    result = insertText(result, [bbtot(index3,1) bbtot(index3,2)+bbtot(index3,4)+10], 'MOUSE', 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'green');
    
    [obj2,index2] = min(batot2);
    if LRAP(index2) == min(LRAP2)
        LRAP2(index2) = 9999999;
        batot2(index2) = 9999999;
        result = insertText(result, [bbtot(index2,1) bbtot(index2,2)+bbtot(index2,4)+10], 'PHONE', 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'green');
    end
    
    [obj1,index1] = min(batot2);
%     batot2(index1) = 9999999;
%     LRAP2(index1) = 9999999;
    result = insertText(result, [bbtot(index1,1) bbtot(index1,2)+bbtot(index1,4)+10], 'KEY', 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'green');    
end
    
figure, imshow(result), title(['Objects found: ',num2str(numObjects)]);

