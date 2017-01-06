function LBPs = LBP(Im, P, R)

%
% P: # sampling points in neighbor of each pixel (P = 8, usually)
% R: radius of each sampling (R = 1, 2, 3, ...)
%


% transform into grayscale if input Im is colorful
if size(Im, 3) == 3
    Im = rgb2gray(Im);
end;

% size of each LBP sample
L = 2*R + 1; 
% center of LBP sample
C = round(L/2);

Im = uint8(Im);
nrows = size(Im, 1) - L + 1;
ncols = size(Im, 2) - L + 1;
LBPs = zeros(nrows, ncols);
for i = 1:nrows
    for j = 1:ncols
        A = Im(i:i+L-1, j:j+L-1);
        A = A+1-A(C,C);
        A(A>0) = 1;
        % transform from binary code into decimal
        LBPs(i,j) = A(C,L) + A(L,L)*2 + A(L,C)*4 + A(L,1)*8 + A(C,1)*16 + A(1,1)*32 + A(1,C)*64 + A(1,L)*128;
    end;
end;