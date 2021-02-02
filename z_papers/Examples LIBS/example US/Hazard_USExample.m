%%
clearvars
close all
clc
subplot(2,2,1);
b     = 0.7;
Mmin  = 4.0;
Mmax  = 7.5;
beta  = log(10)*b;
M     = 7;
rateM = 1/200;
ccdf  = (1-exp(-beta*(M-Mmin)))/(1-exp(-beta*(Mmax - Mmin)));
NMmin = rateM/(1-ccdf);
m     = linspace(4,7.5,100);
ccdf  = (1-exp(-beta*(m-Mmin)))/(1-exp(-beta*(Mmax - Mmin)));
rate  = NMmin*(1-ccdf);
plot(m,rate)

b     = 0.6;
Mmin  = 4.0;
Mmax  = 7.5;
beta  = log(10)*b;
M     = 7;
rateM = 1/600;
ccdf  = (1-exp(-beta*(M-Mmin)))/(1-exp(-beta*(Mmax - Mmin)));
NMmin = rateM/(1-ccdf);
m     = linspace(4,7.5,100);
ccdf  = (1-exp(-beta*(m-Mmin)))/(1-exp(-beta*(Mmax - Mmin)));
rate  = NMmin*(1-ccdf);
hold on
plot(m,rate)

box off
set(gca,'yscale','log')
xlabel('Magnitude')
ylabel('Magnitude rate')
L=legend('MR1','MR2');
L.Box='off';
L.Title.String='Scenario';
set(gca,'ytick',10.^[-4:1:0]);
text(3,1,'(a)')

%%
clearvars

PGA=[0.0001	1.13281421840786
0.000162377673918872	1.13050056022367
0.000263665089873036	1.12364553323459
0.00042813323987194	1.10722835718034
0.000695192796177561	1.07462897217556
0.00112883789168469	1.01953226972331
0.00183298071083244	0.93830808464662
0.00297635144163132	0.831716322605608
0.00483293023857175	0.705283298337386
0.00784759970351461	0.56838852448142
0.0127427498570313	0.432665839527475
0.0206913808111479	0.30947232702622
0.0335981828628378	0.206647592721742
0.0545559478116852	0.127283839567906
0.0885866790410082	0.0707517223920346
0.143844988828766	0.0340868468099432
0.233572146909012	0.0133366518050236
0.379269019073225	0.00391753356940266
0.615848211066026	0.000803094361508571
1	0.000107920930467755];

SA1=[1e-05	1.13357985227352
1.83298071083244e-05	1.13354102435725
3.35981828628378e-05	1.13303567914095
6.15848211066027e-05	1.12920934507846
0.000112883789168469	1.11170826764499
0.000206913808111479	1.06086678969449
0.000379269019073225	0.960458547417952
0.000695192796177561	0.813865100904389
0.00127427498570313	0.642939817632106
0.00233572146909012	0.475674498373122
0.0042813323987194	0.333825036480283
0.00784759970351461	0.225648941146927
0.0143844988828766	0.147496880441308
0.0263665089873036	0.092189824378268
0.0483293023857175	0.0540134220136262
0.0885866790410082	0.0288201951375121
0.162377673918872	0.0134570975159214
0.297635144163132	0.0051781550894913
0.545559478116851	0.00149952825573294
1	0.000294692549319883];

CAVdp=[0.1	1.13358114507276
0.172043377848618	1.13357373982302
0.295989238615622	1.1334851631618
0.50922988418272	1.13276211349841
0.876096293762555	1.12868661208438
1.50726565699565	1.11257238108676
2.59315074944747	1.06692006923384
4.46134414205616	0.971661972834535
7.67544715944484	0.820374147701506
13.2050985580947	0.631170649679857
22.7184976075852	0.439270717824348
39.0856706805469	0.277616013331749
67.2443080935996	0.161672594436068
115.68937905516	0.0884288338864996
199.035915538588	0.0459341781171865
342.428112224509	0.022475130383894
589.124890974299	0.0100380716001227
1013.55036217917	0.00388937648304913
1743.74627928994	0.00123070561382644
3000	0.000300118915110701];

CAV=[
0.01	1.13358158015703
0.0158214613571711	1.13358158015697
0.0250318639476458	1.13358158015
0.0396040668145641	1.13358157967557
0.0626594212693448	1.13358155952134
0.0991363612275642	1.13358102001891
0.156848210825246	1.13357180315976
0.248156790651305	1.13346963674229
0.392620307380922	1.13271895332142
0.621182702126789	1.12896062320663
0.98280181174421	1.11568739004888
1.55493608862687	1.08123594663309
2.46013612390808	1.01256914603612
3.89229486177924	0.902943252519546
6.15817927463558	0.75765574304435
9.74313954241786	0.594044651867706
15.415070576789	0.435590715713965
24.3888943448732	0.301505265158517
38.5867949421539	0.199053266860591
61.0499485074372	0.125114467845855
96.5899401167702	0.0733625569852198
152.819400504895	0.0388666253234497
241.782623971424	0.0181840689337272
382.535444199932	0.00745858115492244
605.226974815749	0.00257013149124347
957.557519436493	0.000662491635915036
1514.99592910331	0.000109947891817693
2396.94495485795	1.03277164331496e-05
3792.31719785512	5.02441483578824e-07
6000	1.19721075053248e-08];

ax(1)=subplot(2,2,2);
hold on
plot(PGA(:,1),PGA(:,2))
plot(SA1(:,1),SA1(:,2))
set(gca,'xscale','log','yscale','log','xtick',10.^[-3:1:0],'xlim',[1e-3 1],'ylim',[1e-5 1e1],'fontsize',9)
L=legend('PGA','SA1');L.Box='off';
xlabel('PGA, SA1 (g)')
ylabel('MRE')
text(2e-4,10,'(b)')

ax(2)=subplot(2,2,3);
hold on
plot(CAVdp(:,1)/980.66,CAVdp(:,2)); %CAV   500 m/s
plot(CAV  (:,1)/980.66,CAV  (:,2)); %CAVdp 760 m/s
set(gca,'xscale','log','yscale','log','xtick',10.^[-3:1:0],'xlim',[1e-3 4],'ylim',[1e-5 1e1],'fontsize',9)
L=legend('CAVdp','CAV');L.Box='off';
xlabel('CAVdp,CAV (g\cdots)')
ylabel('MRE')
text(2e-4,10,'(c)')

set(gcf,'position',[   403   122   642   544])