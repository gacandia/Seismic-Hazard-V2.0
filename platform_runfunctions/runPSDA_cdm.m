function[handles]=runPSDA_cdm(handles)
delete(findall(handles.ax1,'type','line'));
drawnow
psda_param = handles.paramPSDA;
d          = psda_param.d;
realSa     = handles.paramPSDA.realSa;
realD      = handles.paramPSDA.realD;
RandType   = handles.paramPSDA.rng;    % shuffle or default
meth       = handles.paramPSDA.method; % MC or PC

Nscenarios = realSa*realD;
Nd         = length(d);
opt0       = handles.opt;
optL       = handles.opt;

TCDM       = handles.tableCDM.Data;
optL.IM    = PSDA_im_list(handles,TCDM);
optL.im    = retrieve_im(opt0.im,opt0.IM,optL.IM);
handles.site_selection = 1:size(handles.h.p,1);
Nsites     = length(handles.site_selection);
Nsources   = max(sum(handles.sys.Nsrc,1));
Nmodels    = size(handles.tableCDM.Data,1);
handles.lambdaCDM = zeros(Nscenarios,Nsites,Nd,Nsources,Nmodels);

fprintf('\n');
spat  = 'Site %-17g | Branch %-3g of %-49g Runtime:  %-4.3f s\n';
t0 = tic;
fprintf('                               SLOPE DISPLACEMENT HAZARD \n');
fprintf('-----------------------------------------------------------------------------------------------------------\n');

SMLIB = handles.sys.SMLIB;
id    = {handles.sys.SMLIB.id};
ellipsoid = opt0.ellipsoid;

s=rng;
rng(RandType);

for site_ptr=1:Nsites
    site  = handles.h.p(site_ptr,:);
    VS30  = handles.h.VS30(site_ptr);
    r0    = gps2xyz(site,ellipsoid);
    xyz   = gps2xyz(site,ellipsoid);
    
    for model_ptr=1:Nmodels
        ti=tic;
        Ts_param = str2double(regexp(TCDM{model_ptr,3},'\,','split'));
        ky_param = str2double(regexp(TCDM{model_ptr,4},'\,','split'));
        B        = zeros(3,1);
        
        [~,B(1)] = intersect(id,TCDM{model_ptr,5}); fun1 = SMLIB(B(1)).func; % interface
        [~,B(2)] = intersect(id,TCDM{model_ptr,6}); fun2 = SMLIB(B(2)).func; % slab
        [~,B(3)] = intersect(id,TCDM{model_ptr,7}); fun3 = SMLIB(B(3)).func; % crustal
        
        hazpointers= str2double(regexp(TCDM{model_ptr,2},'\,','split'));
        allsource  = buildmodelin(handles.sys,hazpointers,handles.opt.ShearModulus);
        ind        = selectsource(opt0.MaxDistance,xyz,allsource);
        ind        = find(ind);
        
        % run sources
        for source_ptr=ind
            source = allsource(source_ptr);
            source.media = VS30;
            switch source.numgeom(1)
                case 1 , fun = fun1; Bs=B(1); %interface
                case 2 , fun = fun2; Bs=B(2); %intraslab
                case 3 , fun = fun3; Bs=B(3); %crustal
            end
            
            integrator = SMLIB(Bs).integrator;
            Safactor   = SMLIB(Bs).Safactor;
            Ts         = Ts_param(1);
            IMslope    = Safactor*Ts.*(Safactor>=0)+Safactor.*(Safactor<0);
            
            [~,period_ptr]  = intersect(optL.IM,IMslope);
            im              = optL.im(:,period_ptr);

            if integrator==5 && strcmp(meth,'PC')
                t1=cputime;[~,Cz]  = runPCE(source,r0,IMslope,im,realSa,ellipsoid); t1 = cputime-t1;
                t2=cputime;lambda  = fun(Ts_param, ky_param,psda_param, im,[],Cz);  t2 = cputime-t2;
                %disp([t1 t2])
            end

            if integrator==5 && strcmp(meth,'MC')
                t1=cputime;MRE     = runMCS(source,r0,IMslope,im,realSa,ellipsoid); MRE = permute(MRE,[1 3 2]); t1 = cputime-t1;
                t2=cputime;lambda  = fun(Ts_param, ky_param, psda_param, im, MRE,[]);t2 = cputime-t2;
                %disp([t1 t2])
            end
            
            if integrator==6
                im      = handles.haz2.imstandard;
                [~,Cz]  = runPCE(source,r0,IMslope,im,realSa,ellipsoid);
                deagg   = handles.haz2.deagg(site_ptr,:,:,source_ptr);
                [M,dPm] = getMdPm(deagg);
                lambda  = fun(Ts_param, ky_param, psda_param,im,M,dPm,Cz);
            end
            
            handles.lambdaCDM(:,site_ptr,:,source_ptr,model_ptr) = lambda;
        end
        fprintf(spat,site_ptr,model_ptr,Nmodels,toc(ti))
    end
end

fprintf('-----------------------------------------------------------------------------------------------------------\n');
fprintf('%-88sTotal:     %-4.3f s\n','',toc(t0));

% restores rng
rng(s);

function[IM,imethod]=PSDA_im_list(handles,TCDM)

hazard  = regexp(TCDM(:,2),'\,','split');
hazard  = str2double(vertcat(hazard{:}));

ME      = handles.ME;
geomptr = unique(hazard(:,1));
s       = unique(vertcat(handles.sys.mech{geomptr}));
[~,B]   = intersect([1;2;3],s);
func    = {ME.str}';
Smodels = TCDM(:,B+4);
Smodels = unique(Smodels(:));
usedM   = cell(size(Smodels));
for i=1:length(usedM)
    [~,B]=intersect({handles.sys.SMLIB.id},Smodels{i});
    usedM{i}=handles.sys.SMLIB(B).str;
end
usedM  = unique(usedM);



[~,b]=intersect(func,usedM);
IMfactor = zeros(0,1);
for i=1:length(b)
    IMfactor = [IMfactor;ME(b(i)).Safactor(:)];
end
IMfactor = unique(IMfactor);

Tnat = regexp(TCDM(:,3),'\,','split');
Tnat = str2double(vertcat(Tnat{:}));
Tnat = unique(Tnat(:,1));
IM  = [];
for i=1:length(IMfactor)
    if IMfactor(i)<=0
        IM = [IM;IMfactor(i)]; %#ok<*AGROW>
    else
        IM = [IM;IMfactor(i)*Tnat]; %#ok<*AGROW>
    end
end

imethod = zeros(1,length(usedM));
for i=1:length(imethod)
    [~,B]=intersect(func,usedM{i});
    imethod(i)=ME(B).integrator;
end
IM      = unique(IM);
imethod = unique(imethod);

function[im]=retrieve_im(im0,IM0,IM)

[r,c]= size(im0);
NIM  = length(IM);
im = zeros(r,NIM);

if c==1
    im = repmat(im0,1,length(IM));
    if any(IM==-1)
        im(:,IM==-1)=logsp(0.001,60,r)';
    end
    return;
end

for i=1:NIM
    if IM(i)<0
        ind = IM0==IM(i);
        im(:,i)=im0(:,ind);
    else
        disc = abs(IM0-IM(i));
        [~,ind] = min(disc);
        im(:,i)=im0(:,ind);
    end
end


