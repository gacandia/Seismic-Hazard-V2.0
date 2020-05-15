function [param,val] = mGMPEusp(gmm,SC) %#ok<*INUSD,*DEFNU>

method = pshatoolbox_methods(1);
val    = zeros(1,18);
fun = func2str(gmm.handle);
% switch gmm.type
%     case 'regular',
%     case 'cond',    fun = func2str(gmm.cond.conditioning);
%     case 'udm' ,    fun = 'udm';
%     case 'pce' ,    fun = func2str(gmm.handle);
% end

[~,B]  = intersect({method.str},fun);
val(end)=B;

usp   = gmm.usp;
M     = SC.Mag;
dip   = SC.dip;
width = SC.W;
Zhyp  = SC.Zhyp;
Ztor  = SC.Ztor;
Zbot  = SC.Zbot;
Rrup  = SC.Rrup;
Rhyp  = SC.Rhyp;
Rx    = SC.Rx;
Rjb   = SC.Rjb;
ry0   = SC.Ry0;
Vs30  = SC.Vs30;

switch fun
    case 'Youngs1997'
        media      = 'rock';
        [~,val(4)] = intersect({'rock','soil'},media);
        [~,val(5)] = intersect({'interface','intraslab'},usp{1});
    case 'AtkinsonBoore2003'
        media = 'nehrpb';
        [~,val(4)]=intersect({'nehrpb','nehrpc','nehrpd','nehrpe'},media);
        [~,val(5)]=intersect({'interface','intraslab'},usp{1});
        [~,val(6)]=intersect({'general','cascadia','japan'},usp{2});
    case 'Zhao2006'
        media = Vs30;
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(5)]=intersect({'interface','intraslab','strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{1});
    case 'Mcverry2006'
        media = 'B';
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(4)]= intersect({'A','B','C','D','E'},media);
        [~,val(5)]=intersect({'interface','intraslab','strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{1});
    case 'ContrerasBoroschek2012'
        media = 'rock';
        [~,val(4)]= intersect({'rock','soil'},media);
    case 'BCHydro2012'
        media = Vs30;
        [~,val(6)]=intersect({'interface','intraslab'},usp{1});
        [~,val(7)]=intersect({'forearc','backarc','unknown'},usp{2});
        [~,val(8)]=intersect({'lower','central','upper','none'},usp{3});
    case 'BCHydro2018'
        media = Vs30;
        [~,val(5)]=intersect({'interface','intraslab'},usp{1});
    case 'Arteta2018'
        media = 'rock';
        [~,val(3)]=intersect({'rock','soil'},media);
        [~,val(4)]=intersect({'forearc','backarc'},usp{1});
    case 'Idini2016'
        media = Vs30;
        [~,val(6)]=intersect({'interface','intraslab'},usp{1});
        [~,val(7)]=intersect({'si','sii','siii','siv','sv','svi'},usp{2});
    case 'MontalvaBastias2017'
        media = Vs30;
        [~,val(6)]=intersect({'interface','intraslab'},usp{1});
        [~,val(7)]=intersect({'forearc','backarc','unknown'} ,usp{2});
    case 'MontalvaBastias2017HQ'
        media = Vs30;
        [~,val(6)]=intersect({'interface','intraslab'},usp{1});
        [~,val(7)]=intersect({'forearc','backarc','unknown'} ,usp{2});
    case 'SiberRisk2019'
        media = Vs30;
        [~,val(6)]=intersect({'interface','intraslab'},usp{1});
    case 'Garcia2005'
        [~,val(5)]=intersect({'horizontal','vertical'},usp{1});
    case 'Jaimes2006'
    case 'Jaimes2015'
        [~,val(3)]=intersect({'cu','sct','cdao'},usp{1});
    case 'Jaimes2016'
    case 'GarciaJaimes2017'
        [~,val(3)]=intersect({'vertical','horizontal'},usp{1});
    case 'GarciaJaimes2017HV'
    case 'Bernal2014'
        [~,val(4)]=intersect({'interface','intraslab'},usp{1});
    case 'Sadigh1997'
        media = 'rock';
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(3)]= intersect({'deepsoil','rock'},media);
        [~,val(4)]= intersect({'strike-slip','reverse','reverse-oblique'},usp{1});
    case 'I2008'
        media = Vs30;
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(4)]= intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{1});
    case 'CY2008'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(9)]  = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(10)] = intersect({'mainshock','aftershock'},usp{3});
        [~,val(11)] = intersect({'measured','inferred'},usp{4});
    case 'BA2008'
        media = Vs30;
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(4)] =intersect({'unspecified','strike-slip','normal','reverse'},usp{1});
    case 'CB2008'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(8)] =intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(9)] =intersect({'arbitrary','average'},usp{3});
    case 'AS2008'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(10)] =intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(11)] =intersect({'aftershock','mainshock','foreshock','swarms'},usp{3});
        [~,val(12)] =intersect({'measured','inferred'},usp{4});
    case 'AS1997h'
        %M,Rrup,media,SOF,location,sigmatype
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(3)] =intersect({'rock','deepsoil'},usp{1});
        [~,val(4)] =intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(5)] =intersect({'hangingwall','footwall','other'},usp{3});
        [~,val(6)] =intersect({'arbitrary','average'},usp{4});
    case 'I2014'
        media = Vs30;
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(4)]= intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{1});
    case 'CY2014'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(9)] =intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(10)]=intersect({'measured','inferred'},usp{3});
        [~,val(11)]=intersect({'global','california','japan','china','italy','turkey'},usp{4});
    case 'CB2014'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(12)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(13)] = intersect({'include','exclude'},usp{3});
        [~,val(14)] = intersect({'global','california','japan','china','italy','turkey'},usp{4});
    case 'BSSA2014'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(5)] =intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(6)] =intersect({'global','california','japan','china','italy','turkey'},usp{3});
    case 'ASK2014'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(11)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(12)] = intersect({'mainshock','aftershock'},usp{3});
        [~,val(13)] = intersect({'measured','inferred'},usp{4});
        [~,val(14)] = intersect({'global','california','japan','china','italy','turkey'},usp{5});
    case 'AkkarBoomer2007'
        % M,Rjb,media,SOF,damping
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(3)]  = intersect({'stiff','soft','other'},usp{1});
        [~,val(4)]  = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(5)]  = intersect({'2','5','10','20','30'},sprintf('%g',usp{3}));
    case 'AkkarBoomer2010'
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(3) ] = intersect({'rock','stiff','soft'},usp{1});
        [~,val(4)]  = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
    case 'Arroyo2010'
    case 'Bindi2011'
        media = Vs30;
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(4)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{1});
        [~,val(5)] = intersect({'geoh','z'},usp{2});
    case 'Kanno2006'
    case 'DW12'
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(3)]  = intersect({'sgs-b','sgs-c','sgs-d'},usp{1});
        [~,val(4) ] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
    case 'FG15'
        media = Vs30;
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(5) ] = intersect({'interface','intraslab','strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{1});
        [~,val(6) ] = intersect({'forearc','backarc'},usp{2});
        [~,val(7) ] = intersect({'linear','nonlinear'},usp{3});
    case 'TBA03'
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(3)] = intersect({'sgs-b','sgs-c','sgs-d'},usp{1});
        [~,val(4)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
    case 'BU17'
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(4)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified','intraplate','subduction-interface','subduction-intraslab','subduction-unknown'},usp{1});
        [~,val(5)] = intersect({'cav','cav5','cavstd'},usp{2});
    case 'CB10'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(8)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
    case 'CB19'
        media = Vs30;
        usp{2}= strrep(usp{2},'auto','strike-slip');
        [~,val(12)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{2});
        [~,val(13)] = intersect({'global','california','japan','china','italy','turkey'},usp{3});
    case 'KM06'
        usp{1}= strrep(usp{1},'auto','strike-slip');
        [~,val(3)] = intersect({'strike-slip','normal','normal-oblique','reverse','reverse-oblique','unspecified'},usp{1});
end

switch fun
    case 'Youngs1997',              param = [M,Rrup,Zhyp,media,usp];
    case 'AtkinsonBoore2003',       param = [M,Rrup,Zhyp,media,usp];
    case 'Zhao2006',                param = [M,Rrup,Zhyp,media,usp];
    case 'Mcverry2006',             param = [M,Rrup,Zhyp,media,usp];
    case 'ContrerasBoroschek2012',  param = [M,Rrup,Zhyp,media,usp];
    case 'BCHydro2012',             param = [M,Rrup,Rhyp,Zhyp,media,usp];
    case 'BCHydro2018',             param = [M,Rrup,usp];
    case 'Arteta2018',              param = [M,Rhyp,media,usp];
    case 'Idini2016',               param = [M,Rrup,Rhyp,Zhyp,media,usp];
    case 'MontalvaBastias2017',     param = [M,Rrup,Rhyp,Zhyp,media,usp];
    case 'MontalvaBastias2017HQ',   param = [M,Rrup,Rhyp,Zhyp,media,usp];
    case 'SiberRisk2019',           param = [M,Rrup,Rhyp,Zhyp,media,usp];
    case 'Garcia2005',              param = [M,Rrup,Rhyp,Zhyp,usp];
    case 'Jaimes2006',              param = [M,Rrup,usp];
    case 'Jaimes2015',              param = [M,Rrup,usp];
    case 'Jaimes2016',              param = [M,Rrup,usp];
    case 'GarciaJaimes2017',        param = [M,Rrup,usp];
    case 'GarciaJaimes2017HV',      param = [M,Rrup,usp];
    case 'Bernal2014',              param = [M,Rrup,Zhyp,usp];
    case 'Sadigh1997',              param = [M,Rrup,media,usp];
    case 'I2008',                   param = [M,Rrup,media,usp];
    case 'CY2008',                  param = [M,Rrup,Rjb,Rx,Ztor,dip,media,usp];
    case 'BA2008',                  param = [M,Rjb,media,usp];
    case 'CB2008',                  param = [M,Rrup,Rjb,Ztor,dip,media,usp];
    case 'AS2008',                  param = [M,Rrup,Rjb,Rx,Ztor,dip,width,media,usp];
    case 'AS1997h',                 param = [M,Rrup,usp];
    case 'I2014',                   param = [M,Rrup,media,usp];
    case 'CY2014',                  param = [M,Rrup,Rjb,Rx,Ztor,dip,media,usp];
    case 'CB2014',                  param = [M,Rrup,Rjb,Rx,Zhyp,Ztor,'unk',dip,width,media,usp];
    case 'BSSA2014',                param = [M,Rjb,media,usp];
    case 'ASK2014',                 param = [M,Rrup,Rjb,Rx,ry0,Ztor,dip,width,media,usp];
    case 'AkkarBoomer2007',         param = [M,Rjb,usp];
    case 'AkkarBoomer2010',         param = [M,Rjb,usp];
    case 'Arroyo2010',              param = [M,Rrup,usp];
    case 'Bindi2011',               param = [M,Rjb,media,usp];
    case 'Kanno2006',               param = [M,Rrup,Zhyp,media];
    case 'Cauzzi2015',              param = [M,Rrup,Rhyp,usp];
    
    case 'DW12',                    param = [M,Rrup,usp];
    case 'FG15',                    param = [M,Rrup,Zhyp,media,usp];
    case 'TBA03',                   param = [M,Rrup,usp];
    case 'BU17',                    param = [M,Rrup,Zhyp,usp];
    case 'CB10',                    param = [M,Rrup,Rjb,Ztor,dip,media,usp];
    case 'CB11',                    param = [M,Rrup,Rjb,Ztor,dip,media,usp];
    case 'CB19',                    param = [M,Rrup,Rjb,Rx,Zhyp,Ztor,Zbot,dip,width,media,usp];
    case 'KM06',                    param = [M,Rrup,usp];
    
end