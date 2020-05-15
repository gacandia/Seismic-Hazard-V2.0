function [data]=runCMS_m1_CSS(handles,im1,lambda1,Tr,source)

Tcss  = handles.Tcss;
Tcond = str2double(handles.param{2});
handles.opt.im=im1;

% set up data
ellipsoid   = handles.opt.ellipsoid;
site_ptr    = handles.pop_site.Value;
site        = handles.h.p(site_ptr,:);
VS30        = handles.h.VS30(site_ptr);
r0          = gps2xyz(site,ellipsoid);

N0          = numel(Tcss);
T           = unique([Tcss;Tcond]);
N1          = numel(T);

Tcond_ptr   = T==Tcond;
opt         = handles.opt;
Nsource     = length(source);


% compute Hazard Deagregation for T* at Return Period Tr
logy    = log(lambda1(:,Tcond_ptr));
logx    = log(im1(:,Tcond_ptr));
logyy   = log(1/Tr);
logxx   = interp1(logy,logx,logyy,'pchip');
im2     = exp(logxx);
opt2    = opt;
opt2.im = im2;
opt2.IM = Tcond;
lambda2 = nan(1,1,1,Nsource,1);
deagg2  = runhazard2(im2,Tcond,site,VS30,opt2,source,Nsource,1);

for i=1:numel(deagg2)
    if ~isempty(deagg2{i})
        lambda2(i)=sum(deagg2{i}(:,3));
    end
end
lambda2 = permute(lambda2,[2,1,3,4]);
lambda2 = nansum(lambda2,4);
[handles,MRscen] = run_func(handles,source,lambda2,deagg2);

M     = MRscen(1);
ptr1  = MRscen(4);
ptr2  = MRscen(5);

% compute UHS
uhs  = uhspectrum(handles.opt.im,lambda1,1/Tr);

% compute GMPE prediction
source        = source(ptr1);
gmpefun       = source.gmm.handle;
source.mscl   = [M 1];
source.hypm   = source.hypm(ptr2,:);
source.aream  = source.aream(ptr2,:);
source.normal = source.normal(ptr2,:);
source.media  = VS30;
ellip         = handles.opt.ellipsoid;
switch source.obj
    case 1, param = param_circ(r0,source,ellip);  % point1
    case 2, param = param_circ(r0,source,ellip);  % line1
    case 3, param = param_circ(r0,source,ellip);  % area1
    case 4, param = param_circ(r0,source,ellip);  % area2
    case 5, param = param_rect(r0,source,ellip);  % area3
    case 6, param = param_circ(r0,source,ellip);  % area4
    case 7, param = param_circ(r0,source,ellip);  % volume1
end

mu  = zeros(size(uhs));
sig = zeros(size(uhs));
for j=1:length(T)
    [mu(j),sig(j)] = gmpefun(T(j),param{:});
end

% Step 4: compute e*
eTs = (log(uhs(Tcond_ptr))-mu(Tcond_ptr))/sig(Tcond_ptr);

% Step 5: compute ebar
methods = pshatoolbox_methods(4,handles.corrV);
Cond_param.opp       = 0;
switch source.numgeom(1)
    case 1, Cond_param.mechanism = 'interface';
    case 2, Cond_param.mechanism = 'intraslab';
    case 3, Cond_param.mechanism = 'crustal';
end
        
Cond_param.M         = M;
Cond_param.residual  = 'phi';
Cond_param.direction = 'horizontal';
rho = methods.func(Tcond,T,Cond_param);

% Step 6: compute cms
sigCMS  = sig.*sqrt(1-rho.^2);
cms     = exp(mu+eTs*rho.*sig);

% create Output
if N0~=N1
    data    = [uhs,cms(~Tcond_ptr),sigCMS(~Tcond_ptr),rho(~Tcond_ptr)];
else
    data    = [uhs,cms,sigCMS,rho];
end
    
function [handles,MRscen,rmin,rmax,Rcenter,Mcenter]=run_func(handles,source,lambda2,deagg2)

deagg{1}    = vertcat(deagg2{1,1,1,:});
indsource   = zeros(0,2);
Nsources    = size(deagg2,4);
for i=1:Nsources
    dg         = deagg2{1,1,1,i};
    if ~isempty(dg)
        Nscen     = size(dg,1);
        NM        = size(source(i).mscl,1);
        NR        = size(source(i).hypm,1);
        ptr2      = sort(repmat((1:NR)',NM,1));
        indsource = [indsource;[i*ones(Nscen,1),ptr2]];  %#ok<*AGROW>
    end
end

if isempty(deagg)
    return
end

% build deaggregation chart 'dchart'
rmin      = handles.Rbin(1);
rmax      = handles.Rbin(end);
Rcenter   = mean(handles.Rbin,2);
Mcenter   = mean(handles.Mbin,2);
handles.dchart = deagghazard(deagg,lambda2,Mcenter,Rcenter);

Mbar = sum(deagg{1}(:,1).*deagg{1}(:,3))/sum(deagg{1}(:,3));
Rbar = sum(deagg{1}(:,2).*deagg{1}(:,3))/sum(deagg{1}(:,3));
ind1 = and(handles.Mbin(:,1)<Mbar,handles.Mbin(:,2)>Mbar);
ind2 = and(handles.Rbin(:,1)<Rbar,handles.Rbin(:,2)>Rbar);

MBIN = handles.Mbin(ind1,:);
RBIN = handles.Rbin(ind2,:);
ind  = (deagg{1}(:,1)>=MBIN(1)).*(deagg{1}(:,1)<=MBIN(2)).*(deagg{1}(:,2)>=RBIN(1)).*(deagg{1}(:,2)<=RBIN(2))==1;

DG     = [deagg{1}(ind,:),indsource(ind,:)];
mean1  = mean(DG(:,1:2),1);
std1   = std(DG(:,1:2),0,1);
disc1  = bsxfun(@times,bsxfun(@minus,DG(:,1:2)  ,mean1),1./std1);
disc2  = bsxfun(@times,bsxfun(@minus,[Mbar,Rbar],mean1),1./std1);
DISC   = sum(bsxfun(@minus,disc1,disc2).^2,2);
[~,indmin] = min(DISC);
MRscen = DG(indmin,:);



