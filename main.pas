program MomRadio;

{$mode delphi}{$h+}

uses cthreads,cmem,heaptrc,gtk2,gdk2,glib2,gdk2pixbuf,bass,classes;


const
Titles:array[0..5] of ^gchar = ('Авторадио',				
				'Русское радио',
				'Радио Максимум',
				'Европа плюс',
				'Хит FM',
				'Юмор FM');


Urls:array[0..5] of pgchar = ('http://77.73.90.46:1055/avtoradio',
				'http://radio.north.kz:8000/russian-128.m3u',
				'http://radio.north.kz:8000/rmaximum.m3u',
				'http://ep128server.streamr.ru:8030/ep128',
				'',
				'http://89.20.132.26:8000/v5_1');

Images:array[0..5] of pgchar = ('images/auto.jpg','images/rusradio.jpg','images/maximum.jpg','images/europa+.jpg','images/hit.jpg','images/ufm.jpg');


type
 XZ = (PIXBUF_COL,TEXT_COL);

Type
    TMyThread = class(TThread)
    private
      URL: string;
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;


var
window, vbox,treeView, toolbar: pGtkWidget;
play,sep,about,quit:pGtkToolItem;
renderer:pGtkCellRenderer;
column:pGtkTreeViewColumn;
select:pGTKTreeSelection;
MyThread:TMyThread;
sel:pgchar;
ico:pGdkPixbuf;
stream : HSTREAM;


function createModel():pGtkTreeModel;cdecl;
var
 pixbuf:pGdkPixbuf;
 iter:TGtkTreeIter;
 store:pGtkListStore;
 i:gint;
begin
 store:= gtk_list_store_new(2,GDK_TYPE_PIXBUF,G_TYPE_STRING);
 for i:=0 to 5 do begin
  pixbuf:=gdk_pixbuf_new_from_file(images[i],nil);
  gtk_list_store_append(store,@iter);
  gtk_list_store_set(store,@iter,PIXBUF_COL,pixbuf,TEXT_COL,titles[i],-1);
  gdk_pixbuf_unref(pixbuf);
 end;
 createModel:=GTK_TREE_MODEL(store);
end;




constructor TMyThread.Create(CreateSuspended : boolean);
  begin
    FreeOnTerminate := True;
    inherited Create(CreateSuspended);
  end;
 

procedure TMyThread.Execute;
begin    
    stream:=0; 
    BASS_StreamFree(stream);
    stream:= BASS_StreamCreateURL(PAnsichar(AnsiString(MyThread.URL)),0,BASS_STREAM_STATUS,nil,0);
    BASS_ChannelPlay(Stream,False);
  end;



procedure Free();
begin
gtk_tool_button_set_stock_id(PGtkToolButton(play),GTK_STOCK_MEDIA_PLAY);
MyThread.Terminate;
end;



procedure PlayStream(URL:string);
var
btn:PGtkToolButton;
begin
btn:=PGtkToolButton(play);
BASS_StreamFree(stream);
if (gtk_tool_button_get_stock_id(btn)=GTK_STOCK_MEDIA_PLAY) then begin
	gtk_tool_button_set_stock_id(btn,GTK_STOCK_MEDIA_STOP);
	MyThread := TMyThread.Create(True);
	MyThread.FreeOnTerminate:=true;
	MyThread.URL:=URL;
	MyThread.Start;
end
else free();

end;


procedure myfunc(treeview:pGTKtreeview;path:pgtktreepath);cdecl;
var
 iter:TGtkTreeIter;
 model:pGtkTreeModel;
 n,m:string;
 name:^gchar;
 i:0..5;
begin
 model:= gtk_tree_view_get_model(treeview);
 if (gtk_tree_model_get_iter(model,@iter,path)) then begin
  gtk_tree_model_get(model,@iter,TEXT_COL,@name,-1);
  n:=name;
  if (MyThread<>nil) then free();
  for i:=0 to 5 do begin m:=titles[i];if (m=n) then PlayStream(urls[i]);end;
 end;
end;

procedure selection_changed(select:pGtkTreeSelection);cdecl;
var
    treeView:pGtkTreeView;
    model:pGtkTreeModel;
    iter:TGtkTreeIter;
    n,m:string;
    active: ^gchar;
    i:0..5;
begin    
    treeView:= gtk_tree_selection_get_tree_view(select);
    model:= gtk_tree_view_get_model(treeView);
    gtk_tree_selection_get_selected(select, @model, @iter);
    gtk_tree_model_get(model, @iter,1, @active,-1);
    n:=active;
    for i:=0 to 5 do begin m:=titles[i];if (m=n) then sel:=urls[i];end;
end;

procedure PlayBtnClick();cdecl;
begin
if sel<>'' then
PlayStream(sel);
end;


procedure show_about(widget:pGtkWidget;data:gpointer);cdecl;
var
dialog:pGTKWidget;
icon:pGdkPixbuf;
begin
  dialog:= gtk_about_dialog_new();
  icon:=gdk_pixbuf_new_from_file('icons/icon.png',nil);
  gtk_about_dialog_set_logo(GTK_ABOUT_DIALOG(dialog),icon);
  gtk_about_dialog_set_name(GTK_ABOUT_DIALOG(dialog), 'MomRadio');
  gtk_about_dialog_set_version(GTK_ABOUT_DIALOG(dialog), '0.1'); 
  gtk_about_dialog_set_copyright(GTK_ABOUT_DIALOG(dialog), '(c) Yurij Bukatkin');
  gtk_about_dialog_set_comments(GTK_ABOUT_DIALOG(dialog), ' Russian simple radio tuner for PC. ');
  gtk_about_dialog_set_website(GTK_ABOUT_DIALOG(dialog), 'http://www.deslum.com/MomPlayer');
  gtk_about_dialog_set_translator_credits(GTK_ABOUT_DIALOG(dialog), 'Application icon designed by Madeliniz'+#13+
'License: CC Attribution Non-Commercial'+#13+'http://madeliniz.deviantart.com/'); 
  gtk_dialog_run(GTK_DIALOG (dialog));
  gtk_widget_destroy(dialog);
end;

procedure CreateUI();
begin
window := gtk_window_new(GTK_WINDOW_TOPLEVEL);
gtk_window_set_title(GTK_WINDOW(window),'MomRadio');
ico:=gdk_pixbuf_new_from_file('icons/icon.png',nil);
gtk_window_set_icon(GTK_WINDOW(window),ico);
gtk_window_set_default_size(GTK_WINDOW(window),230,420);
gtk_window_set_type_hint(GTK_WINDOW(window),GDK_WINDOW_TYPE_HINT_DIALOG);

treeView:= gtk_tree_view_new_with_model(createModel());
renderer:=gtk_cell_renderer_pixbuf_new();
column:=gtk_tree_view_column_new_with_attributes('',renderer,'pixbuf',PIXBUF_COL,nil);
gtk_tree_view_append_column(GTK_TREE_VIEW(treeView),column);
renderer:=gtk_cell_renderer_text_new();
column:=gtk_tree_view_column_new_with_attributes('',renderer,'text',TEXT_COL,nil);
gtk_tree_view_append_column(GTK_TREE_VIEW(treeView),column);
vbox:= gtk_vbox_new(false,2);
gtk_container_add(GTK_CONTAINER(window),vbox);
toolbar:= gtk_toolbar_new();
gtk_toolbar_set_style(Gtk_Toolbar(toolbar),GTK_TOOLBAR_ICONS);

play:= gtk_tool_button_new_from_stock(GTK_STOCK_MEDIA_PLAY);
sep:= gtk_separator_tool_item_new();
about:= gtk_tool_button_new_from_stock(GTK_STOCK_DIALOG_INFO);
quit:= gtk_tool_button_new_from_stock(GTK_STOCK_QUIT);

gtk_toolbar_insert(GTK_TOOLBAR(toolbar),play,-1);
gtk_toolbar_insert(GTK_TOOLBAR(toolbar),sep,-1);
gtk_toolbar_insert(GTK_TOOLBAR(toolbar),about,-1);
gtk_toolbar_insert(GTK_TOOLBAR(toolbar),quit,-1);

gtk_box_pack_start(GTK_BOX(vbox),toolbar,false,false,1);
gtk_box_pack_start(GTK_BOX(vbox),treeview,true,true,2);
select:= gtk_tree_view_get_selection(GTK_TREE_VIEW(treeView));
gtk_widget_show_all(window);
g_signal_connect(G_OBJECT(select), 'changed', G_CALLBACK(@selection_changed), nil);
g_signal_connect(treeview,'row-activated',G_CALLBACK(@myfunc),nil);
g_signal_connect(G_OBJECT(play),'clicked',G_CALLBACK(@PlayBtnClick),treeview);
g_signal_connect(G_OBJECT(about), 'clicked', G_CALLBACK(@show_about),nil); 
g_signal_connect(G_OBJECT(quit),'clicked',GTK_SIGNAL_FUNC(@gtk_exit),nil);
gtk_signal_connect(GTK_OBJECT(window),'destroy',GTK_SIGNAL_FUNC(@gtk_exit),NIL);
end;


begin
gtk_init(@argc, @argv);
Bass_Init(-1,44100,0,0,nil);
Bass_SetConfig(BASS_CONFIG_NET_PLAYLIST,1);
createUI();
gtk_main();
end.
