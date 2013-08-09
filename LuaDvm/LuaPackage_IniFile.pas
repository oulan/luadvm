//---------------------------------------------------------
// Package for work with Strings
// wrap some usefull Delphi Strings functions
//--------------------------------------------------------
unit LuaPackage_IniFile;

interface
 uses Windows, Messages, SysUtils,Classes,LuaInter,IniFiles;

 //--------------------------------------------------------------------
 // Pachage Class for collect some general purpose functions
 //--------------------------------------------------------------------
 type Package_IniFile=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function pckg_Create(Params:TList): Integer;
    function ReadSections(Params:TList): Integer;
    function ReadSection(Params:TList): Integer;
    function ReadSectionValues(Params:TList):Integer;
    function ReadSectionValuesOnly(Params:TList):Integer;
    function EraseSection(Params:TList): Integer;
    function ReadString(Params:TList): Integer;
    function WriteString(Params:TList): Integer;
  public
    procedure RegisterFunctions;override;
 end;

//---------------------------------------------------------
// Global Instances of above Packages-Classes
//---------------------------------------------------------
var
  //-- Package Instances (created in Initialization section)
  PACK_INIFILE:Package_IniFile;


implementation
//---------------------------------------------------------
// TIniFile
// Class package.
// Implements set of methods for manipulate contents of
// Windows INI files.
// Note:
// Objects of this class must be created with "Create" method.
// Example:
// local MyIniFile=TIniFile.Create("IniFileName");
// MyIniFile:ReadSection("Section1");
// ....
//---------------------------------------------------------
procedure Package_IniFile.RegisterFunctions;
begin
  Methods.AddObject('Create',TUserFuncObject.CreateWithName('Create',pckg_Create));
  Methods.AddObject('ReadSections',TUserFuncObject.CreateWithName('ReadSections',ReadSections));
  Methods.AddObject('ReadSection',TUserFuncObject.CreateWithName('ReadSection',ReadSection));
  Methods.AddObject('ReadSectionValues',TUserFuncObject.CreateWithName('ReadSectionValues',ReadSectionValues));
  Methods.AddObject('ReadSectionValuesOnly',TUserFuncObject.CreateWithName('ReadSectionValuesOnly',ReadSectionValuesOnly));
  Methods.AddObject('EraseSection',TUserFuncObject.CreateWithName('EraseSection',EraseSection));
  Methods.AddObject('ReadString',TUserFuncObject.CreateWithName('ReadString',ReadString));
  Methods.AddObject('WriteString',TUserFuncObject.CreateWithName('WriteString',WriteString));

  HandledProps:=TStringList.Create; //--- only for show that it is Class package
end;

//---------------------------------------------------------
// Create with file name
//---------------------------------------------------------
function Package_IniFile.pckg_Create(Params:TList): Integer;
var
 Fn:String;
 xIni:TIniFile;
begin
  Result:=0;
  Fn:=String(TXVariant(Params.Items[0]).V);
  xIni:=TIniFile.Create(Fn);
  TXVariant(Params.Items[0]).Ptr:=xIni;
end;

//---------------------------------------------------------
// Read Sections
// Second param must be StringList
//---------------------------------------------------------
function Package_IniFile.ReadSections(Params:TList): Integer;
var
 xIni:TIniFile;
 xSectLst:TStringList;
begin
  Result:=0;
  xIni:=TIniFile(TXVariant(Params.Items[0]).Ptr);
  xSectLst:=TStringList(TXVariant(Params.Items[1]).Ptr);
  xIni.ReadSections(xSectLst);
end;

//---------------------------------------------------------
// xIni:ReadSection("Section1",KeyWordsList);      -- or
// KeywordsList=xIni:ReadSection("Section1",MyLst);
//
// Read Section (all keys from specified section) from INI file.
// param 1 - SectName
// param 2 (optional) - if specified - must be TStringList object,
//       if not specified then
//       stringlist will be created and returned
//
// Examples:
//  local MyLst=xIni:ReadSection("Section1");
//  ....
//  Delete(MyLst); -- List must be deleted after use
// ---------
// or
// local MyLst=NEW.TStringList;
// xIni:ReadSection("Section1",MyLst);
//
//---------------------------------------------------------
function Package_IniFile.ReadSection(Params:TList): Integer;
var
 Sn:String;
 xIni:TIniFile;
 xSectLst:TStringList;
begin
  Result:=0;
  xIni:=TIniFile(TXVariant(Params.Items[0]).Ptr);
  Sn:=String(TXVariant(Params.Items[1]).V);
  if(Params.Count >= 3)then begin
    xSectLst:=TStringList(TXVariant(Params.Items[2]).Ptr);
    xIni.ReadSection(Sn,xSectLst); //-- read into specified list
  end else begin
    xSectLst:=TStringList.Create;
    xIni.ReadSection(Sn,xSectLst); //-- read into specified list
    TXVariant(Params.Items[0]).Ptr:=xSectLst;
  end;

end;

//---------------------------------------------------------
// xIni:ReadSectionValues("SectionName",StringList);
// param 1 - INI file Section Name
// param 2 - must be StringList
//
// Read Section Values into specified TStringList object.
// Strings in resulting StringList have a form of:
// "Key1=Value"
// "Key1=Value"
// ...
//---------------------------------------------------------
function Package_IniFile.ReadSectionValues(Params:TList): Integer;
var
 Sn:String;
 xIni:TIniFile;
 xSectLst:TStringList;
 i:integer;
begin
  Result:=0;
  xIni:=TIniFile(TXVariant(Params.Items[0]).Ptr);
  Sn:=String(TXVariant(Params.Items[1]).V);
  xSectLst:=TStringList(TXVariant(Params.Items[2]).Ptr);
  xIni.ReadSectionValues(Sn,xSectLst);
end;

//--------------------------------------------------------------------
// xIni:ReadSectionValuesOnly("SectionName",StringList);
// param 1 - INI file Section Name
// param 2 - must be StringList
//
// Read Section Values without Keys into specified TStringList object.
// Strings in resulting StringList have a form of:
// "Value1"
// "Value2"
// ...
//--------------------------------------------------------------------
function Package_IniFile.ReadSectionValuesOnly(Params:TList): Integer;
var
 Sn:String;
 xIni:TIniFile;
 xSectLst:TStringList;
 i:integer;
begin
  Result:=0;
  xIni:=TIniFile(TXVariant(Params.Items[0]).Ptr);
  Sn:=String(TXVariant(Params.Items[1]).V);
  xSectLst:=TStringList(TXVariant(Params.Items[2]).Ptr);
  xIni.ReadSectionValues(Sn,xSectLst);
  for i:=0 to xSectLst.Count-1 do begin
     xSectLst.Strings[i]:=xSectLst.Values[xSectLst.Names[i]];
  end;
end;

//---------------------------------------------------------
// xIni:EraseSection("SectionName");
// Erase (delete) specified Section from INI file.
// param 1 - Section Name of INI file.
//---------------------------------------------------------
function Package_IniFile.EraseSection(Params:TList): Integer;
var
 Sn:String;
 xIni:TIniFile;
 xSectLst:TStringList;
begin
  Result:=0;
  xIni:=TIniFile(TXVariant(Params.Items[0]).Ptr);
  Sn:=String(TXVariant(Params.Items[1]).V);
  xIni.EraseSection(Sn);
end;

//---------------------------------------------------------
// StringValue=xIni:ReadString("SectName","KeyName","DefaultValue");
// Read String value from Ini file.
// param 1 - Section Name if INI file.
// param 2 - KeyName
// param 3 - Default Value (returned if there are no such section/key in INI file).
//
// Example:
// MyStrValue=xIni:ReadString("Section1","Key1","");
// if(MyStrValue == "")then
//   -- do something
// end;
//---------------------------------------------------------
function Package_IniFile.ReadString(Params:TList): Integer;
var
 Sn:String;
 Kn:String;
 DefVal:String;
 xIni:TIniFile;
 xSectLst:TStringList;
begin
  Result:=0;
  xIni:=TIniFile(TXVariant(Params.Items[0]).Ptr);
  Sn:=String(TXVariant(Params.Items[1]).V);
  Kn:=String(TXVariant(Params.Items[2]).V);
  DefVal:=String(TXVariant(Params.Items[3]).V);
  DefVal:=xIni.ReadString(Sn,Kn,DefVal);
  TXVariant(Params.Items[0]).V:=DefVal;
end;

//---------------------------------------------------------
// xIni:WriteString("SectionName","KeyName","New String Value");
// Write String value to Ini file.
//
// param 1 - Section Name
// param 2 - KeyName
// param 3 - String Value saved in INI file.
//---------------------------------------------------------
function Package_IniFile.WriteString(Params:TList): Integer;
var
 Sn:String;
 Kn:String;
 Val:String;
 xIni:TIniFile;
 xSectLst:TStringList;
begin
  Result:=0;
  xIni:=TIniFile(TXVariant(Params.Items[0]).Ptr);
  Sn:=String(TXVariant(Params.Items[1]).V);
  Kn:=String(TXVariant(Params.Items[2]).V);
  Val:=String(TXVariant(Params.Items[3]).V);
  xIni.WriteString(Sn,Kn,Val);
end;

//=======================================================================
initialization
//--- Create string package -----
PACK_INIFILE:=Package_IniFile.Create;
PACK_INIFILE.RegisterFunctions;

//--- Register this package -----
LuaInter.RegisterGlobalVar('TIniFile',PACK_INIFILE);

end.
