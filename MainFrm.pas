unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls,FileCtrl,
  LuaInter,LC_Procs, Buttons,
  //--- used packages -------
  LuaPackages,LuaPackage_Str;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    OpenDialog1: TOpenDialog;
    btnLoadBinary: TButton;
    btnExecScript: TButton;
    Button1: TButton;
    TestPanel: TPanel;
    Panel3: TPanel;
    Memo2: TMemo;
    Memo1: TMemo;
    Splitter1: TSplitter;
    lblMouseCoords: TLabel;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure btnLoadBinaryClick(Sender: TObject);
    procedure btnExecScriptClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    ByteCodeProto:TByteCodeProto;
  private
    procedure PrintListing(LuaFunction:TByteCodeProto);
    function  ResolveLuaGlobalsForActiveForm(xByteCodeProto:TObject;Operation:LUA_OPCODES;pV1,pV2,pV3:TXVariant):integer;
    function  LuaMessageBox(Params:TList):integer;
    procedure RegisterLuaGlobals(xByteCodeProto:TByteCodeProto);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.btnLoadBinaryClick(Sender: TObject);
var
  i:integer;
  InternFunction:TByteCodeProto;
begin
   OpenDialog1.InitialDir:=ExtractFilePath(Application.ExeName);
   if(OpenDialog1.Execute)then begin
     //--- Delete previous Proto if exists -------
     if(ByteCodeProto <> Nil)then begin
       ByteCodeProto.Destroy;
       ByteCodeProto:=Nil;
     end;

     //-- clear list of breakpoints which can be filled from previous ByteCode execution
     //frmLUADebugger.BptList.Clear;

     try
      //-- Create New ByteCodeProto and load file into ----
      ByteCodeProto:=TByteCodeProto.Create(Self);
      RegisterLuaGlobals(ByteCodeProto);

      ByteCodeProto.LoadBinary(OpenDialog1.FileName);
      Memo2.Lines.Clear;

      //------ Print Listing of main function ----------
      PrintListing(ByteCodeProto);

      //------ Print Listing of all internal functions ----------
      for i:=0 to ByteCodeProto.InternalFunctionsList.Count-1 do begin
        InternFunction:=TByteCodeProto(ByteCOdeProto.InternalFunctionsList.Items[i]);
        PrintListing(InternFunction);
      end;

     except
        on E: Exception do begin
          MessageBox(GetActiveWindow(),PChar(E.Message),'Unable to load binary',MB_ICONINFORMATION);
        end;
     end;

   end;



end;


//--------------------------------------------------------
// Print listing of function
//--------------------------------------------------------
procedure TForm1.PrintListing(LuaFunction:TByteCodeProto);
{$IFNDEF LUA_SECURITY}
var
  i:integer;
  Lst:TStringList;
  pV:TXVariant;
  S:String;
{$ENDIF}
  
begin
  {$IFNDEF LUA_SECURITY}

      if(Memo2.Lines.Count > 0)then begin
          Memo2.Lines.Add('');
      end;
      Memo2.Lines.Add('FUNCTION:'+LuaFunction.source);

      //----- Show all constnats ---------
      if(LuaFunction.ConstList.Count > 0)then begin
        Memo2.Lines.Add('FUNCTION CONSTANTS:');
        Memo2.Lines.Add('=====================');
        for i:=0 to LuaFunction.ConstList.Count-1 do begin
           pV:=TXVariant(LuaFunction.ConstList.Items[i]);
           S:=IntToStr(i)+' :';
           S:=S+String(pV.V);
           Memo2.Lines.Add(S);
        end;
      end;

      Memo2.Lines.Add('');
      Memo2.Lines.Add('FUNCTION INSTRUCTIONS:');
      Memo2.Lines.Add('=====================');
      Lst:=LuaFunction.PrintBinary; //--- test listing print
      for i:=0 to Lst.Count-1 do begin
          Memo2.Lines.Add(Lst.Strings[i]);
      end;
      Lst.Free;
    {$ENDIF}
end;

//--------------------------------------------
// Try to Execute Script
procedure TForm1.btnExecScriptClick(Sender: TObject);
var
  iErr:integer;
  S:String;
  xNameSpace:TNameSpaceInfo;
begin
    if(ByteCodeProto <> NIL)then begin

      if(ByteCodeProto.NameSpace = NIL)then begin
         xNameSpace:=TNameSpaceInfo.Create;
         xNameSpace.CtrlForm:=Self;
         ByteCodeProto.NameSpace:=xNameSpace;
      end;         

      LuaInter.OnHandleGlobals:=ResolveLuaGlobalsForActiveForm;
      iErr:=0;

      S:=ByteCodeProto.Execute(iErr);
      if(iErr < 0)then begin
          MessageBox(GetActiveWindow,PChar(S),'EXECUTION ERROR',MB_ICONINFORMATION);
      end;
    end;
end;



//----------------------------------------------------------------------------------------
// LUA GLOBAL Vars Handler.
// Globals treated here as Controls on some form and searched by name.
// Form where to search controls can be specified as NameSpace property of TByteCodeProto
// from where this function is called. So different TByteCodeProto classes can belongs to
// different forms and no control names conflicts appears.
//
// The following Operation parameter values available:
//  OP_GETGLOBAL - find control by its name and return it's address
//  OP_GETTABLE  - Get Property of object by Property name
//  OP_SETTABLE  - Set Property of object by Property name
//
// Params depending on operation:
//--------------------------------
// OP_GETGLOBAL:
//   pV1.V - string containing Global - Control Name to find on form. Form can be a "NameSpace" prop. of xByteCodeProto
//   Result:
//  pV2.Ptr - pointer to finded global
// OP_GETTABLE:
// OP_SETTABLE:
//   pV1.Ptr - pointer to object
//   pV2.V   - string containing Property Name to fetch
//   Result:
//   pV3.V    - Property Value for non object properties
//or pV3.Ptr  - If Property is Object - pointer to object
//
//$VSMAY2004: Now we take form attached to lua ByteCode from NameSpace of this ByteCode
//----------------------------------------------------------------------------------------
function TForm1.ResolveLuaGlobalsForActiveForm(xByteCodeProto:TObject;Operation:LUA_OPCODES;pV1,pV2,pV3:TXVariant):integer;
var
  xComponent:TComponent;
  GetSetCmd:char;
  xObject:TObject;
  VarValue:Variant;
  PropIsObject:boolean;
  r:Real;
  xSearchForm:TForm;
begin
   GetSetCmd:='G';

   Result:=0;

   if((xByteCodeProto <> Nil) and (TByteCodeProto(xByteCodeProto).NameSpace <> Nil))then begin
      //---- Take form attached to lua ByteCode from NameSpace ----
      xSearchForm:=TForm(TByteCodeProto(xByteCodeProto).NameSpace.CtrlForm);
   end else begin
      xSearchForm:=Self; //CurrentState.CurrentForm;
   end;


   case Operation of

     //-- Find object by name (in pV1) and
     //-- return it's address into pV2
     OP_GETGLOBAL:
      begin
           if(TVarData(pV1.V).VType <> varString)then begin
              raise Exception.Create('External Object name is invalid.');
           end;

           //--- Here when we work under debugger - it's form is active - so can't find Component ------
           xComponent:=LC_FindComponentByName(xSearchForm{Screen.ActiveForm},String(pV1.V));
           if(xComponent = Nil)then begin
             raise Exception.Create('Can''t find Object with name:'+String(pV1.V));
           end;
           pV2.Ptr:=xComponent;
      end;

     //-- For OP_GETTABLE assign property of object to pV3 value
     //-- For OP_SETTABLE assign pV3 value to property of object.
     //-- pV1:Pointer to object,pV2- property name or index,pV3-Local or constant (string or numeric)
     OP_GETTABLE,OP_SETTABLE:
      begin
           if(Operation = OP_SETTABLE)then begin
               GetSetCmd:='S'; //-- indicate Set property operation. Default is 'G'- get property
           end;

           //--- Check parameter pV1 - must be object refference --------
           if(NOT pV1.IsObject)then begin
              raise Exception.Create('Invalid External Object refference.');
           end;

           //--- Check parameter pV2 - must be String (property name) --------
           if(TVarData(pV2.V).VType <> varString)then begin
              raise Exception.Create('Property Name is not String.');
           end;

           //--- Get Object as pointer saved in variant -------
           xObject:=TObject(pV1.Ptr);


           try
             //--- Try to Get/Set property ---------------
             if(GetSetCmd = 'S')then begin
               if(pV3.IsObject)then begin
                 //--- If our TXVariant is pointer
                 //--- Save it as Ord value (integer) in variant
                 VarValue:=integer(pV3.Ptr);
               end else begin
                 VarValue:=pV3.V;
               end;
             end;

             //if(xObject is TApplication)then begin
             //  if(Not UC_GetSetPropAsVariant(GetSetCmd,TApplication_Published(xObject),String(pV2.V),VarValue,PropIsObject))then begin
             //     raise Exception.Create('Property "'+String(pV2.V)+'" not found.');
             //  end;
             //  Exit;
             //end;
             //CustObject(xObject);

             if(Not LC_GetSetPropAsVariant(GetSetCmd,xObject,String(pV2.V),VarValue,PropIsObject))then begin
                Result:=0;
                Exit;
                //raise Exception.Create('Property "'+String(pV2.V)+'" not found.');
             end;

             if(GetSetCmd = 'G')then begin
               if(PropIsObject)then begin
                 //--- If property is pointer to object ----
                 //--- Save it in Pointer part of TXVariant
                 pV3.Ptr:=Pointer(integer(VarValue));
               end else begin
                 //--- Else save as variant ---
                 pV3.V:=VarValue;
                 if(pV3.VarType = varInteger)then begin
                    r:=pV3.V; //-- Convert to Real because all Lua numbers are Real
                    pV3.V:=r;
                 end;
               end;
             end;
             Result:=1;
           except
              //-- Handle internal error occured while Get/Set property
              //raise  Exception.Create('Internal Error on Property "'+String(pV2.V)+'"');
              Result:=-1; //-- indicate internal error on get/set property
           end;
      end;

   end; //-- case
end;


//-----------------------------------------------------
// Show/Hide debugger
//-----------------------------------------------------
procedure  DelObjX(xObj:TObject);
begin
   xObj.Destroy;
end;

//------------------------------------------------
// Test button click
//------------------------------------------------
procedure TForm1.Button1Click(Sender: TObject);
var
  xLst:TStringList;
  i:integer;
  //S:String;
begin
  if(LC_GetSetOrdPropValue('G',Sender,'OnClick',i))then begin
      Memo1.Lines.Add('OnClick EXISTS');
  end;
  xLst:=TStringList.Create;
  GetListOfMethods(Sender,xLst);
  for i:=0 to xLst.Count-1 do begin
     Memo1.Lines.Add(xLst.Strings[i]);
  end;
  xLst.Free;
end;


//-----------------------------------------------------
// Test of user defined lua function
// Show Message Box
//-----------------------------------------------------
function TForm1.LuaMessageBox(Params:TList):integer;
begin
    MessageBox(HWND(Nil),Pchar(String(TXVariant(Params.Items[0]).V)),
                               Pchar(String(TXVariant(Params.Items[1]).V)),MB_ICONINFORMATION);
    Result:=0;
end;

//-----------------------------------------------------
// Register all available LUA packages
//-----------------------------------------------------
procedure TForm1.RegisterLuaGlobals(xByteCodeProto:TByteCodeProto);
begin
      //--- Register internal function(s) -----------
      xByteCodeProto.RegisterGlobalFunction('MyMessageBox',LuaMessageBox);   //-- some internal function for test

      //--- Register Global vars ---------------
      xByteCodeProto.RegisterGlobalVar('Application',Application);
      xByteCodeProto.RegisterGlobalVar('CurrentForm',Self);

      //---- Set some variable for test it during lua func. execution ---
      xByteCodeProto.RegisterGlobalVar('EventName',Nil);
      SetLuaGlobal('EventName','Execute');
end;

end.
