function [lny,sigma,tau,phi]=SBSA2016(To,M,Rjb,VS30,SOF,region)

st          = dbstack;
isadmisible = isIMadmisible(To,st(1).name,[0 10],[nan nan],[nan nan],[nan nan]);
if isadmisible==0
    lny   = nan(size(M));
    sigma = nan(size(M));
    tau   = nan(size(M));
    phi   = nan(size(M));
    return
end

if To>=0
    To  = max(To,0.001);  % PGA is associated to To=0.01;
end

period  = [-1,0.001,0.01,0.02,0.022,0.025,0.029,0.03,0.032,0.035,0.036,0.04,0.042,0.044,0.045,0.046,0.048,0.05,0.055,0.06,0.065,...
    0.067,0.07,0.075,0.08,0.085,0.09,0.095,0.1,0.11,0.12,0.13,0.133,0.14,0.15,0.16,0.17,0.18,0.19,0.2,0.22,0.24,0.25,0.26,0.28,0.29,...
    0.3,0.32,0.34,0.35,0.36,0.38,0.4,0.42,0.44,0.45,0.46,0.48,0.5,0.55,0.6,0.65,0.667,0.7,0.75,0.8,0.85,0.9,0.95,1,1.1,1.2,1.3,1.4,...
    1.5,1.6,1.7,1.8,1.9,2,2.2,2.4,2.5,2.6,2.8,3,3.2,3.4,3.5,3.6,3.8,4,4.2,4.4,4.6,4.8,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10];

T_lo    = max(period(period<=To));
T_hi    = min(period(period>=To));
index   = find(abs((period - T_lo)) < 1e-6);    % Identify the period

% computes PGARock
PGAr = exp(gmpe(index,M,Rjb,VS30,SOF,region,[]));

if T_lo==T_hi
    [lny,tau,phi] = gmpe(index,M,Rjb,VS30,SOF,region,PGAr);
else
    [lny_lo,tau_lo,phi_lo] = gmpe(index,  M,Rjb,VS30,SOF,region,PGAr);
    [lny_hi,tau_hi,phi_hi] = gmpe(index+1,M,Rjb,VS30,SOF,region,PGAr);
    x          = log([T_lo;T_hi]);
    Y_sa       = [lny_lo,lny_hi]';
    Y_sigma2   = [tau_lo,tau_hi]';
    Y_sigma1   = [phi_lo,phi_hi]';
    lny        = interp1(x,Y_sa,log(To))';
    phi        = interp1(x,Y_sigma2,log(To))';
    tau        = interp1(x,Y_sigma1,log(To))';
end

sigma = sqrt(tau.^2+phi.^2);

function[lny,tau,phi]=gmpe(index,M,Rjb,VS30,SOF,region,PGAr)

U=0;SS=0;NS=0;RS=0;
switch SOF
    case 'strike-slip'     , SS = 1;
    case 'normal'          , NS = 1;
    case 'normal-oblique'  , NS = 1;
    case 'reverse'         , RS = 1;
    case 'reverse-oblique' , RS = 1;
    case 'unspecified'     , U  = 1;
end

C     = SBSA2016coefficients(index);
e0    =C(1);
e1    =C(2);
e2    =C(3);
e3    =C(4);
e4    =C(5);
e5    =C(6);
e6    =C(7);
Mh    =C(8);
c1    =C(9);
c2    =C(10);
c3    =C(11);
Mref  =C(12);
Rref  =C(13);
h     =C(14);

switch region
    case 'global'    , Dc3   =C(15);
    case 'california', Dc3   =C(15);
    case 'japan'     , Dc3   =C(17);
    case 'china'     , Dc3   =C(16);
    case 'italy'     , Dc3   =C(17);
    case 'turkey'    , Dc3   =C(16);
    otherwise %Taiwan, New zeeland
        Dc3   =C(15);
end

c     =C(18);
Vc    =C(19);
Vref  =C(20);
f1    =C(21);
f3    =C(22);
f4    =C(23);
f5    =C(24);
phi1  =C(25);
phi2  =C(26);
tau1  =C(27);
tau2  =C(28);

% Event term
FE  = e0*U+e1*SS+e2*NS+e3*RS+e4*(M-Mh)+e5*(M-Mh).^2;
FE2 = e0*U+e1*SS+e2*NS+e3*RS+e6*(M-Mh);
FE(M>Mh) = FE2(M>Mh);

% Path term
R  = sqrt(Rjb.^2+h^2);
FP = (c1+c2*(M-Mref)).*log(R/Rref)+(c3+Dc3)*(R-Rref);

% Site term
if ~isempty(PGAr)
    lnFlin = c*log(min(Vc,VS30)/Vref);
    f2     = f4*(exp(f5*(min(VS30,760)-360))-exp(f5*(760-360)));
    lnFnl  = f1+f2*log((PGAr+f3)/f3);
    FS     = lnFlin+lnFnl;
else
    FS=0;
end

% Median model
lny = FE+FP+FS;

% Aleatory Variability
tau = tau1+(tau2-tau1)*(M-4.5);
tau(M<=4.5)=tau1;
tau(M>=5.5)=tau2;

phi = phi1+(phi2-phi1)*(M-4.5);
phi(M<=4.5)=phi1;
phi(M>=5.5)=phi2;

function[C]=SBSA2016coefficients(index)

switch index
    case   1, C=[4.27 4.29 4.18 4.26 0.993 -0.111 0.247 6.2 -1.25 0.172 -0.0034 4.5 1 6.9 0 0.00336 0 -0.518 1300 760 0 0.1 -0.03 -0.00844 0.582 0.597 0.386 0.349];
    case   2, C=[0.184 0.234 0.0156 0.154 1.25 0 0.0226 5.5 -1.18 0.158 -0.00922 4.5 1 5.1 0 0.00475 0 -0.329 1500 760 0 0.1 -0.05 -0.00701 0.712 0.534 0.476 0.376];
    case   3, C=[0.205 0.255 0.0351 0.174 1.24 0 0.0222 5.5 -1.18 0.157 -0.00922 4.5 1 5.1 0 0.00498 0 -0.329 1500 760 0 0.1 -0.05 -0.00701 0.715 0.533 0.481 0.381];
    case   4, C=[0.394 0.447 0.23 0.357 1.24 0 0.0104 5.5 -1.21 0.16 -0.00904 4.5 1 5.06 0 0.00521 0 -0.318 1500.1 760 0 0.1 -0.0501 -0.00728 0.718 0.538 0.49 0.388];
    case   5, C=[0.445 0.499 0.281 0.406 1.24 0 0.00844 5.5 -1.22 0.16 -0.00904 4.5 1 5.03 0 0.00525 0 -0.311 1501 760 0 0.1 -0.0501 -0.00731 0.725 0.543 0.502 0.397];
    case   6, C=[0.531 0.588 0.367 0.488 1.23 0 0.00667 5.5 -1.23 0.161 -0.00907 4.5 1 4.99 0 0.00532 0 -0.301 1501 760 0 0.1 -0.0501 -0.00734 0.731 0.547 0.512 0.405];
    case   7, C=[0.646 0.706 0.486 0.595 1.22 0 0.00736 5.5 -1.24 0.161 -0.00921 4.5 1 4.99 0 0.0054 0 -0.298 1502 760 0 0.1 -0.0498 -0.00731 0.737 0.552 0.522 0.412];
    case   8, C=[0.671 0.732 0.512 0.618 1.22 0 0.00862 5.5 -1.25 0.161 -0.00926 4.5 1 4.99 0 0.00542 0 -0.297 1502 760 0 0.1 -0.0497 -0.00729 0.744 0.557 0.532 0.419];
    case   9, C=[0.716 0.777 0.56 0.659 1.22 0 0.0127 5.5 -1.25 0.16 -0.00939 4.5 1 5.01 0 0.00546 0 -0.298 1502 760 0 0.1 -0.0497 -0.00725 0.75 0.563 0.541 0.427];
    case  10, C=[0.773 0.836 0.623 0.71 1.21 0 0.0209 5.5 -1.24 0.158 -0.00963 4.5 1 5.03 0 0.00552 0 -0.3 1503 760 0 0.1 -0.0504 -0.00715 0.756 0.567 0.55 0.433];
    case  11, C=[0.789 0.853 0.641 0.725 1.21 0 0.024 5.5 -1.24 0.158 -0.00972 4.5 1 5.03 0 0.00554 0 -0.304 1503 760 0 0.1 -0.0508 -0.00711 0.761 0.571 0.558 0.439];
    case  12, C=[0.837 0.902 0.695 0.767 1.22 0 0.0369 5.5 -1.23 0.154 -0.0101 4.5 1 5.03 0 0.0056 0 -0.319 1502.9 760 0 0.1 -0.0535 -0.00694 0.767 0.576 0.565 0.445];
    case  13, C=[0.853 0.919 0.711 0.782 1.22 0 0.0447 5.5 -1.23 0.152 -0.0103 4.5 1 5.01 0 0.00563 0 -0.324 1502 760 0 0.1 -0.0553 -0.00684 0.771 0.58 0.571 0.45];
    case  14, C=[0.865 0.932 0.722 0.794 1.22 0 0.0527 5.5 -1.22 0.15 -0.0106 4.5 1 4.99 0 0.00566 0 -0.331 1502 760 0 0.1 -0.0573 -0.00675 0.776 0.583 0.576 0.456];
    case  15, C=[0.869 0.936 0.726 0.798 1.23 0 0.0571 5.5 -1.21 0.149 -0.0107 4.5 1 4.98 0 0.00567 0 -0.339 1502 760 0 0.1 -0.0584 -0.0067 0.78 0.587 0.58 0.462];
    case  16, C=[0.873 0.941 0.728 0.801 1.23 0 0.0616 5.5 -1.21 0.148 -0.0108 4.5 1 4.97 0 0.00568 0 -0.349 1502 760 0 0.1 -0.0594 -0.00666 0.784 0.59 0.582 0.468];
    case  17, C=[0.881 0.949 0.733 0.808 1.23 0 0.0713 5.5 -1.2 0.145 -0.011 4.5 1 4.96 0 0.0057 0 -0.358 1501.9 760 0 0.1 -0.0616 -0.00656 0.787 0.593 0.584 0.474];
    case  18, C=[0.886 0.955 0.735 0.814 1.24 0 0.0811 5.5 -1.19 0.142 -0.0112 4.5 1 4.94 0 0.00571 0 -0.365 1501.1 760 0 0.1 -0.0636 -0.00648 0.789 0.595 0.583 0.479];
    case  19, C=[0.892 0.962 0.732 0.821 1.26 0 0.104 5.5 -1.17 0.135 -0.0116 4.5 1 4.9 0 0.00572 0 -0.372 1500 760 0 0.1 -0.0682 -0.00628 0.79 0.596 0.581 0.483];
    case  20, C=[0.886 0.957 0.71 0.818 1.28 0 0.123 5.5 -1.15 0.129 -0.0119 4.5 1 4.9 0 0.0057 0 -0.38 1499.1 760 0 0.1 -0.0715 -0.00611 0.79 0.597 0.578 0.486];
    case  21, C=[0.875 0.947 0.684 0.813 1.3 0 0.142 5.5 -1.13 0.122 -0.0121 4.5 1 4.9 0 0.00566 0 -0.386 1497.4 760 0 0.1 -0.0734 -0.00597 0.79 0.599 0.574 0.489];
    case  22, C=[0.872 0.943 0.675 0.812 1.31 0 0.149 5.5 -1.12 0.12 -0.0121 4.5 1 4.9 0 0.00564 0 -0.392 1496.7 760 0 0.1 -0.0739 -0.00592 0.789 0.6 0.569 0.49];
    case  23, C=[0.867 0.938 0.662 0.812 1.32 0 0.158 5.5 -1.11 0.117 -0.0122 4.5 1 4.9 0 0.0056 0 -0.397 1495.5 760 0 0.1 -0.0745 -0.00586 0.789 0.602 0.563 0.491];
    case  24, C=[0.86 0.93 0.642 0.811 1.35 0 0.17 5.5 -1.09 0.112 -0.0122 4.5 1 4.9 0 0.00553 0 -0.4 1493.2 760 0 0.1 -0.0749 -0.00578 0.787 0.603 0.555 0.49];
    case  25, C=[0.853 0.922 0.627 0.81 1.37 0 0.176 5.5 -1.08 0.108 -0.0122 4.5 1 4.88 0 0.00546 0 -0.403 1490.7 760 0 0.1 -0.0751 -0.00572 0.786 0.604 0.547 0.487];
    case  26, C=[0.849 0.917 0.616 0.811 1.39 0 0.174 5.51 -1.06 0.105 -0.0121 4.5 1 4.85 0 0.00538 0 -0.404 1488.1 760 0 0.1 -0.075 -0.00568 0.784 0.605 0.538 0.483];
    case  27, C=[0.847 0.915 0.607 0.813 1.4 0 0.167 5.52 -1.05 0.104 -0.012 4.5 1 4.83 0 0.0053 0 -0.404 1485.6 760 0 0.1 -0.0747 -0.00565 0.781 0.606 0.528 0.476];
    case  28, C=[0.847 0.914 0.603 0.817 1.41 0 0.157 5.53 -1.05 0.103 -0.0118 4.5 1 4.81 0 0.00523 -0.0001 -0.404 1482.3 760 0 0.1 -0.0742 -0.00564 0.779 0.607 0.518 0.469];
    case  29, C=[0.849 0.914 0.601 0.821 1.43 0 0.144 5.54 -1.04 0.102 -0.0117 4.5 1 4.8 0 0.00518 -0.00025 -0.404 1480 760 0 0.1 -0.0736 -0.00564 0.777 0.607 0.508 0.461];
    case  30, C=[0.85 0.913 0.6 0.828 1.44 -0.0000625 0.11 5.57 -1.03 0.102 -0.0114 4.5 1 4.79 0 0.00512 -0.00045 -0.403 1473.7 760 0 0.1 -0.0717 -0.00565 0.775 0.607 0.497 0.453];
    case  31, C=[0.84 0.901 0.593 0.822 1.44 -0.00305 0.0713 5.62 -1.02 0.104 -0.0111 4.5 1 4.76 0 0.00512 -0.00065 -0.402 1466.2 760 0 0.1 -0.0692 -0.00569 0.772 0.606 0.486 0.445];
    case  32, C=[0.823 0.88 0.583 0.809 1.42 -0.0104 0.0314 5.66 -1.01 0.107 -0.0107 4.5 1 4.77 0 0.00515 -0.00085 -0.401 1458.5 760 0 0.1 -0.0664 -0.00574 0.769 0.605 0.474 0.437];
    case  33, C=[0.816 0.872 0.578 0.803 1.41 -0.013 0.0203 5.67 -1.01 0.108 -0.0106 4.5 1 4.77 0 0.00516 -0.0009 -0.4 1456 760 0 0.1 -0.0655 -0.00576 0.766 0.603 0.463 0.429];
    case  34, C=[0.795 0.848 0.563 0.785 1.39 -0.0202 -0.00228 5.7 -1 0.11 -0.0104 4.5 1 4.78 0 0.0052 -0.0011 -0.4 1450.2 760 0 0.1 -0.0635 -0.0058 0.762 0.601 0.452 0.422];
    case  35, C=[0.755 0.804 0.534 0.751 1.35 -0.0328 -0.028 5.74 -0.996 0.113 -0.0101 4.5 1 4.78 0 0.00524 -0.00132 -0.4 1441.2 760 0 0.1 -0.0607 -0.00586 0.757 0.598 0.441 0.416];
    case  36, C=[0.711 0.755 0.499 0.711 1.31 -0.0473 -0.0471 5.78 -0.99 0.115 -0.00981 4.5 1 4.78 0 0.00527 -0.00152 -0.4 1431.6 760 0 0.1 -0.0581 -0.00592 0.752 0.596 0.43 0.41];
    case  37, C=[0.662 0.702 0.463 0.666 1.26 -0.0636 -0.061 5.82 -0.986 0.118 -0.00951 4.5 1 4.76 0 0.00527 -0.00168 -0.401 1422.3 760 0 0.1 -0.0557 -0.00598 0.746 0.594 0.42 0.405];
    case  38, C=[0.613 0.648 0.426 0.619 1.21 -0.081 -0.0707 5.85 -0.982 0.12 -0.00922 4.5 1 4.76 0 0.00526 -0.00183 -0.402 1413.7 760 0 0.1 -0.0534 -0.00604 0.74 0.592 0.41 0.401];
    case  39, C=[0.563 0.594 0.389 0.572 1.16 -0.0982 -0.0774 5.89 -0.979 0.122 -0.00896 4.5 1 4.77 0 0.00523 -0.00195 -0.403 1405.4 760 0 0.1 -0.0512 -0.0061 0.733 0.59 0.401 0.398];
    case  40, C=[0.517 0.544 0.354 0.527 1.11 -0.114 -0.0819 5.92 -0.977 0.124 -0.00871 4.5 1 4.79 0 0.00518 -0.00205 -0.403 1396.5 760 0 0.1 -0.0492 -0.00616 0.727 0.589 0.391 0.394];
    case  41, C=[0.431 0.453 0.284 0.448 1.03 -0.142 -0.0864 5.97 -0.974 0.127 -0.00825 4.5 1 4.78 0 0.00505 -0.0022 -0.402 1378.9 760 0 0.1 -0.0461 -0.00627 0.721 0.588 0.383 0.39];
    case  42, C=[0.354 0.37 0.216 0.377 0.955 -0.167 -0.0865 6.03 -0.97 0.129 -0.00785 4.5 1 4.8 0 0.00488 -0.0023 -0.401 1360.9 760 0 0.1 -0.0435 -0.00639 0.715 0.588 0.375 0.387];
    case  43, C=[0.319 0.334 0.184 0.345 0.925 -0.178 -0.0858 6.05 -0.969 0.129 -0.00766 4.5 1 4.81 0 0.00478 -0.00233 -0.4 1352.9 760 0 0.1 -0.0424 -0.00644 0.709 0.588 0.368 0.383];
    case  44, C=[0.287 0.299 0.154 0.316 0.9 -0.187 -0.0857 6.07 -0.968 0.13 -0.00748 4.5 1 4.83 0 0.00468 -0.00235 -0.398 1344.5 760 0 0.1 -0.0416 -0.0065 0.702 0.588 0.361 0.379];
    case  45, C=[0.227 0.236 0.0952 0.262 0.861 -0.203 -0.0861 6.11 -0.967 0.131 -0.00715 4.5 1 4.88 0 0.00446 -0.00237 -0.396 1329.1 760 0 0.1 -0.0402 -0.00661 0.695 0.589 0.354 0.375];
    case  46, C=[0.2 0.208 0.0673 0.237 0.847 -0.209 -0.0855 6.12 -0.967 0.131 -0.00699 4.5 1 4.91 0 0.00436 -0.00237 -0.393 1320.8 760 0 0.1 -0.0397 -0.00666 0.689 0.589 0.348 0.371];
    case  47, C=[0.173 0.181 0.0397 0.212 0.836 -0.215 -0.0841 6.14 -0.967 0.132 -0.00684 4.5 1 4.94 0 0.00425 -0.00237 -0.39 1313.4 760 0 0.1 -0.039 -0.0067 0.682 0.59 0.343 0.367];
    case  48, C=[0.124 0.131 -0.0118 0.167 0.821 -0.224 -0.0836 6.16 -0.966 0.132 -0.00656 4.5 1 5 0 0.00405 -0.00237 -0.388 1298.7 760 0 0.1 -0.038 -0.0068 0.676 0.59 0.339 0.364];
    case  49, C=[0.0759 0.0819 -0.0625 0.12 0.811 -0.232 -0.0831 6.18 -0.967 0.133 -0.00629 4.5 1 5.05 0 0.00386 -0.00237 -0.385 1286.3 760 0 0.1 -0.0371 -0.00689 0.67 0.59 0.336 0.362];
    case  50, C=[0.0518 0.0579 -0.0877 0.096 0.808 -0.236 -0.0827 6.18 -0.967 0.133 -0.00616 4.5 1 5.07 0 0.00376 -0.00237 -0.382 1280 760 0 0.1 -0.0367 -0.00693 0.663 0.589 0.333 0.359];
    case  51, C=[0.0285 0.0347 -0.112 0.0729 0.806 -0.239 -0.0821 6.19 -0.968 0.134 -0.00603 4.5 1 5.1 0 0.00368 -0.00236 -0.38 1273.8 760 0 0.1 -0.0362 -0.00697 0.657 0.589 0.331 0.358];
    case  52, C=[-0.0161 -0.00945 -0.159 0.028 0.805 -0.244 -0.0806 6.19 -0.97 0.134 -0.00579 4.5 1 5.15 0 0.00351 -0.00236 -0.38 1262.1 760 0 0.1 -0.0354 -0.00705 0.65 0.588 0.33 0.356];
    case  53, C=[-0.0577 -0.0504 -0.202 -0.0139 0.809 -0.248 -0.0781 6.2 -0.973 0.135 -0.00556 4.5 1 5.19 0 0.00335 -0.00235 -0.38 1252.1 760 0 0.1 -0.0348 -0.00712 0.644 0.588 0.329 0.355];
    case  54, C=[-0.0972 -0.0893 -0.242 -0.0544 0.819 -0.25 -0.0751 6.2 -0.975 0.136 -0.00534 4.5 1 5.23 0 0.00321 -0.00234 -0.381 1242.5 760 0 0.1 -0.0343 -0.00719 0.638 0.588 0.329 0.354];
    case  55, C=[-0.135 -0.127 -0.28 -0.0939 0.83 -0.252 -0.071 6.2 -0.978 0.136 -0.00514 4.5 1 5.27 0 0.00308 -0.00232 -0.384 1233.6 760 0 0.1 -0.0339 -0.00726 0.633 0.588 0.331 0.351];
    case  56, C=[-0.154 -0.146 -0.297 -0.114 0.835 -0.253 -0.0689 6.2 -0.979 0.137 -0.00504 4.5 1 5.28 0 0.00301 -0.00232 -0.388 1229.7 760 0 0.1 -0.0337 -0.00729 0.627 0.588 0.333 0.35];
    case  57, C=[-0.173 -0.164 -0.315 -0.133 0.841 -0.254 -0.067 6.2 -0.981 0.137 -0.00495 4.5 1 5.3 0 0.00295 -0.00231 -0.393 1225.9 760 0 0.1 -0.0335 -0.00732 0.622 0.588 0.337 0.35];
    case  58, C=[-0.209 -0.2 -0.347 -0.17 0.852 -0.255 -0.0643 6.2 -0.983 0.138 -0.00477 4.5 1 5.33 0 0.00284 -0.00229 -0.4 1218.6 760 0 0.1 -0.033 -0.00739 0.617 0.589 0.341 0.35];
    case  59, C=[-0.24 -0.232 -0.376 -0.203 0.865 -0.256 -0.0621 6.2 -0.987 0.138 -0.0046 4.5 1 5.35 0 0.00274 -0.00228 -0.406 1212.4 760 0 0.1 -0.0325 -0.00745 0.611 0.59 0.347 0.35];
    case  60, C=[-0.314 -0.306 -0.442 -0.278 0.903 -0.256 -0.0502 6.2 -0.995 0.139 -0.00421 4.5 1 5.4 0 0.00252 -0.00223 -0.413 1195.9 760 0 0.1 -0.031 -0.0076 0.606 0.591 0.354 0.349];
    case  61, C=[-0.373 -0.365 -0.497 -0.338 0.948 -0.253 -0.0364 6.2 -1.01 0.139 -0.00387 4.5 1 5.49 0 0.00235 -0.00217 -0.421 1181.6 760 0 0.1 -0.0296 -0.00774 0.601 0.592 0.361 0.348];
    case  62, C=[-0.42 -0.413 -0.539 -0.386 0.996 -0.248 -0.0252 6.2 -1.02 0.139 -0.00358 4.5 1 5.62 0 0.00223 -0.00211 -0.431 1170.1 760 0 0.1 -0.0285 -0.00787 0.596 0.593 0.369 0.346];
    case  63, C=[-0.434 -0.427 -0.551 -0.4 1.01 -0.246 -0.0208 6.2 -1.02 0.139 -0.00349 4.5 1 5.67 0 0.00219 -0.00208 -0.441 1166.6 760 0 0.1 -0.028 -0.00791 0.591 0.595 0.377 0.346];
    case  64, C=[-0.459 -0.452 -0.575 -0.426 1.04 -0.242 -0.0115 6.2 -1.03 0.138 -0.00333 4.5 1 5.78 0 0.00214 -0.00204 -0.452 1159.5 760 0 0.1 -0.0272 -0.00799 0.586 0.596 0.386 0.346];
    case  65, C=[-0.491 -0.485 -0.605 -0.458 1.09 -0.236 0.00275 6.2 -1.04 0.138 -0.00311 4.5 1 5.96 0 0.0021 -0.00196 -0.464 1149.7 760 0 0.1 -0.026 -0.00809 0.581 0.598 0.395 0.348];
    case  66, C=[-0.517 -0.512 -0.631 -0.482 1.14 -0.23 0.0199 6.2 -1.05 0.137 -0.00292 4.5 1 6.16 0 0.00208 -0.00189 -0.475 1140.1 760 0 0.1 -0.0249 -0.00818 0.577 0.6 0.404 0.352];
    case  67, C=[-0.541 -0.536 -0.655 -0.505 1.18 -0.224 0.0394 6.2 -1.06 0.135 -0.00276 4.5 1 6.37 0 0.00208 -0.00181 -0.486 1132.2 760 0 0.1 -0.0239 -0.00826 0.573 0.603 0.413 0.355];
    case  68, C=[-0.561 -0.557 -0.675 -0.525 1.23 -0.218 0.0602 6.2 -1.07 0.134 -0.00262 4.5 1 6.56 0 0.0021 -0.00173 -0.497 1124.7 760 0 0.1 -0.0231 -0.00832 0.57 0.606 0.422 0.358];
    case  69, C=[-0.579 -0.575 -0.693 -0.542 1.27 -0.211 0.0828 6.2 -1.08 0.132 -0.00249 4.5 1 6.75 0 0.00213 -0.00165 -0.508 1118.6 760 0 0.1 -0.0222 -0.00836 0.566 0.609 0.431 0.361];
    case  70, C=[-0.595 -0.592 -0.708 -0.557 1.32 -0.205 0.107 6.2 -1.09 0.129 -0.00236 4.5 1 6.94 0 0.00217 -0.00158 -0.518 1113 760 0 0.1 -0.0215 -0.00838 0.563 0.613 0.44 0.365];
    case  71, C=[-0.623 -0.62 -0.738 -0.584 1.41 -0.192 0.155 6.2 -1.1 0.124 -0.00219 4.5 1 7.33 0 0.00224 -0.00143 -0.528 1103.7 760 0 0.1 -0.0202 -0.00836 0.56 0.617 0.449 0.37];
    case  72, C=[-0.649 -0.646 -0.764 -0.609 1.5 -0.18 0.199 6.2 -1.12 0.117 -0.00203 4.5 1 7.7 0 0.00231 -0.0013 -0.538 1095.2 760 0 0.1 -0.0191 -0.00826 0.557 0.622 0.457 0.375];
    case  73, C=[-0.679 -0.676 -0.792 -0.639 1.57 -0.171 0.253 6.2 -1.13 0.11 -0.00188 4.5 1 8.07 0 0.00238 -0.00118 -0.547 1086.5 760 0 0.1 -0.0178 -0.00806 0.554 0.626 0.466 0.379];
    case  74, C=[-0.713 -0.71 -0.822 -0.675 1.64 -0.163 0.305 6.2 -1.14 0.104 -0.00175 4.5 1 8.4 0 0.00245 -0.00107 -0.557 1077.2 760 0 0.1 -0.0164 -0.00776 0.551 0.63 0.475 0.383];
    case  75, C=[-0.75 -0.747 -0.853 -0.715 1.7 -0.158 0.354 6.2 -1.14 0.0977 -0.00162 4.5 1 8.72 0 0.00251 -0.000974 -0.567 1067.4 760 0 0.1 -0.0152 -0.00738 0.548 0.634 0.483 0.387];
    case  76, C=[-0.789 -0.786 -0.884 -0.756 1.75 -0.151 0.398 6.2 -1.15 0.0924 -0.00152 4.5 1 8.99 0 0.00256 -0.000886 -0.578 1056.4 760 0 0.1 -0.0141 -0.00692 0.545 0.637 0.49 0.391];
    case  77, C=[-0.828 -0.827 -0.91 -0.799 1.8 -0.145 0.442 6.2 -1.16 0.0876 -0.00142 4.5 1 9.17 0 0.00262 -0.000807 -0.59 1045.3 760 0 0.1 -0.0129 -0.00642 0.542 0.639 0.496 0.395];
    case  78, C=[-0.869 -0.869 -0.934 -0.844 1.85 -0.139 0.485 6.2 -1.17 0.0833 -0.00134 4.5 1 9.31 0 0.00267 -0.000737 -0.602 1034.9 760 0 0.1 -0.0118 -0.0059 0.538 0.641 0.502 0.398];
    case  79, C=[-0.91 -0.91 -0.961 -0.89 1.89 -0.132 0.526 6.2 -1.17 0.0791 -0.00127 4.5 1 9.46 0 0.00271 -0.000675 -0.613 1024.6 760 0 0.1 -0.0109 -0.00539 0.535 0.642 0.506 0.401];
    case  80, C=[-0.953 -0.954 -0.989 -0.936 1.93 -0.127 0.566 6.2 -1.18 0.075 -0.00119 4.5 1 9.56 0 0.00275 -0.000621 -0.625 1014.4 760 0 0.1 -0.0102 -0.00489 0.531 0.642 0.51 0.402];
    case  81, C=[-1.04 -1.05 -1.04 -1.03 2.02 -0.112 0.636 6.2 -1.18 0.0682 -0.00109 4.5 1 9.6 0 0.00282 -0.000534 -0.638 992.76 760 0 0.1 -0.00896 -0.00399 0.528 0.641 0.514 0.402];
    case  82, C=[-1.14 -1.15 -1.09 -1.13 2.1 -0.0957 0.701 6.2 -1.18 0.0627 -0.000991 4.5 1 9.53 0 0.00287 -0.00047 -0.645 973.49 760 0 0.1 -0.0079 -0.00326 0.525 0.64 0.517 0.402];
    case  83, C=[-1.19 -1.21 -1.13 -1.17 2.13 -0.0882 0.733 6.2 -1.18 0.0605 -0.000948 4.5 1 9.49 0 0.00288 -0.000446 -0.648 964.54 760 0 0.1 -0.00742 -0.00296 0.522 0.639 0.519 0.401];
    case  84, C=[-1.24 -1.26 -1.16 -1.23 2.16 -0.0818 0.764 6.2 -1.18 0.0589 -0.0009 4.5 1 9.46 0 0.00289 -0.000426 -0.651 956.16 760 0 0.1 -0.00697 -0.00271 0.519 0.638 0.52 0.4];
    case  85, C=[-1.35 -1.38 -1.24 -1.34 2.22 -0.0688 0.824 6.2 -1.18 0.0557 -0.00081 4.5 1 9.45 0 0.00289 -0.000397 -0.652 939.01 760 0 0.1 -0.00615 -0.00231 0.515 0.637 0.521 0.4];
    case  86, C=[-1.46 -1.5 -1.33 -1.45 2.27 -0.0568 0.884 6.2 -1.17 0.0526 -0.000704 4.5 1 9.49 0 0.00287 -0.00035 -0.645 921.23 760 0 0.1 -0.00543 -0.00203 0.511 0.637 0.522 0.399];
    case  87, C=[-1.58 -1.62 -1.43 -1.57 2.3 -0.0487 0.938 6.2 -1.16 0.0507 -0.000639 4.5 1 9.51 0 0.00282 -0.0002 -0.641 904.14 760 0 0.1 -0.00479 -0.00184 0.506 0.637 0.523 0.397];
    case  88, C=[-1.69 -1.73 -1.51 -1.68 2.33 -0.0399 0.982 6.2 -1.16 0.0506 -0.000577 4.5 1 9.48 0 0.00275 -0.00012 -0.63 888.7 760 0 0.1 -0.00423 -0.00171 0.502 0.637 0.524 0.394];
    case  89, C=[-1.74 -1.78 -1.55 -1.73 2.35 -0.0359 1 6.2 -1.15 0.0507 -0.000547 4.5 1 9.47 0 0.00271 -0.0001 -0.628 881.42 760 0 0.1 -0.00397 -0.00166 0.498 0.637 0.525 0.392];
    case  90, C=[-1.79 -1.84 -1.6 -1.78 2.36 -0.0324 1.02 6.2 -1.15 0.0506 -0.000519 4.5 1 9.48 0 0.00266 -0.000095 -0.623 874.26 760 0 0.1 -0.00373 -0.00163 0.494 0.637 0.526 0.39];
    case  91, C=[-1.89 -1.94 -1.7 -1.89 2.39 -0.026 1.06 6.2 -1.14 0.0501 -0.000464 4.5 1 9.49 0 0.00256 0 -0.611 860.43 760 0 0.1 -0.0033 -0.00157 0.489 0.637 0.527 0.387];
    case  92, C=[-2 -2.04 -1.81 -2 2.41 -0.0207 1.09 6.2 -1.13 0.0488 -0.000412 4.5 1 9.51 0 0.00244 0 -0.6 847.56 760 0 0.1 -0.00293 -0.00153 0.484 0.637 0.527 0.385];
    case  93, C=[-2.1 -2.14 -1.91 -2.11 2.44 -0.0155 1.12 6.2 -1.12 0.0476 -0.000362 4.5 1 9.52 0 0.00232 0 -0.59 835.89 760 0 0.1 -0.00257 -0.0015 0.478 0.638 0.529 0.382];
    case  94, C=[-2.2 -2.24 -2.01 -2.21 2.46 -0.0111 1.14 6.2 -1.11 0.0468 -0.000315 4.5 1 9.54 0 0.00219 0 -0.578 825.46 760 0 0.1 -0.00224 -0.00149 0.472 0.639 0.532 0.38];
    case  95, C=[-2.31 -2.34 -2.11 -2.31 2.48 -0.00841 1.16 6.2 -1.1 0.0469 -0.00027 4.5 1 9.54 0 0.00206 0 -0.563 816.48 760 0 0.1 -0.00192 -0.00147 0.465 0.64 0.534 0.38];
    case  96, C=[-2.41 -2.45 -2.21 -2.41 2.48 -0.0071 1.18 6.2 -1.09 0.048 -0.000227 4.5 1 9.53 0 0.00193 0 -0.544 809.05 760 0 0.1 -0.00161 -0.00146 0.458 0.64 0.537 0.382];
    case  97, C=[-2.51 -2.56 -2.31 -2.51 2.49 -0.00588 1.19 6.2 -1.09 0.0501 -0.000185 4.5 1 9.5 0 0.00181 0 -0.522 802.67 760 0 0.1 -0.00135 -0.00145 0.45 0.64 0.54 0.386];
    case  98, C=[-2.78 -2.83 -2.56 -2.75 2.5 -0.00125 1.2 6.2 -1.07 0.058 -0.0000884 4.5 1 9.36 0 0.00155 0 -0.476 790.21 760 0 0.1 -0.000823 -0.00142 0.443 0.639 0.538 0.387];
    case  99, C=[-3.05 -3.12 -2.84 -3.01 2.49 -0.0000625 1.21 6.2 -1.04 0.0673 0 4.5 1 9.1 0 0.00134 0 -0.437 782.06 760 0 0.1 -0.000456 -0.0014 0.436 0.636 0.535 0.39];
    case 100, C=[-3.33 -3.41 -3.1 -3.26 2.47 0 1.19 6.2 -1.03 0.0808 0 4.5 1 8.69 0 0.00118 0 -0.4 776.36 760 0 0.1 -0.000215 -0.00138 0.427 0.634 0.533 0.393];
    case 101, C=[-3.59 -3.68 -3.37 -3.49 2.43 0 1.18 6.2 -1.02 0.0967 0 4.5 1 8.29 0 0.00106 0 -0.366 772.82 760 0 0.1 -0.0000704 -0.00138 0.419 0.63 0.53 0.395];
    case 102, C=[-3.84 -3.94 -3.64 -3.72 2.38 0 1.16 6.2 -1.02 0.112 0 4.5 1 7.81 0 0.000975 0 -0.338 770.95 760 0 0.1 -0.00000679 -0.00137 0.411 0.628 0.525 0.399];
    case 103, C=[-4.07 -4.18 -3.89 -3.93 2.34 0 1.15 6.2 -1.02 0.125 0 4.5 1 7.37 0 0.000923 0 -0.317 770.1 760 0 0.1 0 -0.00137 0.402 0.626 0.507 0.403];
    case 104, C=[-4.29 -4.4 -4.14 -4.14 2.31 0 1.14 6.2 -1.01 0.138 0 4.5 1 6.8 0 0.000895 0 -0.303 768.53 760 0 0.1 0 -0.00137 0.399 0.618 0.496 0.416];
    case 105, C=[-4.5 -4.61 -4.39 -4.33 2.26 0 1.14 6.2 -1.01 0.15 0 4.5 1 6.43 0 0.000885 0 -0.292 768.71 760 0 0.1 0 -0.00137 0.382 0.608 0.493 0.418];
    case 106, C=[-4.69 -4.8 -4.61 -4.51 2.22 0 1.16 6.2 -1.01 0.158 0 4.5 1 6.13 0 0.000888 0 -0.284 771.66 760 0 0.1 0 -0.00136 0.379 0.593 0.49 0.418];
    case 107, C=[-4.87 -4.99 -4.8 -4.67 2.19 0 1.16 6.2 -1.02 0.16 0 4.5 1 5.93 0 0.000896 0 -0.277 775 760 0 0.1 0 -0.00136 0.375 0.581 0.484 0.418];
end