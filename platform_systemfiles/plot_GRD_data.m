function plot_GRD_data(h_ax,p,t,u,tit,ptype)

F =  scatteredInterpolant(p(:,1),p(:,2),u(:),'linear','none');

delete(findall(h_ax,'tag','fill'))
delete(findall(h_ax,'tag','contour'))
fig=h_ax.Parent;
delete(findall(fig,'type','colorbar'))


H1=patch('parent',h_ax,...
    'vertices',p,...
    'faces',t,...
    'facevertexcdata',u(:),...
    'facecol','interp',...
    'edgecol','none',...
    'linewidth',0.5,...
    'facealpha',0.7,...
    'ButtonDownFcn',{@grd_click,h_ax,F},...
    'tag','fill',...
    'visible','off');

[~,H2]=contour(h_ax,...
    reshape(p(:,1),size(u)),...
    reshape(p(:,2),size(u)),...
    u,...
    12,...
    'tag','contour',...
    'ButtonDownFcn',{@grd_click,h_ax,F},...
    'visible','off');

switch ptype
    case 0
        H1.Visible='on';
    case 1
        H2.Visible='on';
end
ch=findall(h_ax,'tag','siteplot');
ch.ButtonDownFcn={@grd_click,h_ax,F};
uistack(ch,'top')

C=colorbar('peer',h_ax,'ylim',[min(u(:)),max(u(:))],'position',[0.9332    0.0935    0.0285    0.6894]);
C.Title.String=tit;

function grd_click(hObject, eventdata, h_ax,F) %#ok<*INUSL>

delete(findall(h_ax,'Tag','grdtext'));
coordinates = get(h_ax,'CurrentPoint');
x   = coordinates(1,1);
y   = coordinates(1,2);
Fxy = F(x,y);
str = sprintf('%3.2g',Fxy);
text(x,y,str,'parent',h_ax,'Tag','grdtext','visible','on');

