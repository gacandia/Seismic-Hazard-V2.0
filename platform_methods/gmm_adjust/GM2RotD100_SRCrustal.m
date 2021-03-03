function[SF]=GM2RotD100_SRCrustal(IM)

IM(IM==0)=0.01;
IM(IM<0)=NaN;
IM(IM>10)=NaN;

% xData=T, yData=meanRatio for intraslab earthquakes M>5 and 400 < Vs30 < 900
xData=[ 0.0100
    0.0200
    0.0500
    0.0750
    0.1000
    0.1500
    0.2000
    0.2500
    0.3000
    0.4000
    0.5000
    0.6000
    0.7500
    1.0000
    1.5000
    2.0000
    2.5000
    3.0000
    4.0000
    5.0000
    6.0000
    7.5000
    10.0000];

yData=[    1.2172
    1.2176
    1.1968
    1.2050
    1.2267
    1.2231
    1.2274
    1.2317
    1.2535
    1.2390
    1.2528
    1.2521
    1.2474
    1.2471
    1.2508
    1.2584
    1.2510
    1.2476
    1.2533
    1.2504
    1.2528
    1.2500
    1.2474];

SF = interp1(log(xData),yData,log(IM),'pchip','extrap');
