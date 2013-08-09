program LUA_DVM;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {Form1},
  LuaInter in 'LuaDvm\LuaInter.pas',
  MappedFile in 'LuaDvm\MappedFile.pas',
  Lc_procs in 'LuaDvm\Lc_procs.pas',
  LuaPackages in 'LuaDvm\LuaPackages.pas',
  LuaPackage_Str in 'LuaDvm\LuaPackage_Str.pas',
  EventProxy in 'LuaDvm\EventProxy.pas',
  BMH_Search in 'LuaDvm\BMH_Search.pas',
  LuaPackage_COM in 'LuaDvm\LuaPackage_COM.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
