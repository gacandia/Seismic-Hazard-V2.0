function[SPEC,MRZ]=runDSPEC1(T0,periods,h,opt,source,Nsource,epsilon,site_selection)
% runs a single branch of the logic tree for GMM's of type 'regular','cond','udm'

ellip  = opt.ellipsoid;
xyz    = gps2xyz(h.p,ellip);
Nsite  = size(xyz,1);
NIM    = length(periods);
ind    = zeros(Nsite,length(source));

for i=site_selection
    ind(i,:)=selectsource(opt.MaxDistance,xyz(i,:),source);
end

SPEC = nan(Nsite,NIM,Nsource);
MRZ  = nan(Nsite,8  ,Nsource);
for k=site_selection
    ind_k      = ind(k,:);
    sptr       = find(ind_k);
    xyzk       = xyz(k,:);
    valuek      = h.value(k,:);
    for i=sptr
        source(i).media = valuek;
        if any(source(i).gmm.T>=0)
            [SPEC(k,:,i),MRZ(k,:,i)]=runsource(source(i),xyzk,periods,T0,ellip,epsilon,h.param);
        end
    end
end

return

function [SPEC,MRZ]=runsource(source,r0,periods,T0,ellip,epsilon,hparam)

NIM  = length(periods);
SPEC = zeros(1,NIM);
[param,~,MRZ] = source.pfun(r0,source,ellip,hparam);

%% DEFINES SCENARIO
mu = source.gmm.handle(T0,param{:});
[~,ind]=max(mu);
B  = mGMPEdspec(source.gmm,param);
switch source.gmm.type
    case 'frn'
        Ndepend=length(B);
        for ii=1:Ndepend
            for i=1:length(B{ii})
                if B{ii}(i)
                    param{4+ii}{i}=param{4+ii}{i}(ind);
                end
            end
        end
    otherwise
        for i=1:length(B)
            if B(i)==1 && isnumeric(param{i})
                param{i}=param{i}(ind);
            end
        end
end
MRZ = [MRZ(ind,:),ind];
MRZ(5:7)=xyz2gps(MRZ(:,5:7),ellip);

%% COMPUTES RESPONSE SPECTRUM OF CONTROLLING SCENARIOAS

for j=1:NIM
    [mu,sig] = source.gmm.handle(periods(j),param{:});
    SPEC(j)  = exp(mu+epsilon*sig);
end
