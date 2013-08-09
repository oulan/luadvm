//=================================================================================================
// This module contains definitions of some packages,which can be used
// by TByteCodeProto class (Lua_DVM) during ByteCode execution.
// All below functions/packages are registered as globals in Initialization section.
//
// The following packages are implemented here:
// Package_IO             - Package of some generic functions. Also the following functions from this package
//                          are intended to be registered as separate Global Functions.
//                          function DeleteObject(Params:TList):integer;
//                          function Assign(Params:TList):integer;
// ClassTStringsPackage   - Class package for define functions of TStringList class
// ClassTListPackage      - Class package for define functions of TList class
// ClassTObjectPackage    - Define few base properties (ClassName) and methods of any object
// ClassTComponentPackage - Define few base properties and methods of TComponent
//                          And Event Wrappers (for being able to call LuaFunction as Event Handler e.g. OnClick)
// ClassTWinControlPackage- Define few base properties and methods of TWinControl
//
// TableFuncPackage       - Functions for support Lua Tables
//
// Global instances of these packages are created in "initialization" section
// NOTE:
//  All Global Vars Names,Function Names,Packages names,Properties Names are CASE SENSITIVE!
//=================================================================================================
unit LuaPackages;

interface
 uses Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls,LuaInter,TypInfo,EventProxy,LC_Procs,FileCtrl,Variants;

  procedure ResetLuaEventsOfComponent(xCompo:TComponent;CollectEventProxyLst:TList);

 //--------------------------------------------------------------------
 // Function Package object for collect some general purpose functions
 //--------------------------------------------------------------------
 type Package_IO=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function MessageBox1(Params:TList):integer;
    function MessageBox2(Params:TList):integer;
    function ExecCommand(Params:TList):integer;
    function xSetCurrentDir(Params:TList):integer;
    function xGetCurrentDir(Params:TList):integer;
    function xGetApplicationDir(Params:TList):integer;
    function xSleep(Params:TList):integer;
    function GetUniqueStr(Params:TList):integer;
    function xOutputDebugString(Params:TList):integer;
    function xFileExists(Params:TList):integer;
    function xDirectoryExists(Params:TList):integer;
    function xCreateDir(Params:TList):integer;

  public
    procedure RegisterFunctions;override;

    //--- Additional functins ----------------
    function DeleteObject(Params:TList):integer;   //-- Delete(xxxx) function
    function Assign(Params:TList):integer;
    function IsObject(Params:TList):integer;
    function LoadLuaBinary(Params:TList):integer;
    function tostring(Params:TList):integer;
    function tonumber(Params:TList):integer;
    function toOle(Params:TList):integer;
 end;


 //--------------------------------------------------------------------
 // Class TByteCodeProto Package.
 // Functions called from lua by MODULE build in var. For example:
 // MODULE:SaveGlobals();
 //--------------------------------------------------------------------
 type Package_TByteCodeProto=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function SaveGlobals(Params:TList):integer;
    function SaveGlobal(Params:TList):integer;
    function DeleteGlobal(Params:TList):integer;
    function HandleProperties(Params:TList):integer; //--- all props of module treated as Globals
    function FindByName(Params:TList):integer;
  public
    procedure RegisterFunctions;override;
 end;


 //--------------------------------------------------------------------
 // Class Package object for expose TStringList functions
 //--------------------------------------------------------------------
 type ClassTStringsPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function Add(Params:TList):integer;
    function Insert(Params:TList):integer;
    function Delete(Params:TList):integer;
    function Clear(Params:TList):integer;
    function GetObject(Params:TList):integer;
    function SetObject(Params:TList):integer;
    function Find(Params:TList):integer;
    function GetValue(Params:TList):integer;
    function SetValue(Params:TList):integer;

    function HandleProperties(Params:TList):integer;
  public
    procedure RegisterFunctions;override;
 end;

 //--------------------------------------------------------------------
 // Class Package object for expose TList functions
 //--------------------------------------------------------------------
 type ClassTListPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function Add(Params:TList):integer;
    function Insert(Params:TList):integer;
    function Delete(Params:TList):integer;

    function AddNumber(Params:TList):integer;
    function GetNumber(Params:TList):integer;
    function InsertNumber(Params:TList):integer;

  public
    procedure RegisterFunctions;override;
 end;

 //--------------------------------------------------------------------
 // Class Package object for expose TObject functions
 //--------------------------------------------------------------------
 type ClassTObjectPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function ClassName(Params:TList):integer;
    function InheritedFrom(Params:TList):integer;
    function LoadFromFile(Params:TList):integer;
    function SaveToFile(Params:TList):integer;
    function ProcessMessages(Params:TList):integer;

    //--- Functions in Package ---------
    function HandleProperties(Params:TList):integer;
  public
    procedure RegisterFunctions;override;
 end;

 //--------------------------------------------------------------------
 // Class Package object for expose TWinControl properties/functions
 //--------------------------------------------------------------------
 type ClassTWinControlPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function HandleProperties(Params:TList):integer;
    function FindComponentByName(Params:TList):integer;
  public
    procedure RegisterFunctions;override;
 end;


  //--------------------------------------------------------------------
 // Class Package object for TForm extra properties/functions
 //--------------------------------------------------------------------
 type ClassTFormPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function HandleProperties(Params:TList):integer;
  public
    procedure RegisterFunctions;override;
 end;

  //--------------------------------------------------------------------
 // Class Package object for expose TComponent properties/functions
 //--------------------------------------------------------------------
 type ClassTComponentPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function HandleProperties(Params:TList):integer;
    function ShowModal(Params:TList):integer;
    function Show(Params:TList):integer;
    function Close(Params:TList):integer;
    function FindComponent(Params:TList):integer;

  public
    procedure RegisterFunctions;override;

 end;

  //--------------------------------------------------------------------
 // Functions Package object for tables (TLuaTable)
 //--------------------------------------------------------------------
 type TableFuncPackage=class(TLuaPackage)
  private
    function HandleProperties(Params:TList):integer;
    function GetTableFromParams(Params:TList):TLuaTable; //--- check params return TLuaTable
    function GetTableLength(Params:TList):integer;      //-- Works with IndexList part of table
    function Insert(Params:TList):integer;              //-- add or insert element (can be other table)
    function Delete(Params:TList):integer;              //-- delete element by index
    function GetSTableLength(Params:TList):integer;     //-- Works with DictList part of table
    function GetTList(Params:TList):integer;            //-- return TList part of Table
    function GetTStringList(Params:TList):integer;      //-- return TStringLsit part of Table
    function Copy(Params:TList):integer;                //-- create a copy of LuaTable

    //function CreateArray(Params:TList):integer;         //--- Create multi dimension array
    //function AddTableTo(Indexes:TList;RecursLevel:integer):TLuaTable; //-- internal for CreateArray(...)

  public
    procedure RegisterFunctions;override;
 end;


//--------------------------------------------------------------------------
// Global Instances of above Packages created in Initialization section
//--------------------------------------------------------------------------
var
  //-- Package Instances ----
  PACK_IO:Package_IO;
  PackageTable:TableFuncPackage;

  PackageClassTByteCodeProto:Package_TByteCodeProto;
  PackageClassTStrings:ClassTStringsPackage;
  PackageClassTList:ClassTListPackage;
  PackageClassTObject:ClassTObjectPackage;
  PackageClassTComponent:ClassTComponentPackage;
  PackageClassTWinControl:ClassTWinControlPackage;
  PackageClassTForm:ClassTFormPackage;

  VarTypesLst:TStringList; //--- list of variant types strings/consts used in toOle(...) function
implementation

//-------------------------------------------------------------------------------------------------------
// Helper procedure for reset all Event-like props which was set for Specified Component.
// Note:
// Component's events properties can be set via EventProxy components which are Owned by
// Component. So if we create component from lua,set it's Onxxxx properties and then Destroy
// Component  -all it's EventProxies will be deleted automatically. But if don't Destroy
// component - we must clear all it's LuaEvent handlers manually.
//-------------------------------------------------------------------------------------------------------
procedure ResetLuaEventsOfComponent(xCompo:TComponent;CollectEventProxyLst:TList);
var
  xEventProxy:TLuaEventProxy;
  PropInfo:PPropInfo;
  xMethod:TMethod;
  i:integer;
begin
        //---Create Emtpy value of Onxx Properties ----
        xMethod.Code:=Nil;
        xMethod.Data:=Nil;

        for i:=0 to xCompo.ComponentCount-1 do begin
           if(xCompo.Components[i] is TLuaEventProxy)then begin
               xEventProxy:=TLuaEventProxy(xCompo.Components[i]);
               //-- Set Onxxx property of object to Nil ----------
               PropInfo:=TypInfo.GetPropInfo(xCompo.ClassType,xEventProxy.EventPropName);
               TypInfo.SetMethodProp(xCompo,PropInfo,xMethod);
               //--- Collect EventProxy components ---------
               CollectEventProxyLst.Add(xEventProxy);
           end;
        end;
end;






//---------------------------------------------------------
// Add all functions to internal list
//---------------------------------------------------------
procedure Package_IO.RegisterFunctions;
begin
  Methods.AddObject('MessageBox',TUserFuncObject.CreateWithName('MessageBox',MessageBox1));
  Methods.AddObject('MessageBox1',TUserFuncObject.CreateWithName('MessageBox1',MessageBox1));
  Methods.AddObject('MessageBoxYesNo',TUserFuncObject.CreateWithName('MessageBoxYesNo',MessageBox2));
  Methods.AddObject('LoadLuaBinary',TUserFuncObject.CreateWithName('LoadLuaBinary',LoadLuaBinary));
  Methods.AddObject('SetCurrentDir',TUserFuncObject.CreateWithName('SetCurrentDir',xSetCurrentDir));
  Methods.AddObject('GetCurrentDir',TUserFuncObject.CreateWithName('GetCurrentDir',xGetCurrentDir));
  Methods.AddObject('GetApplicationDir',TUserFuncObject.CreateWithName('GetApplicationDir',xGetApplicationDir));
  Methods.AddObject('ExecCmd',TUserFuncObject.CreateWithName('ExecCmd',ExecCommand));
  Methods.AddObject('Sleep',TUserFuncObject.CreateWithName('Sleep',xSleep));
  Methods.AddObject('GetUniqueStr',TUserFuncObject.CreateWithName('GetUniqueStr',GetUniqueStr));
  Methods.AddObject('OutputDebugString',TUserFuncObject.CreateWithName('OutputDebugString',xOutputDebugString));
  Methods.AddObject('FileExists',TUserFuncObject.CreateWithName('FileExists',xFileExists));
  Methods.AddObject('DirectoryExists',TUserFuncObject.CreateWithName('DirectoryExists',xDirectoryExists));
  Methods.AddObject('CreateDir',TUserFuncObject.CreateWithName('CreateDir',xCreateDir));

  //--- Duplicate functions registration. These functions also registered as globals so now we can call
  //--- then both ways  "sys.Delete(xxxx)"  or simply "Delete(xxxx)"
  Methods.AddObject('DeleteObject',TUserFuncObject.CreateWithName('Delete',DeleteObject));
  Methods.AddObject('Assign',TUserFuncObject.CreateWithName('Assign',Assign));
  Methods.AddObject('IsObject',TUserFuncObject.CreateWithName('IsObject',IsObject));
  Methods.AddObject('tostring',TUserFuncObject.CreateWithName('tostring',tostring));
  Methods.AddObject('tonumber',TUserFuncObject.CreateWithName('tonumber',tonumber));
  Methods.AddObject('toOle',TUserFuncObject.CreateWithName('toOle',toOle));
end;

//---------------------------------------------------------
// MessageBox("Message")
// MessageBox("Message","Box Caption")
// Show Standard Windows MessageBox with or without caption.
//---------------------------------------------------------
function Package_IO.MessageBox1(Params:TList):integer;
var
  SHeader:Pchar;
  MbRes:Lua_Number;
  MbAttr:integer;
begin
    Result:=0;
    SHeader:='Message';
    MbAttr:=MB_ICONINFORMATION;

    if(Params.Count >= 2)then begin
      SHeader:=Pchar(String(TXVariant(Params.Items[1]).V));
    end;
    if(Params.Count >= 3)then begin
      MbAttr:=TXVariant(Params.Items[2]).V;
    end;

    MbRes:=MessageBox(HWND(Nil),Pchar(String(TXVariant(Params.Items[0]).V)),Sheader,MbAttr);
    TXVariant(Params.Items[0]).V:=MbRes; //-- return result
end;

//---------------------------------------------------------
// MessageBoxYesNo("Message","Box Caption")
// Show MessageBox with Yes No buttons.
// Return value - windows equivalent of ID_YES ID_NO
//---------------------------------------------------------
function Package_IO.MessageBox2(Params:TList):integer;
var
 MbRes:Lua_Number;
begin
    Result:=0;
    MbRes:=MessageBox(HWND(Nil),Pchar(String(TXVariant(Params.Items[0]).V)),
                               Pchar(String(TXVariant(Params.Items[1]).V)),MB_YESNO or MB_ICONINFORMATION);

    TXVariant(Params.Items[0]).V:=MbRes;
end;

//--------------------------------------------------------
// DeleteObject(X)
// Deletes Object X previously was created by
// X=NEW.ObjType;
//--------------------------------------------------------
function Package_IO.DeleteObject(Params:TList):integer;
var
 xObj:TObject;
 pV:TXVariant;
begin
    Result:=0;
    pV:=TXVariant(Params.Items[0]);
    xObj:=TObject(pV.Ptr);
    xObj.Destroy;
    pV.Clear;
end;

//--------------------------------------------------------
// IsObject(X)
// Check does X variable is refference to object
//--------------------------------------------------------
function Package_IO.IsObject(Params:TList):integer;
var
 pV:TXVariant;
begin
    Result:=0;
    pV:=TXVariant(Params.Items[0]);
    if((pV.IsObject) and (pV.Ptr <> NullPtrObject))then begin
       pV.V:=1;
    end else begin
       pV.V:=0;
    end;
end;


//--------------------------------------------------------
// sys.Assign(ObjFrom,ObjTo);
// Assign value of ObjFrom to object ObjTo.
//--------------------------------------------------------
function Package_IO.Assign(Params:TList):integer;
var
 xObjFrom,xObjTo:TObject;
 pV:TXVariant;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  xObjFrom:=TObject(pV.Ptr);
  pV:=TXVariant(Params.Items[1]);
  xObjTo:=TObject(pV.Ptr);
  if((xObjFrom is TPersistent) and (xObjTo is TPersistent))then begin
     TPersistent(xObjTo).Assign(TPersistent(xObjFrom));
  end;
end;

//------------------------------------------------------------------
// Load lua binary code and return newly created TByteCodeProto object.
// Example of usage:
//   local MyFunc=LoadBinary("Mymodule.out");
//   MyFunc(); -- call loaded function
//------------------------------------------------------------------
function Package_IO.LoadLuaBinary(Params:TList):integer;
var
 NewLuaFunction:TByteCodeProto;
 Fn:String;
begin
  Result:=0;
  Fn:=String(TXVariant(Params.Items[0]).V);
  if(NOT FileExists(Fn))then begin
     TXVariant(Params.Items[0]).Ptr:=NullPtrObject; //-- global var defined in LuaInter module
     Exit;
  end;

  NewLuaFunction:=TByteCodeProto.Create(Nil);
  NewLuaFunction.LoadBinary(Fn);
  TXVariant(Params.Items[0]).Ptr:=NewLuaFunction;
end;


//-------------------------------------------------
// N=tostring(N);
// Convert number to string.
// Assumed that N contains numeric value before function call.
//-------------------------------------------------
function Package_IO.tostring(Params:TList):integer;
var
  pV:TXVariant;
  ptrval:integer;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);

  if(pV.isObject)then begin
     ptrval:=integer(pV.Ptr);
     pV.V:='0x'+IntToHex(ptrval,8);
  end else if(pV.VarType = varDouble)then begin
     pV.V:=String(pV.V);
  end;
end;


//-----------------------------------------------------------
// Perform some explicit convertions for OLE calls
// Param 1)Variant value to be converted to specifyed type.
//         All types specified in VarTypesLst - String List
// Param 2)is string representing type
//-----------------------------------------------------------
function Package_IO.toOle(Params:TList):integer;
var
  pV:TXVariant;
  S:String;
  Idx:integer;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  S:=TXVariant(Params.Items[1]).V;
  if(VarTypesLst.Find(S,Idx))then begin
     pV.V:=VarAsType(pV.V,Integer(VarTypesLst.Objects[Idx]));
  end else begin
    raise Exception.Create('Unknown variant type specified.');
  end;
end;

//-------------------------------------------------
// S=tonumber(S);
// Convert String to number if possible
// Assumed that S contains string value before function call.
//-------------------------------------------------
function Package_IO.tonumber(Params:TList):integer;
var
  pV:TXVariant;
  r:Real;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);

  if(pV.VarType = varString)then begin
     r:=pV.V;
     pV.V:=r;
  end;
end;

//-------------------------------------------------
// Do WinExec with String as command
// sys.ExecCmd("Copy f1 f2")   -- exec command with SW_SHOWNORMAL window
// sys.ExecCmd("Copy f1 f2",0) -- exec command with Hide window
//-------------------------------------------------
function Package_IO.ExecCommand(Params:TList):integer;
var
  pV:TXVariant;
  r:Lua_Number;
  CmdStr:String;
  HideCmd:integer;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  r:=-1;

  HideCmd:=SW_SHOWNORMAL;
  if((Params.Count = 2) and (TXVariant(Params.Items[1]).VarType = varDouble) )then begin
      HideCmd:=TXVariant(Params.Items[1]).V;
  end;

  if(pV.VarType = varString)then begin
     CmdStr:='CMD /C "'+ String(pV.V)+'"';
     r:=WinExec(PChar(CmdStr),HideCmd);
     if(r < 31)then begin
        r:=-1; //-- indicate an error
     end;
  end;
  pV.V:=r; //--- return execution result back
end;

//-------------------------------------------------
// SetCurrentDir("DirectoryName");
// Set current working dirictory
//-------------------------------------------------
function Package_IO.xSetCurrentDir(Params:TList):integer;
var
  pV:TXVariant;
  r:boolean;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  r:=false;
  if(pV.VarType = varString)then begin
     r:=SetCurrentDir(String(pV.V)); //-- or ChDir
     //r:=SetWorkingDir(PChar(String(pV.V))); //-- or ChDir
  end;
  pV.V:=r; //--- return execution result back
end;

//-------------------------------------------------
// CurrentDir=GetCurrentDir();
// Return current working directory name string.
//-------------------------------------------------
function Package_IO.xGetCurrentDir(Params:TList):integer;
var
  pV:TXVariant;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  pV.V:=GetCurrentDir;
end;

//-------------------------------------------------
// ApplicationDir=GetApplicationDir();
// Return directory from where application was started.
// Usually needs for define location of INI files.
//-------------------------------------------------
function Package_IO.xGetApplicationDir(Params:TList):integer;
var
  pV:TXVariant;
  S:String;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  S:=ExtractFilePath(Application.ExeName);
  pV.V:=S;
end;


//-------------------------------------------------
// Sleep(mSec);
// Sleep for specified number of milliseconds
//-------------------------------------------------
function Package_IO.xSleep(Params:TList):integer;
var
  pV:TXVariant;
  i:integer;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  if(pV.VarType = varDouble)then begin
     i:=pV.V;
     Sleep(i);
  end;
end;

//-------------------------------------------------
// MyUniqueString=GetUniqueStr()
// Return long numeric like string based on current time.
//-------------------------------------------------
function Package_IO.GetUniqueStr(Params:TList):integer;
var
  pV:TXVariant;
  i64:int64;
  FID:FILETIME;
  S:String;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  GetSystemTimeAsFileTime(FID);
  i64:=int64(FID);
  S:=IntToStr(i64);
  pV.V:=S; //-- return string back
end;

//-------------------------------------------------
// OutputDebugString("Mystring");
// Send Debug string to Windows from Lua code.
// For view these strings you must have some special
// utilits like "DbgWin".
//-------------------------------------------------
function Package_IO.xOutputDebugString(Params:TList):integer;
var
  S:String;
  pV:TXVariant;
begin
  pV:=TXVariant(Params.Items[0]);
  S:=String(pV.V);
  Windows.OutputDebugString(PChar(S));
  Result:=0;
end;

//-------------------------------------------------
// FileExists("FullFileName");
// Check if specified File Exits.
// Return: true or false.
//-------------------------------------------------
function Package_IO.xFileExists(Params:TList):integer;
var
  S:String;
  pV:TXVariant;
  Res:Boolean;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  S:=String(pV.V);
  Res:=FileExists(S);
  TXVariant(Params.Items[0]).V:=Res;
end;

//-------------------------------------------------
// DirectoryExists("FullDirName");
// Check if specified directory Exits.
// Return: true or false.
//-------------------------------------------------
function Package_IO.xDirectoryExists(Params:TList):integer;
var
  S:String;
  pV:TXVariant;
  Res:Boolean;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  S:=String(pV.V);
  Res:=DirectoryExists(S);
  TXVariant(Params.Items[0]).V:=Res;
end;

//-------------------------------------------------
// CreateDir("DirName");
// Create Directory with specified name.
//-------------------------------------------------
function Package_IO.xCreateDir(Params:TList):integer;
var
  S:String;
  pV:TXVariant;
  Res:Boolean;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);
  S:=String(pV.V);
  Res:=CreateDir(S);
  TXVariant(Params.Items[0]).V:=Res;
end;


//---------------------------------------------------------
// Add ClassTStringsPackage functions to internal list
//---------------------------------------------------------
procedure ClassTStringsPackage.RegisterFunctions;
begin
  Methods.AddObject('Add',TUserFuncObject.CreateWithName('Add',Add));
  Methods.AddObject('Insert',TUserFuncObject.CreateWithName('Insert',Insert));
  Methods.AddObject('Delete',TUserFuncObject.CreateWithName('Delete',Delete));
  Methods.AddObject('Clear',TUserFuncObject.CreateWithName('Clear',Clear));
  Methods.AddObject('GetObject',TUserFuncObject.CreateWithName('GetObject',GetObject));
  Methods.AddObject('SetObject',TUserFuncObject.CreateWithName('SetObject',SetObject));
  Methods.AddObject('Find',TUserFuncObject.CreateWithName('Find',Find));
  Methods.AddObject('GetValue',TUserFuncObject.CreateWithName('GetValue',GetValue));
  Methods.AddObject('SetValue',TUserFuncObject.CreateWithName('SetValue',SetValue));

  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));

  HandledProps:=TStringList.Create;
  HandledProps.Add('Count');
  HandledProps.Add('Sorted');
  HandledProps.Add('Strings');

end;

//------------------------------------------------------
// TStrings/TStringList properties:
// TStringList.Sorted=true
//------------------------------------------------------
function  ClassTStringsPackage.HandleProperties(Params:TList):integer;
var
  xLst:TObject;
  Cmd,PropName:String;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    xLst:=TStrings(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;         //-- Property name

    //----- "Sorted" property -------------------------
    if((xLst is TStringList) and (PropName = 'Sorted'))then begin
        if(Cmd = 'G')then begin
          TXVariant(Params.Items[3]).V:=TStringList(xLst).Sorted;
          Result:=1;
        end else begin
          TStringList(xLst).Sorted:=TXVariant(Params.Items[3]).V;
          Result:=1;
        end;
    end;
end;


//---------------------------------------------------------
// Note:
// Items[0] contains pointer to Variant which VPointer part
// is TStrings object.
//---------------------------------------------------------
// StringList:Add("NewString");
// Add String to StringList previously creted as:
// StringList=NEW.TStringList;
// Note: All objects created with NEW must be
// deleted with Delete(...) function.
// Also you can use
// StringList:Add(xLst) as Delphi StringList.AddStrings(xLst) method.
//---------------------------------------------------------
function ClassTStringsPackage.Add(Params:TList):integer;
var
  xLst:TStrings;
  S:String;
  pV:TXVariant;
  xObj:TObject;
begin
    Result:=0;
    pV:=TXVariant(Params.Items[0]);
    if(NOT pV.IsObject)then begin
       Result:=-1;
       Exit;
    end;

    xObj:=TObject(pV.Ptr);
    xLst:=TStrings(xObj);

    if(Params.Count = 2)then begin
      //--- Implement AddStrings as Add(xList) -------
      if(TXVariant(Params.Items[1]).isObject)then begin
         if(TObject(TXVariant(Params.Items[1]).Ptr) is TStrings)then begin
           xLst.AddStrings(TStrings(TXVariant(Params.Items[1]).Ptr)); //-- $VS2JUN2005
         end;
      end else begin
        S:=String(TXVariant(Params.Items[1]).V);
        xLst.Add(S);
      end;
    end else if(Params.Count = 3)then begin
      S:=String(TXVariant(Params.Items[1]).V);
      pV:=TXVariant(Params.Items[2]);
      xLst.AddObject(S,pV);
    end;
end;

//---------------------------------------------------------
// StringList:Insert(Index,"NewString");
// Insert String into StringList
// Before string with specified Index.
// (Indexes goes from 0).
// For example: StringList.Insert(0,"NewString");
// will insert "NewString" at the head of list.
// Note: All objects created with NEW must be
// deleted with Delete(...) function.
//---------------------------------------------------------
function ClassTStringsPackage.Insert(Params:TList):integer;
var
  xLst:TStrings;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    xLst.Insert(integer(TXVariant(Params.Items[1]).V),String(TXVariant(Params.Items[2]).V));
end;

//---------------------------------------------------------
// StringList:Delete(Index);
// Delete String from StringList by specified Index.
// (Indexes goes from 0).
// For example: StringList.Delete(0);
// will delete first string from list.
//---------------------------------------------------------
function ClassTStringsPackage.Delete(Params:TList):integer;
var
  xLst:TStrings;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    xLst.Delete(integer(TXVariant(Params.Items[1]).V));
end;

//---------------------------------------------------------
// StringList:Clear();
// Delete all Strings from StringList.
//---------------------------------------------------------
function ClassTStringsPackage.Clear(Params:TList):integer;
var
  xLst:TStrings;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    xLst.Clear();
end;

//----------------------------------------------------------------
// GetObject(StringLst,Index); or
// StringList:GetObject(Index);
// Return object associated with String with specified index.
// This object must be previously attached to Stringlist with
// SetObject(Obj,Index) function call.
//----------------------------------------------------------------
function ClassTStringsPackage.GetObject(Params:TList):integer;
var
  xLst:TStrings;
  idx:integer;
  pV:TXVariant;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    idx:=integer(TXVariant(Params.Items[1]).V);
    if(xLst.Objects[idx] = Nil)then begin
       pV:=NullPtrObject;
    end else begin
       pV:=TXVariant(xLst.Objects[idx]); //--- assumed that TStirng list has Variants as attached objects
    end;
    TXVariant(Params.Items[0]).Assign(pV);
end;

//----------------------------------------------------------------
// SetObject(StringList,Index,Object); or
// StringList:SetObject(Index,Object);
// Associate Object with String from StringList having specified index.
//----------------------------------------------------------------
function ClassTStringsPackage.SetObject(Params:TList):integer;
var
  xLst:TStrings;
  idx:integer;
  pV:TXVariant;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    idx:=integer(TXVariant(Params.Items[1]).V);
    pV:=TXVariant(Params.Items[2]);
    xLst.Objects[idx]:=pV; //--- assumed that TStirng list has Variants as attached objects
end;

//----------------------------------------------------------------
// Find(StringList,StringToFind); or
// StringList:Find(StringToFind);
// Find specified string in StringList.
// return Index in Lst or -1
//----------------------------------------------------------------
function ClassTStringsPackage.Find(Params:TList):integer;
var
  xLst:TStrings;
  idx:integer;
  pV:TXVariant;
  S:String;
  r:Lua_Number;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    S:=TXVariant(Params.Items[1]).V;

    if(xLst is TStringList)then begin
       idx:=TStringList(xLst).IndexOf(S); //-- if sorted then IndexOf use Find - quick search
    end else begin
       idx:=xLst.IndexOf(S);
    end;
    //-- return result back -------
    pV:=TXVariant(Params.Items[0]);
    r:=idx; //-- convert result to Real
    pV.V:=r;
end;

//----------------------------------------------------------------
// StringList:GetValue("SomeKeyword");
//
// If StringList contains Strings in Key/Value form (as used in INI files),
// eg."Key=Value" -
// Function returns "Value" of specified "Key".
// It is analogue of Delphi Values property of StringList
// Eg. xxStringList.Values["MyValue"]
// return (SSSSS) if there is string "MyValue=SSSSS"
// in StringList.
//----------------------------------------------------------------
function ClassTStringsPackage.GetValue(Params:TList):integer;
var
  xLst:TStrings;
  S:String;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    S:=TXVariant(Params.Items[1]).V;
    S:=xLst.Values[S];
    TXVariant(Params.Items[0]).V:=S;
end;

//----------------------------------------------------------------
// StringList:SetValue("SomeKeyword","NewValue");
//
// If StringList contains Strings in Key/Value form (as used in INI files),
// eg."Key=Value" -
// Function set new "Value" for specified "Key".
// It is Analogue of Delphi Values property of StringList
// Eg. in Delphi: xxStringList.Values["MyValue"]="NEWVALUESTRING"
//----------------------------------------------------------------
function ClassTStringsPackage.SetValue(Params:TList):integer;
var
  xLst:TStrings;
  S1:String;
  Key:String;
begin
    Result:=0;
    xLst:=TStrings(TXVariant(Params.Items[0]).Ptr);
    Key:=TXVariant(Params.Items[1]).V;
    S1:=TXVariant(Params.Items[2]).V;
    xLst.Values[Key]:=S1;
    TXVariant(Params.Items[0]).V:=S1;
end;

//=========================================================
// Add ClassTListPackage functions to internal list
//---------------------------------------------------------
// Class TList Support.
// TList is placeholder for Objects or Numbers.
// Must be created as
// Lst1=NEW.TList
// After use - must be deleted with Delete(Lst1);
//---------------------------------------------------------
procedure ClassTListPackage.RegisterFunctions;
begin
  Methods.AddObject('Add',TUserFuncObject.CreateWithName('Add',Add));
  Methods.AddObject('Insert',TUserFuncObject.CreateWithName('Insert',Insert));
  Methods.AddObject('Delete',TUserFuncObject.CreateWithName('Delete',Delete));
  Methods.AddObject('AddNumber',TUserFuncObject.CreateWithName('AddNumber',AddNumber));
  Methods.AddObject('GetNumber',TUserFuncObject.CreateWithName('GetNumber',GetNumber));
  Methods.AddObject('InsertNumber',TUserFuncObject.CreateWithName('InsertNumber',InsertNumber));

  HandledProps:=TStringList.Create;
  HandledProps.Add('Count');
  HandledProps.Add('Items');

end;

//---------------------------------------------------------
// Note:
// Items[0] contains pointer to Variant which VPointer part
// is TList object.
//---------------------------------------------------------
// Lst:Add(myObject);
// Add object refference to List.
// Objects can be created with "NEW" or can be
// Lua Functions or Lua Tables.
//---------------------------------------------------------
function ClassTListPackage.Add(Params:TList):integer;
var
  xLst:TList;
  pV:TXVariant;
  xObj:TObject;
begin
    Result:=0;
    pV:=TXVariant(Params.Items[0]);
    if(NOT pV.IsObject)then begin
       Result:=-1;
       Exit;
    end;

    xObj:=TObject(pV.Ptr);
    xLst:=TList(xObj);

    xObj:=TObject(TXVariant(Params.Items[1]).Ptr);
    xLst.Add(xObj);
end;


//---------------------------------------------------------
// Lst:AddNumber(X);
// Add Numeric value to TList
// Note:
//  NOrmally TLsit assume that we add Objects into it...
//  But if we need save numbers - this can be used.
//  Assumed that X has no fractal part (is integer).
//---------------------------------------------------------
function ClassTListPackage.AddNumber(Params:TList):integer;
var
  xLst:TList;
  pV:TXVariant;
  xObj:TObject;
  IntValue:integer;
begin
    Result:=0;
    pV:=TXVariant(Params.Items[0]);
    if(NOT pV.IsObject)then begin
       Result:=-1;
       Exit;
    end;

    xObj:=TObject(pV.Ptr);
    xLst:=TList(xObj);

    if( (TXVariant(Params.Items[1]).IsObject) or (TXVariant(Params.Items[1]).VarType <> varDouble) )then begin
       raise Exception.Create('List:AddNumber - argument not a number!');
    end;

    IntValue:=TXVariant(Params.Items[1]).V;
    xLst.Add(TObject(IntValue));
end;

//---------------------------------------------------------
// Numb=Lst:GetNumber(i);
// Return Numeric value from TList by specified index (i);
// Note:
//  NOrmally TLsit assume that we add Objects into it...
//  local i=MyLst:GetNumber(Idx);
//---------------------------------------------------------
function ClassTListPackage.GetNumber(Params:TList):integer;
var
  xLst:TList;
  pV:TXVariant;
  xObj:TObject;
  Idx:integer;
  IntValue:integer;
  r:Lua_Number;
begin
    Result:=0;
    pV:=TXVariant(Params.Items[0]);
    if(NOT pV.IsObject)then begin
       Result:=-1;
       Exit;
    end;

    xObj:=TObject(pV.Ptr);
    xLst:=TList(xObj);

    Idx:=TXVariant(Params.Items[1]).V; //-- must be a number

    IntValue:=integer(xLst.Items[Idx]);
    r:=IntValue;
    TXVariant(Params.Items[0]).V:=r;
end;

//---------------------------------------------------------
// MyLst:InsertNumber(Idx,Value);
// Insert Numeric to TList
// Note:
//  NOrmally TLsit assume that we add Objects into it.
//---------------------------------------------------------
function ClassTListPackage.InsertNumber(Params:TList):integer;
var
  xLst:TList;
  pV:TXVariant;
  xObj:TObject;
  IntValue:integer;
  Idx:integer;
begin
    Result:=0;
    pV:=TXVariant(Params.Items[0]);
    if(NOT pV.IsObject)then begin
       Result:=-1;
       Exit;
    end;

    xObj:=TObject(pV.Ptr);
    xLst:=TList(xObj);

    if( (TXVariant(Params.Items[2]).IsObject) or (TXVariant(Params.Items[1]).VarType <> varDouble) or (TXVariant(Params.Items[2]).VarType <> varDouble) )then begin
       raise Exception.Create('List:InsertNumber - argument not a number!');
    end;

    Idx:=TXVariant(Params.Items[1]).V;
    IntValue:=TXVariant(Params.Items[2]).V;
    xLst.Insert(idx,TObject(IntValue));
end;


//---------------------------------------------------------
// MyLst:Insert(Idx,ObjReff);
// Insert Object refference to specified location of
// TList (before element with index Idx).
//---------------------------------------------------------
function ClassTListPackage.Insert(Params:TList):integer;
var
  xLst:TList;
begin
    Result:=0;
    xLst:=TList(TXVariant(Params.Items[0]).Ptr);
    xLst.Insert(integer(TXVariant(Params.Items[1]).V),(TXVariant(Params.Items[2]).Ptr));
end;

//---------------------------------------------------------
// MyLst:Delete(Idx);
// Delete Object refference from specified location of
// TList (element with index Idx).
//---------------------------------------------------------
function ClassTListPackage.Delete(Params:TList):integer;
var
  xLst:TList;
begin
    Result:=0;
    xLst:=TList(TXVariant(Params.Items[0]).Ptr);
    xLst.Delete(integer(TXVariant(Params.Items[1]).V));
end;


//------------------------------------------------------------------
// TObject class package
// "TObject" is the base class for all other classes.
// It has some specific properties as "ClassName","ClassParent"
// general to all objects.
// For Example:
//  ItsClassName=MyObj.ClassName -- If MyObj is Button for example
//  ItsClassName == "TButton".
//
//  Having "ClassName" we can emumerate for example all Buttons
//  which belongs to some form.
// Also for some types of TObject functions
// "LoadFromFile" and "SaveToFile" implemented here.
// For example: for load text file to TStringList we can
//  xLst=NEW.TStringList                  -- Create stringlist.
//  xLst:LoadFromFile("MyTextFile.txt")   -- Load text file to StringList
//------------------------------------------------------------------
procedure ClassTObjectPackage.RegisterFunctions;
begin
  Methods.AddObject('ClassName',TUserFuncObject.CreateWithName('ClassName',ClassName));
  Methods.AddObject('InheritedFrom',TUserFuncObject.CreateWithName('InheritedFrom',InheritedFrom));
  Methods.AddObject('LoadFromFile',TUserFuncObject.CreateWithName('LoadFromFile',LoadFromFile));
  Methods.AddObject('SaveToFile',TUserFuncObject.CreateWithName('SaveToFile',SaveToFile));
  Methods.AddObject('ProcessMessages',TUserFuncObject.CreateWithName('ProcessMessages',ProcessMessages));

  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));

  HandledProps:=TStringList.Create;
  HandledProps.Add('ClassName');
  HandledProps.Add('ClassParent');
  HandledProps.Add('Ref');
end;

//---------------------------------------------------------
function  ClassTObjectPackage.ClassName(Params:TList):integer;
var
  xObj:TObject;
begin
    Result:=0;
    if(NOT TXVariant(Params.Items[0]).IsObject)then begin
      TXVariant(Params.Items[0]).V:='';  //-- return empty class name
    end else begin
      xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
      TXVariant(Params.Items[0]).V:=xObj.ClassName; //-- return class name
    end;
end;

//---------------------------------------------------------
// Param 0 - TObject (self)
// Param 1 - ClassName of ancestor class for check
//---------------------------------------------------------
// MyObj:InheritedFrom("SomeClassName");
// Check for Some Object's (MyObj) type inherited from specified
// type ("SomeClassName")
//---------------------------------------------------------
function  ClassTObjectPackage.InheritedFrom(Params:TList):integer;
var
  xObj:TObject;
  S:String;
  ParentClass:TClass;
  YesNo:lua_number;
begin
    Result:=0;
    YesNo:=0;

    if(NOT TXVariant(Params.Items[0]).IsObject)then begin
      TXVariant(Params.Items[0]).V:=0;
      Exit;
    end;

    xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
    S:=String(TXVariant(Params.Items[1]).V);
    ParentClass:=xObj.ClassType; //-- get our TClass
    while(ParentClass <> Nil)do begin
       if(ParentClass.ClassName = S)then begin
         YesNo:=1;
         break;
       end;
       ParentClass:=ParentClass.ClassParent; //-- get ancestor class
    end;

    //-- return true or false result
    TXVariant(Params.Items[0]).V:=YesNo;
end;

//---------------------------------------------------------------
// MyObj:LoadFromFile("FileName");
// Load content of some object from specified file.
// This function valid for Objects of the following types:
//   TStrings,TBitmap,TPicture,TImage.
//---------------------------------------------------------------
function ClassTObjectPackage.LoadFromFile(Params:TList):integer;
var
  xObj:TObject;
  S:String;
begin
    Result:=0;
    xObj:=TObject(TXVariant(Params.Items[0]).Ptr); //-- Object
    S:=String(TXVariant(Params.Items[1]).V); //-- file name

    if(xObj is TStrings)then begin
       TStrings(xObj).LoadFromFile(S);
    end else if(xObj is TBitmap)then begin
       TBitmap(xObj).LoadFromFile(S);
    end else if(xObj is TPicture)then begin
       TPicture(xObj).LoadFromFile(S);
    end else if(xObj is TImage)then begin
       TImage(xObj).Picture.LoadFromFile(S);
    end else

end;

//---------------------------------------------------------------
// MyObj:SaveToFile("FileName");
// Save content of some object to specified file.
// This function valid for Objects of the following types:
//   TStrings,TBitmap,TPicture,TImage.
//---------------------------------------------------------------
function ClassTObjectPackage.SaveToFile(Params:TList):integer;
var
  xObj:TObject;
  S:String;
begin
    Result:=0;
    xObj:=TObject(TXVariant(Params.Items[0]).Ptr); //-- Object
    S:=String(TXVariant(Params.Items[1]).V); //-- file name

    if(xObj is TStrings)then begin
       TStrings(xObj).SaveToFile(S);
    end else if(xObj is TBitmap)then begin
       TBitmap(xObj).SaveToFile(S);
    end else if(xObj is TPicture)then begin
       TPicture(xObj).SaveToFile(S);
    end else if(xObj is TImage)then begin
       TImage(xObj).Picture.SaveToFile(S);
    end else

end;

//---------------------------------------------------------------
// Wrapper for Application.ProcessMessages;
//---------------------------------------------------------------
function ClassTObjectPackage.ProcessMessages(Params:TList):integer;
begin
      Application.ProcessMessages;
      Result:=0;
end;

//---------------------------------------------------------
// Handle Properties of TObject
//---------------------------------------------------------
function  ClassTObjectPackage.HandleProperties(Params:TList):integer;
var
  xObj:TObject;
  Cmd,PropName:String;
  //Val:Lua_Number;
  //xLst:TList;
  //i:integer;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    xObj:=TObject(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;        //-- Property name

    //----- "ClassName" property -------------------------
    if((PropName = 'ClassName') and (Cmd = 'G'))then begin

        if(NOT TXVariant(Params.Items[1]).IsObject)then begin
           TXVariant(Params.Items[3]).V:='';
           Exit;
        end;

        TXVariant(Params.Items[3]).V:=xObj.ClassName;
        Result:=1;

    //----- "ClassParent" property -------------------------
    end else if((PropName = 'ClassParent') and (Cmd = 'G'))then begin
        if(NOT TXVariant(Params.Items[1]).IsObject)then begin
           TXVariant(Params.Items[3]).V:='';
           Exit;
        end;

        if(xObj.ClassParent <> NIL)then begin
           TXVariant(Params.Items[3]).Ptr:=xObj.ClassParent;
        end else begin
           TXVariant(Params.Items[3]).Ptr:=NullPtrObject;
        end;
        Result:=1;
    //----- "Ref" property Return address of Specified object --------------
    end else if((PropName = 'Ref') and (Cmd = 'G'))then begin
         TXVariant(Params.Items[3]).Ptr:=xObj;
         Result:=1;
    end;

end;



//---------------------------------------------------------
// TForm class Package
// Can not be implemented so, because of lot of props
// delegates over TForm to TControl/TObject e.t.c
//---------------------------------------------------------
//---------------------------------------------------------
// TForm class Package
// Inheritance:
//   TObject -> TControl -> TWinControl -> TForm
// Mostly implements refferences to Controls owned by form.
// For example:  myBtn=MyForm1.Btn1
// myBtn get refference to Button having name "Btn1"
// which owned by form "MyForm1".
// When we create controls, they are created with specified "Owner".
// Eg:
// NEW.ControlOwner=MyForm1    -- Form "MyForm1" will be a Owner of Button
// myBtn=NEW.TButton           -- Create Button control
// myBtn.Name="Btn1"           -- Give name "Btn1" to newly created Button
// myBtn.Parent=MyForm1.Panel1 -- Set "Panel1" a parent of Button. (Button will resides on this panel).
//
// When Form became an "Owner" of some control - this control
// added to Form's list of owned controls. This list can be used
// for enumerate all controls belongs to Form. And when Form will be deleted
// it automatically deletes all controls it owns.
//---------------------------------------------------------
procedure ClassTFormPackage.RegisterFunctions;
begin
  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));

  HandledProps:=TStringList.Create;
  HandledProps.Add('.ControlName as Form Property');
end;

//--------------------------------------------------
// Use Control Names as Properties of Form
//--------------------------------------------------
function ClassTFormPackage.HandleProperties(Params:TList):integer;
var
  pV:TXVariant;
  xSearchIn:TWinControl;
  xComponent:TComponent;
  xFrm:TForm;
  PropName:String;
  Cmd:String;
  xValue:LUA_NUMBER;
begin
  Result:=0;

  Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

  xFrm:=TForm(TXVariant(Params.Items[1]).Ptr); //--- Object
  PropName:=TXVariant(Params.Items[2]).V;         //-- Property name

  //--- Try to find Property of TForm -----------
  if((PropName = 'ModalResult') and (Cmd = 'G'))then begin
     xValue:=xFrm.ModalResult;
     TXVariant(Params.Items[3]).V:=xValue;
     Result:=1;
     Exit;
  end;


  //--- Try to find component on form whith specified name ----
  xComponent:=LC_FindComponentByName(xFrm,PropName);
  if(xComponent = Nil)then begin
      Result:=0;
  end else begin
      TXVariant(Params.Items[3]).Ptr:=xComponent;
      Result:=1; //-- FOUND - OK
  end;
end;


//---------------------------------------------------------
// TWinControl Package
// Inheritance:
//   TObject -> TControl -> TWinControl
//
// Implements some specific of TControl which has
// Window. For example - Panel control.
// Objects of type of TWinControl can have
// child controls (eg. controls resides on Panel).
// For these child controls Panel will be a Parent control.
// TWinControl has methods for enumerate child controls.
// as whell as find some child control by it's Name.
//---------------------------------------------------------
procedure ClassTWinControlPackage.RegisterFunctions;
begin
  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));
  Methods.AddObject('FindComponentByName',TUserFuncObject.CreateWithName('FindComponentByName',FindComponentByName));


  HandledProps:=TStringList.Create;
  HandledProps.Add('ControlCount');
  HandledProps.Add('Controls');

end;

//---------------------------------------------------------
// MyCompo=MyWinControl:FindComponentByName("ComponentName");
//
// Scan for list of Components owned by some WinControl for component
// with specified name.
// Return: refference to component if found.
//         NULL if not found.
// Example:
//  xBtn1=Form1:FindComponentByName("Btn1");
//  if(xBtn1 ~= NULL)then
//     xBtn1.Caption="BTN1";
//  end;
//
//---------------------------------------------------------
function ClassTWinControlPackage.FindComponentByName(Params:TList):integer;
var
  pV:TXVariant;
  xSearchIn:TWinControl;
  xComponent:TComponent;
begin
  Result:=0;
  //--- get ptr to first param - object where search control
  pV:=TXVariant(Params.Items[0]);

  if(NOT pV.IsObject)then begin
     TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
     Exit;
  end;

  if(TObject(pV.Ptr) is TWinControl)then begin
     xSearchIn:=TWinControl(pV.Ptr);
  end else begin
     TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
     Exit;
  end;

   //--- Here when we work under debugger - it's form is active - so can't find Component ------
   xComponent:=LC_FindComponentByName(xSearchIn,String(TXVariant(Params.Items[1]).V));
   if(xComponent = Nil)then begin
      TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
   end else begin
      TXVariant(Params.Items[0]).Ptr:=xComponent;
   end;
end;
//---------------------------------------------------------------
// Function for Get/Set non published properties of TWinControl
//---------------------------------------------------------------
function ClassTWinControlPackage.HandleProperties(Params:TList):integer;
var
  xObj:TWinControl;
  Cmd,PropName:String;
  Val:Lua_Number;
  xLst:TList;
  i:integer;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    xObj:=TWinControl(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;        //-- Property name

    //----- "ControlCount" property -------------------------
    if((PropName = 'ControlCount') and (Cmd = 'G'))then begin
        Val:=xObj.ControlCount;
        TXVariant(Params.Items[3]).V:=Val;
        Result:=1;

    //----- "Controls" property -------------------------
    end else if((PropName = 'Controls') and (Cmd = 'G'))then begin
        //--- Return Controls as TList ---------
        xLst:=TList.Create;
        for i:=0 to xObj.ControlCount-1 do begin
             xLst.Add(xObj.Controls[i]);
        end;

        TXVariant(Params.Items[3]).Ptr:=xLst;
        Result:=1;
    end;

end;

//---------------------------------------------------------
// TComponent Package
// Inheritance:
// TObject -> TComponent
// TComponent is the base class for all Controls.
// Component is something we can place to form and save to file.
// Component have "Name" property. Component can be an "Owner" for
// other Components.
//---------------------------------------------------------
procedure ClassTComponentPackage.RegisterFunctions;
begin
  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));
  Methods.AddObject('Show',TUserFuncObject.CreateWithName('Show',Show));
  Methods.AddObject('ShowModal',TUserFuncObject.CreateWithName('ShowModal',ShowModal));
  Methods.AddObject('Close',TUserFuncObject.CreateWithName('Close',Close));
  Methods.AddObject('FindComponent',TUserFuncObject.CreateWithName('FindComponent',FindComponent));

  HandledProps:=TStringList.Create;
  HandledProps.Add('ComponentCount');
  HandledProps.Add('Components');
  HandledProps.Add('ControlCount');
  HandledProps.Add('Controls');
  HandledProps.Add('ExeName');
  HandledProps.Add('Owner');
  HandledProps.Add('Parent');
  HandledProps.Add('Onxx Events');

end;


//---------------------------------------------------------------
// Find Component in list
//---------------------------------------------------------------
function ClassTComponentPackage.FindComponent(Params:TList):integer;
var
  xObj:TComponent;
  CName:String;
  i:integer;
begin
    Result:=0;
    xObj:=TComponent(TXVariant(Params.Items[0]).Ptr); //--- Object

   // if(xObj is TForm)then begin
   //    CName:=TXVariant(Params.Items[1]).V;

   // end;
    CName:=TXVariant(Params.Items[1]).V;
    xObj:=xObj.FindComponent(CName);
    if(xObj = Nil)then begin
      TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
    end else begin
      TXVariant(Params.Items[0]).Ptr:=xObj;
    end;
    Exit;

    for i:=0 to xObj.ComponentCount-1 do begin
         if(not (xObj.Components[i] is TComponent))then Continue;
         if(TComponent(xObj.Components[i]).Name = CName)then begin
             TXVariant(Params.Items[0]).Ptr:=xObj.Components[i];
             Exit;
         end;
    end;
    TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
end;

//---------------------------------------------------------------
// Function for Get/Set non published properties of TWinControl
//---------------------------------------------------------------
function ClassTComponentPackage.HandleProperties(Params:TList):integer;
var
  xObj:TComponent;
  xLuaFunc:TObject;
  Cmd,PropName:String;
  Val:Lua_Number;
  xLst:TList;
  i:integer;
  PropInfo:PPropInfo;
  xMethod:TMethod;
  pMethod:Pointer;
  xEventProxy:TLuaEventProxy;
  CompoEventPropName:String;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    xObj:=TComponent(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;           //-- Property name

    //----- "ComponentCount" property -------------------------
    if((PropName = 'ComponentCount') and (Cmd = 'G'))then begin
        Val:=xObj.ComponentCount;
        TXVariant(Params.Items[3]).V:=Val;
        Result:=1;

    //----- "Components" property -------------------------
    end else if((PropName = 'Components') and (Cmd = 'G'))then begin
        //--- Return Controls as TList ---------
        xLst:=TList.Create;
        for i:=0 to xObj.ComponentCount-1 do begin
             xLst.Add(xObj.Components[i]);
        end;

        TXVariant(Params.Items[3]).Ptr:=xLst;
        Result:=1;
    //----- "ControlCount" property -------------------------
    end else if((PropName = 'ControlCount') and (Cmd = 'G'))then begin
        if(xObj is TWinControl)then begin
          Val:=TWinControl(xObj).ControlCount;
        end else begin
          Val:=0;
        end;
        TXVariant(Params.Items[3]).V:=Val;
        Result:=1;

    //----- "Controls" property -------------------------
    end else if((PropName = 'Controls') and (Cmd = 'G'))then begin
        //--- Return Controls as TList ---------
        xLst:=TList.Create;
        if(xObj is TWinControl)then begin
           for i:=0 to TWinControl(xObj).ControlCount-1 do begin
              xLst.Add(TWinControl(xObj).Controls[i]);
           end;
        end;

        TXVariant(Params.Items[3]).Ptr:=xLst;
        Result:=1;
    //----- "Exename" property -------------------------
    end else if((PropName = 'ExeName') and (Cmd = 'G'))then begin
        TXVariant(Params.Items[3]).V:=Application.ExeName;
        Result:=1;
    end;

    if(Result = 1)then begin
      Exit;
    end;

    //--- Check for Methods Properties Assignment ------
    try
       if(Cmd = 'S')then begin
          if(NOT TXVariant(Params.Items[3]).IsObject)then begin
            Exit; //--- if command = Set - only TByteCodeProto object can be set as Method -----
          end;
       end;

      //--- Firstly define does object has such property ---
      //--- Get Info about this property. Return NULL if not found ---
      PropInfo:=TypInfo.GetPropInfo(xObj.ClassType, PropName);
      if(PropInfo = Nil)then begin
         Exit; //-- No such property in object's class ----
      end;

      //--- Check if it is METHOD-kind property ---------
      if(PropInfo^.PropType^.Kind = tkMethod)then begin

            //--- If Get command - take LuaFunction attached to EventProxy which set for this Onxxx Property ---
            if(Cmd = 'G')then begin
                //-- Scan attached event proxies and find one which set for this Onxxx property ---
                for i:=0 to xObj.ComponentCount-1 do begin
                   if(xObj.Components[i] is TLuaEventProxy)then begin
                       xEventProxy:=TLuaEventProxy(xObj.Components[i]);
                       //-- Get Lua function which set for this prop ----------
                       if(xEventProxy.EventPropName = PropName)then begin
                          TXVariant(Params.Items[3]).Ptr:=xEventProxy.FLuaEventHandlerFunction;
                          Result:=1;
                          Exit;
                       end;
                   end;
                end;
                //--- Onxx property Not set - return NULL
                TXVariant(Params.Items[3]).Ptr:=NullPtrObject;
                Result:=1;
                Exit;
            end;


           //---First Check if request for RESET EVENT Property to Null value ---------
           if(TXVariant(Params.Items[3]).Ptr = NullPtrObject)then begin
               xMethod.Code:=Nil;
               xMethod.Data:=Nil;
               TypInfo.SetMethodProp(xObj,PropInfo,xMethod);
               Result:=1;
               Exit;
           end;

           //---- Check if object for assign to our Onxxx property is Lua Function (obj of TByteCodeProto type) ---
           if(NOT TXVariant(Params.Items[3]).IsObject)then begin
                 Exit; //--- not Lua function invalid
           end;

           //---- Check if object for assign to our Onxxx property is Lua Function (obj of TByteCodeProto type) ---
           if(NOT (TObject(TXVariant(Params.Items[3]).Ptr) is TByteCodeProto))then begin
                 Exit; //--- not Lua function invalid
           end;


           CompoEventPropName:=PropName; //--- save Onxxx prop name

           //------ Otherwice - new prop value must be Lua Function (object of TByteCodeProto type).
           PropName:=PropInfo^.PropType^.Name; //-- get method type name e.g. 'TNotifyEvent'
           PropName:=PropName+'Wrapper';       //--- make internal name e.g 'TNotifyEventWrapper' used in EventProxy

           xEventProxy:=TLuaEventProxy.Create(TComponent(xObj));

           //--- Find does TLuaEventProxy class have such method (e.g. 'TNotifyEventWrapper'. It must be published!) -------
           pMethod:=xEventProxy.MethodAddress(PropName);

           if(pMethod <> Nil)then begin
             xMethod.Code:=pMethod;
             xMethod.Data:=xEventProxy;

             //--- Save pointer to Lua Function (TByteCodeProto object) in "Tag" property of Component ----
             //--- Set pointer to our internal wrapper Method to Property of Object ------
             TypInfo.SetMethodProp(xObj,PropInfo,xMethod);
             //--- Save specified LuaFunction in xEventProxy object ---
             xEventProxy.FLuaEventHandlerFunction:=TByteCodeProto(TXVariant(Params.Items[3]).Ptr);
             xEventProxy.EventPropName:=CompoEventPropName; //-- save property name for reset it then
             Result:=1;

           end else begin
               //--- if No such method in EventProxy class - destroy it ----
               xEventProxy.Destroy;
           end;
      end;

    except
       Exit;
    end;
end;

//-----------------------------------------------------------------
// MyComponent:ShowModal();
// Mostly used if Component is TForm.
// Show (Form) as Dilaog. While it is open - focus can't be moved
// to another form of application.
//-----------------------------------------------------------------
function  ClassTComponentPackage.ShowModal(Params:TList):integer;
var
  xObj:TObject;
begin
    xObj:=TObject(TXVariant(Params.Items[0]).Ptr); //--- Object
    if(xObj is TCustomForm)then begin
       TCustomForm(xObj).ShowModal;
    end;
    Result:=0;
end;

//-----------------------------------------------------------------
// MyComponent:Show();
// Mostly used if Component is TForm.
// Show (Form). Focus can be moved to this form or to some another
// form of application.
//-----------------------------------------------------------------
function  ClassTComponentPackage.Show(Params:TList):integer;
begin
    if(TObject(TXVariant(Params.Items[0]).Ptr) is TControl)then begin
       TControl(TXVariant(Params.Items[0]).Ptr).Show; //--- Object
    end;
    Result:=0;
end;

//-----------------------------------------------------------------
// MyComponent:Close();
// Mostly used if Component is TForm.
// Close specified Form.
// Form became invisible, but not deleted here. It can be showed
// agan with Show() or ShowModal() methods.
//-----------------------------------------------------------------
function  ClassTComponentPackage.Close(Params:TList):integer;
begin
    if(TObject(TXVariant(Params.Items[0]).Ptr) is TCustomForm)then begin
       TCustomForm(TXVariant(Params.Items[0]).Ptr).Close; //--- Object
    end;
    Result:=0;
end;

//==========================================================
// TableFuncPackage implementation
//==========================================================
//----------------------------------------------------------
//  Package for support Lua Tables:
//
//  Example of tables declarations
//  MyTbl1={Btn1,Btn2,Combobox1}                    -- Definition of Table with numeric indexes
//  MyTbl1[1]=Btn1                                  -- Refference to element of table
//
//  MyTbl2={First=Btn1,Second=Btn2,Third=Combobox1} -- Definition of Table with named indexes
//  MyTbl2[First]=Btn1                              -- Refference to element of table ... or
//  MyTbl2.First=Btn1                               -- Equivalent form of refference to element of table
//
//  NOTE:
//   Table indexes always goes from "1"!! In comparision, indexes of TStringList,TList and some
//   other objects inherited from Delphi always goes from "0".
//
//  Tables can be treated
//  as arrays (if numeric indexes used)
//  as Structures (if named indexes used) or even Objects.
//  For example we can write:
//
//  function MyObj1_MyFunction(xTbl,Value)
//     xTbl.Widht=xTbl.Widht+Value;
//     xTbl.Height=xTbl.Height+Value;
//  end;
//
//  MyObj1={Width=10,Height=20,Grow=MyFunction}
//  MyObj1:Grow(10); -- call function specified in table and send MyObj1 as first parameter.
//
//  The last call is equivalent to:
//  MyObj1.Grow(MyObj1,10); -- Just get element of table and assume that it is some function.
//
//
//  Tables restrictions:
//  -------------------
//   1) Only numeric and/or string keys are accepted for tables.
//    MyTable[MyLocal] -- Is invalid if "MyLocal" contains refference to some object/function.
//    If "MyLocal" is Numeric or String - O.K.
//   2) Currently, some native lua "tables" package functions not supported e.g: "foreach" "foreachi"
//   3) After creation - tables stays in memory till respective TByteCodeProto destructor (Destroy).
//      So, intensive creation of tables (eg. in procedure which called many times) can lead to grow of memory usage.
//      For prevent this user can call "DeleteTables()" build-in function which delete all tables
//      created in context of current function.
//      As alternative to tables user can use NEW.TList or NEW.TStringList with following
//      "Delete(xxxx)".
//
//  Table Extensions:
//  ----------------
// 1) There is some build-in function named "CreateArray(...)" with variable number of parameters.
// This function let us create Multiple dimensioned tables.
// Example:
//  local MyXYZTable=CreateArray(10,20,30); -- Create 3-D table
//  MyXYZTable[1][5][20]="JJJJJJ";
//
// 2)Internally, TLuaTable has TList and TStringList parts which can be accessed with GetTList,GetTStringList functions.
//  Example:
//  local TblList1=table.GetTList(MyLocalTable);
//  local TblStList1=table.GetTStringList(MyLocalTable);
//
// 3) "TableFuncPackage" registered as Function Package and ClassPackage. It can be done,
//     because first parameter of all functions is TLuaTable.
//     So both of following types of calls are valid:
//    local i=table.GetTableLength(MyTbl1);
//    local i=MyTbl1:GetTableLength();
//
// 4) Special temporary table can be used for set properties of some object.
//  Example:
//      MyObject:Properties={Prop1=1;Prop2="xxx";Prop3="yyy"};
//
//  Here "Properties" is some predefined "syntax-type" keyword.
//
//  NOTE: Table of properties is always treated as TEMPORARY and being deleted after set properties operation.
//  So the following usage is valid, but can lead to unexpected results!
//   local X={Prop1=1;Prop2="xxx";Prop3="yyy"};
//   MyObject:Properties=X -- Table X will be destroyed after this assignment!
//--------------------------------------------------------------------------------------------
procedure TableFuncPackage.RegisterFunctions;
begin
  Methods.AddObject('getn',TUserFuncObject.CreateWithName('getn',GetTableLength));
  Methods.AddObject('Length',TUserFuncObject.CreateWithName('getn',GetTableLength));
  Methods.AddObject('gets',TUserFuncObject.CreateWithName('gets',GetSTableLength));
  Methods.AddObject('SLength',TUserFuncObject.CreateWithName('SLength',GetSTableLength));
  Methods.AddObject('insert',TUserFuncObject.CreateWithName('insert',Insert));
  Methods.AddObject('delete',TUserFuncObject.CreateWithName('delete',Delete));
  Methods.AddObject('GetTList',TUserFuncObject.CreateWithName('GetTList',GetTList));
  Methods.AddObject('GetTStringList',TUserFuncObject.CreateWithName('GetTStringList',GetTStringList));
  Methods.AddObject('Copy',TUserFuncObject.CreateWithName('Copy',Copy));

  //Methods.AddObject('CreateArray',TUserFuncObject.CreateWithName('CreateArray',CreateArray));
  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));

  HandledProps:=TStringList.Create;
  HandledProps.Add('Sorted');

end;

//--------------------------------------------------
// Helper function for check Table parameter
//--------------------------------------------------
function  TableFuncPackage.GetTableFromParams(Params:TList):TLuaTable;
label
  lblErr;
var
  xObj:TObject;
begin
    if(not TXVariant(Params.Items[0]).IsObject)then begin
       goto lblErr;
    end;
    xObj:=TObject(TXVariant(Params.Items[0]).Ptr);

    if(not (xObj is TLuaTable))then begin
       goto lblErr;
    end;
    Result:=TLuaTable(xObj);
    Exit;

lblErr:
    raise Exception.Create('Table Operation on non Table Object.');

end;

//----------------------------------------------------
// l=table.Length(MyTbl); -- or
// l=table.getn(MyTbl);   -- or
// l=MyTbl:Length();      -- or
// l=MyTbl:getn(MyTbl);
//
// Return Length of IndexList part of table.
//----------------------------------------------------
function  TableFuncPackage.GetTableLength(Params:TList):integer;
var
  Tbl:TLuaTable;
  xCount:Real;
begin
    Tbl:=GetTableFromParams(Params);
    xCount:=Tbl.iCount;
    //if(xCount > 0)then Dec(xCount);

    TXVariant(Params.Items[0]).V:=xCount;
    Result:=0;
end;

//----------------------------------------------------
// l=table.SLength(MyTbl); -- or
// l=table.gets(MyTbl);   -- or
// l=MyTbl:SLength();      -- or
// l=MyTbl:gets(MyTbl);
//
// Return Length of StringList part of table.
//-----------------------------------------------------
function  TableFuncPackage.GetSTableLength(Params:TList):integer;
var
  Tbl:TLuaTable;
begin
    Tbl:=GetTableFromParams(Params);
    TXVariant(Params.Items[0]).V:=Tbl.sCount;
    Result:=0;
end;


//-----------------------------------------------------------
// Add or Insert by position to IndexList part of table
//-----------------------------------------------------------
function TableFuncPackage.Insert(Params:TList):integer;
var
  Tbl:TLuaTable;
  pV:TXVariant;
  r:Lua_Number;
  iPos:integer;
begin
    Tbl:=GetTableFromParams(Params);

    if(Params.Count = 2)then begin //-- just add value
       pV:=TXVariant.Create;
       r:=Tbl.iCount+1;
       pV.V:=r;
       Tbl.SetTableValue(pV,TXVariant(Params.Items[1]));
       pV.Destroy;
    end else if(Params.Count = 3)then begin  //-- insert value by position
        //-- If param 2 is String - add key/value ------
        if(TXVariant(Params.Items[1]).VarType = varString)then begin
           Tbl.SetTableValue(TXVariant(Params.Items[1]),TXVariant(Params.Items[2]));
        end else if(TXVariant(Params.Items[1]).VarType = varDouble)then begin
            iPos:=TXVariant(Params.Items[1]).V;  //-- must be numeric (1-based)
            if(iPos > Tbl.IndexedList.Count)then begin
                Tbl.SetTableValue(TXVariant(Params.Items[1]),TXVariant(Params.Items[2]));
            end else begin
                pV:=TXVariant.Create;
                pV.Assign(TXVariant(Params.Items[2]));
                Tbl.IndexedList.Insert(iPos-1,pV);
            end;
        end;
    end;
    Result:=0;
end;

//-----------------------------------------------------------
// Delete element of table
//  MyTbl:Delete("KeyOfDeletedElement") if table with Keys - delete by key
//  MyTbl:Delete(101) if indexed table - delete by index
//  MyTbl:Delete()    Delete all elements of table
//-----------------------------------------------------------
function TableFuncPackage.Delete(Params:TList):integer;
var
  Tbl:TLuaTable;
  iPos:integer;
  pV:TXVariant;
begin
    Result:=0;

    Tbl:=GetTableFromParams(Params);

    //--- Clear All Table ----------
    if(Params.Count = 1)then begin
          if(Tbl.IndexedList <> Nil)then begin
             for iPos:=0 to Tbl.IndexedList.Count-1 do begin
                 //-- Delete attached object
                 pV:=TXVariant(Tbl.IndexedList.Items[iPos]);
                 //---- If element of table is TLuaTable - also destroy it---
                 if(pV.isObject)then begin
                   if(TObject(pV.Ptr) is TLuaTable)then begin
                      TLuaTable(pV.Ptr).Destroy;
                   end;
                 end;
                 pV.Free;
             end;
             Tbl.IndexedList.Clear;
          end;

          if(Tbl.DictList <> Nil)then begin
             for iPos:=0 to Tbl.DictList.Count-1 do begin
                 //-- Delete attached object
                 pV:=TXVariant(Tbl.DictList.Objects[iPos]);
                 //---- If element of table is TLuaTable - also destroy it---
                 if(pV.isObject)then begin
                   if(TObject(pV.Ptr) is TLuaTable)then begin
                      TLuaTable(pV.Ptr).Destroy;
                   end;
                 end;
                 pV.Free;
             end;
             Tbl.DictList.Clear;
          end;

      Exit;
    end;

    //-- If param 2 is String - delete by key ------
    if(TXVariant(Params.Items[1]).VarType = varString)then begin
       iPos:=Tbl.DictList.IndexOf(String(TXVariant(Params.Items[1]).V));
       if(iPos >=0)then begin
           //-- Delete attached object
           pV:=TXVariant(Tbl.DictList.Objects[iPos]);
           //---- If element of table is TLuaTable - also destroy it---
           if(pV.isObject)then begin
             if(TObject(pV.Ptr) is TLuaTable)then begin
                TLuaTable(pV.Ptr).Destroy;
             end;
           end;
           pV.Free;
           Tbl.DictList.Delete(iPos);
       end;

    end else if(TXVariant(Params.Items[1]).VarType = varDouble)then begin
       //-- If param 2 is Numeric - delete from IndexedList by index (1-based) ------
       iPos:=TXVariant(Params.Items[1]).V;
       if(iPos <= Tbl.IndexedList.Count)then begin
          Dec(iPos);
           //-- Delete attached object
           pV:=TXVariant(Tbl.IndexedList.Items[iPos]);
           //---- If element of table is TLuaTable - also destroy it---
           if(pV.isObject)then begin
             if(TObject(pV.Ptr) is TLuaTable)then begin
                TLuaTable(pV.Ptr).Destroy;
             end;
           end;
           pV.Free;
           Tbl.IndexedList.Delete(iPos);
       end;
    end;
    Result:=0;
end;

//--------------------------------------
//-- return TList part of Table
//--------------------------------------
function TableFuncPackage.GetTList(Params:TList):integer;
var
  Tbl:TLuaTable;
begin
    Tbl:=GetTableFromParams(Params);
    if(Tbl.IndexedList = Nil)then begin
       TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
    end else begin
       TXVariant(Params.Items[0]).Ptr:=Tbl.IndexedList;
    end;
    Result:=0;
end;

//--------------------------------------
//-- return TStrinList part of Table
//--------------------------------------
function TableFuncPackage.GetTStringList(Params:TList):integer;
var
  Tbl:TLuaTable;
begin
    Tbl:=GetTableFromParams(Params);
    if(Tbl.DictList = Nil)then begin
       TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
    end else begin
       TXVariant(Params.Items[0]).Ptr:=Tbl.DictList;
    end;
    Result:=0;
end;

//------------------------------------------------------
// Table properties:
// Tbl.Sorted=true
//------------------------------------------------------
function  TableFuncPackage.HandleProperties(Params:TList):integer;
var
  Tbl:TLuaTable;
  Cmd,PropName:String;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    Tbl:=TLuaTable(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;         //-- Property name

    //----- "Sorted" property -------------------------
    if(PropName = 'Sorted')then begin
        if(Cmd = 'G')then begin
          TXVariant(Params.Items[3]).V:=Tbl.DictList.Sorted;
          Result:=1;
        end else begin
          Tbl.DictList.Sorted:=TXVariant(Params.Items[3]).V;
          Result:=1;
        end;
    end;
end;


//----------------------------------------------------
// local NewTable=MyTbl:Copy();
//
// Create new Lua Table and copy elements of MyTbl
//----------------------------------------------------
function  TableFuncPackage.Copy(Params:TList):integer;
var
  Tbl:TLuaTable;
  NewTbl:TLuaTable;
  i:integer;
  pV1,pV2:TXVariant;
begin
    Tbl:=GetTableFromParams(Params);

    //-- create new table and add it to the same owner
    //-- Note: owner needs for able to delete all created tables
    NewTbl:=TLuaTable.Create(Tbl.TableOwnerList);

    //--- Duplicate elements of DictList (StringList) if exists
    if(Tbl.DictList <> Nil)then begin
       NewTbl.DictList:=TStringList.Create;
       NewTbl.DictList.Assign(Tbl.DictList); //--- assign strings
       for i:=0 to Tbl.DictList.Count-1 do begin
          pV1:=TxVariant.Create;
          pV2:=TxVariant(Tbl.DictList.Objects[i]);
          pV1.Assign(pV2);
          NewTbl.DictList.Objects[i]:=pV1; //-- assign objects
       end;
    end;

    //--- Duplicate elements of indexed list if exists
    if(Tbl.IndexedList <> Nil)then begin
       NewTbl.IndexedList:=TList.Create;
       for i:=0 to Tbl.IndexedList.Count-1 do begin
         pV1:=TxVariant.Create;
         pV2:=TxVariant(Tbl.IndexedList.Items[i]);
         pV1.Assign(pV2);
         NewTbl.IndexedList.Add(pV1);
       end;
    end;

    TXVariant(Params.Items[0]).Ptr:=NewTbl; //-- return new table
    Result:=0;
end;



//-------------------------------------------------------------------------------------------
// Class TByteCodeProto:
//
// All compiled LUA executable modules contained in
// TByteCodeProto objects. LUADVM Virtial machine,which interpret
// bytecode (obtained by compilation of source LUA module) make deal with this class.
// All Internal functions of module also stored into TByteCodeProto
// classes, attached to main function's TByteCodeProto.
// Currently, there are only few functions, which let us influence to interpretation
// process.Mostly these functions concerning to control of global variables.
// Currently executed module can be accessed via pseudo global variable named "MODULE".
// Statements like the following:
// "MODULE.GlobalName" are treated by interpreter as access to specified "GlobalName".
// For Example we can check if some global function currently loaded and available for call:
// if(MODULE.MyGlobalFunction ~= NULL)then
//     MyGlobalFunction(); -- call function if loaded
// end;
//-------------------------------------------------------------------------------------------
procedure Package_TByteCodeProto.RegisterFunctions;
begin
  Methods.AddObject('SaveGlobals',TUserFuncObject.CreateWithName('SaveGlobals',SaveGlobals));
  Methods.AddObject('SaveGlobal',TUserFuncObject.CreateWithName('SaveGlobal',SaveGlobal));
  Methods.AddObject('DeleteGlobal',TUserFuncObject.CreateWithName('DeleteGlobal',DeleteGlobal));
  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));
  Methods.AddObject('FindByName',TUserFuncObject.CreateWithName('FindByName',FindByName));

  HandledProps:=TStringList.Create;
  HandledProps.Add('MODULE.GlobalName');

end;

//--------------------------------------------------------------------------
// Obsolete. Use FindControlByName of TForm class.
// Call OnHandleGlobals for get refference (mostly for find control by name)
// if NOT found - return NULL (NullPtrObject)
//--------------------------------------------------------------------------
function Package_TByteCodeProto.FindByName(Params:TList):integer;
var
  pV:TXVariant;
  xByteCodeProto:TByteCodeProto;
  xSearchForm:TForm;
  xComponent:TComponent;
begin
  Result:=0;
  //--- get ptr to Self - current TByteCodeProto
  pV:=TXVariant(Params.Items[0]);

  if(NOT pV.IsObject)then begin
     TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
     Exit;
  end;

  if(TObject(pV.Ptr) is TByteCodeProto)then begin
     xByteCodeProto:=TByteCodeProto(pV.Ptr);

     if((xByteCodeProto <> Nil) and (TByteCodeProto(xByteCodeProto).NameSpace <> Nil))then begin
        xSearchForm:=TForm(TByteCodeProto(xByteCodeProto).NameSpace.CtrlForm);
     end else begin
        xSearchForm:=Screen.ActiveForm;
     end;
  end else if(TObject(pV.Ptr) is TForm)then begin
     xSearchForm:=TForm(pV.Ptr)
  end else begin
     TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
     Exit;
  end;

   //--- Here when we work under debugger - it's form is active - so can't find Component ------
   xComponent:=LC_FindComponentByName(xSearchForm,String(TXVariant(Params.Items[1]).V));
   if(xComponent = Nil)then begin
      TXVariant(Params.Items[0]).Ptr:=NullPtrObject;
   end else begin
      TXVariant(Params.Items[0]).Ptr:=xComponent;
   end;
end;


//--------------------------------------------------------------------------
// MODULE.SaveGlobals();
//
// Instruct TByteCodeProto for NOT delete all globals created
// from start of module execution and current execution point.
// Note: ALL internal functions of current TByteCodeProto
// also are saved as globals.
// So,after TByteCodeProto destructor they became unaccessable.
// This function can be helpful for save global constants or result
// of some function which loaded in runtime and then going to be unloaded.
//--------------------------------------------------------------------------
function Package_TByteCodeProto.SaveGlobals(Params:TList):integer;
var
  pV:TXVariant;
  pDVM:TByteCodeProto;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);

  if(NOT pV.IsObject)then begin
     Exit;
  end;

  if(NOT (TObject(pV.Ptr) is TByteCodeProto))then begin
     Exit;
  end;

   pDVM:=TByteCodeProto(pV.Ptr);
   if(pDVM.AddedToGlobals <> Nil)then begin
     pDVM.AddedToGlobals.Clear; //-- clear info about all variables added to globals during execution
   end;

end;

//---------------------------------------------------------------------
// MODULE.SaveGlobal("GlobalVarName");                       -- save one global.
// MODULE.SaveGlobal("GlobalVarName1","GlobalVarName2",,,,); -- save all specified globals.
//
// Instruct TByteCodeProto for NOT delete specified global variable(s)
// on TByteCodeProto destructor.
// Variable can be specified by name or by refference.
// There can be few variables specified in Params list
// This function can be helpful for save global constants or result
// of some function which loaded in runtime and then going to be unloaded.
//---------------------------------------------------------------------
function Package_TByteCodeProto.SaveGlobal(Params:TList):integer;
var
  pV:TXVariant;
  pDVM:TByteCodeProto;
  i,j:integer;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);

  if(NOT pV.IsObject)then begin
     Exit;
  end;

  if(NOT (TObject(pV.Ptr) is TByteCodeProto))then begin
     Exit;
  end;

  pDVM:=TByteCodeProto(pV.Ptr);
  if(pDVM.AddedToGlobals = Nil)then begin
    Exit;
  end;

  for j:=1 to Params.Count-1 do begin
    pV:=TXVariant(Params.Items[j]);
    if(pV.VarType = varString)then begin
       if(pDVM.AddedToGlobals.Find(String(pV.V),i))then begin
          pDVM.AddedToGlobals.Delete(i);
       end;
    end else if(pV.IsObject)then begin
       //--- Find specified object by scan list of AddedGlobals ----
        for i:=0 to pDVM.AddedToGlobals.Count-1 do begin
             if(pV.Ptr = pDVM.AddedToGlobals.Objects[i])then begin
                pDVM.AddedToGlobals.Delete(i);
                break;
             end;
        end;
    end;
  end;


end;

//---------------------------------------------------------------------
// MODULE.DeleteGlobal("GlobalName");                  -- or
// MODULE.DeleteGlobal("GlobalName1","GlobalName2",,);
//
// Remove Variable(s) by name(s) from GLobalVarsList
// Variable names in list must be specified as Strings.
// This function mostly used internally by interpreter.
//---------------------------------------------------------------------
function Package_TByteCodeProto.DeleteGlobal(Params:TList):integer;
var
  pV:TXVariant;
  pDVM:TByteCodeProto;
  i,j:integer;
begin
  Result:=0;
  pV:=TXVariant(Params.Items[0]);

  if(NOT pV.IsObject)then begin
     Exit;
  end;

  if(NOT (TObject(pV.Ptr) is TByteCodeProto))then begin
     Exit;
  end;

  pDVM:=TByteCodeProto(pV.Ptr);

  for j:=1 to Params.Count-1 do begin
    pV:=TXVariant(Params.Items[j]);
    if(pV.VarType = varString)then begin
       LuaInter.UnRegisterGlobalVar(String(pV.V),NIL);
    end;
  end;


end;

//---------------------------------------------------------
// Handle Properties of MODULE
// All properties treated as Globals
// Pointer to Global will be returned if found
//---------------------------------------------------------
function Package_TByteCodeProto.HandleProperties(Params:TList):integer;
var
  Cmd,PropName:String;
  pDVM:TByteCodeProto;
  i:integer;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    pDVM:=TByteCodeProto(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;        //-- Property name

    //-- Assume not found ---------------
    TXVariant(Params.Items[3]).Ptr:=NullPtrObject;

    if(Cmd <> 'G')then begin
      Exit;
    end;

    if((pDVM.NameSpace <> NIL) and (pDVM.NameSpace.DupGlobals.Find(PropName,i)))then begin
        //--- If there is such global in list --------
        TXVariant(Params.Items[3]).Ptr:=pDVM.NameSpace.DupGlobals.Objects[i];
    end else if(LuaInter.GlobalVarsList.Find(PropName,i))then begin
        //--- If there is such global in list --------
        TXVariant(Params.Items[3]).Ptr:=LuaInter.GlobalVarsList.Objects[i];
    end;
end;


//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// Create instances of all package classes defined in this module
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
initialization

//--- Create General package -----
PACK_IO:=Package_IO.Create;
PACK_IO.RegisterFunctions;

PackageClassTByteCodeProto:=Package_TByteCodeProto.Create;
PackageClassTByteCodeProto.RegisterFunctions;


PackageTable:=TableFuncPackage.Create;
PackageTable.RegisterFunctions;


//--- Create TStrings Class package -----
PackageClassTStrings:=ClassTStringsPackage.Create;
PackageClassTStrings.RegisterFunctions;

//--- Create TList Class package -----
PackageClassTList:=ClassTListPackage.Create;
PackageClassTList.RegisterFunctions;

//--- Create TObject Class package -----
PackageClassTObject:=ClassTObjectPackage.Create;
PackageClassTObject.RegisterFunctions;

PackageClassTComponent:=ClassTComponentPackage.Create;
PackageClassTComponent.RegisterFunctions;

PackageClassTWinControl:=ClassTWinControlPackage.Create;
PackageClassTWinControl.RegisterFunctions;

PackageClassTForm:=ClassTFormPackage.Create;
PackageClassTForm.RegisterFunctions;

//------------------------------------------------------
// Try to register all that packages and functions
//-------------------------------------------------------
LuaInter.RegisterGlobalFunction('Delete',PACK_IO.DeleteObject);  //-- function from PACK_IO
LuaInter.RegisterGlobalFunction('Assign',PACK_IO.Assign);
LuaInter.RegisterGlobalFunction('IsObject',PACK_IO.IsObject);
LuaInter.RegisterGlobalFunction('LoadLuaBinary',PACK_IO.LoadLuaBinary);
LuaInter.RegisterGlobalFunction('tostring',PACK_IO.tostring);
LuaInter.RegisterGlobalFunction('tonumber',PACK_IO.tonumber);

//--- Register packages ---------------
LuaInter.RegisterGlobalVar('io',PACK_IO);
LuaInter.RegisterGlobalVar('sys',PACK_IO);
LuaInter.RegisterGlobalVar('TByteCodeProto',PackageClassTByteCodeProto);

LuaInter.RegisterGlobalVar('TStrings',PackageClassTStrings);
LuaInter.RegisterGlobalVar('TList',PackageClassTList);
LuaInter.RegisterGlobalVar('TObject',PackageClassTObject);

//--- register table package as table and TLuaTable for being call methods as
//--- xx=mytbl:getn() or xx=table.getn(mytbl)
LuaInter.RegisterGlobalVar('table',PackageTable);
LuaInter.RegisterGlobalVar('TLuaTable',PackageTable);


LuaInter.RegisterGlobalVar('TComponent',PackageClassTComponent);
LuaInter.RegisterGlobalVar('TWinControl',PackageClassTWinControl);
LuaInter.RegisterGlobalVar('TForm',PackageClassTForm); //-- can not be implemented properly

VarTypesLst:=TStringList.Create;
VarTypesLst.AddObject('varEmpty',TObject(varEmpty)); //The Variant is Unassigned.
VarTypesLst.AddObject('varNull',TObject(varNull));	        //The Variant is Null.
VarTypesLst.AddObject('varSmallint',TObject(varSmallint));	//16-bit signed integer (type Smallint).
VarTypesLst.AddObject('varInteger',TObject(varInteger));	//32-bit signed integer (type Integer).
VarTypesLst.AddObject('varSingle',TObject(varSingle));	//Single-precision floating-point value (type Single).
VarTypesLst.AddObject('varDouble',TObject(varDouble));	//Double-precision floating-point value (type Double).
VarTypesLst.AddObject('varCurrency',TObject(varCurrency));	//Currency floating-point value (type Currency).
VarTypesLst.AddObject('varDate',TObject(varDate));	        //Date and time value (type TDateTime).
VarTypesLst.AddObject('varOleStr',TObject(varOleStr));	//Reference to a dynamically allocated UNICODE string.
VarTypesLst.AddObject('varDispatch',TObject(varDispatch));	//Reference to an Automation object (an IDispatch interface pointer).
VarTypesLst.AddObject('varError',TObject(varError));	//Operating system error code.
VarTypesLst.AddObject('varBoolean',TObject(varBoolean));	//16-bit boolean (type WordBool).
VarTypesLst.AddObject('varVariant',TObject(varVariant));	//A Variant.
VarTypesLst.AddObject('varUnknown',TObject(varUnknown));	//Reference to an unknown OLE object (an IUnknown interface pointer).
VarTypesLst.AddObject('varByte',TObject(varByte));         //A Byte
VarTypesLst.AddObject('varStrArg',TObject(varStrArg));       //COM-compatible string.
VarTypesLst.AddObject('varString',TObject(varString));       //Reference to a dynamically allocated string. (not COM compatible)
VarTypesLst.AddObject('varAny',TObject(varAny));          //A CORBA Any value.
VarTypesLst.Sorted:=true;

end.
