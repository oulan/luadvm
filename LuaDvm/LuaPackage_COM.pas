unit LuaPackage_COM;
interface

uses  Windows, Messages, SysUtils,Classes,ActiveX,ComObj,
      LUaInter; //, oleauto;


 //--------------------------------------------------------------------
 // Pachage Class for collect some general purpose functions
 //--------------------------------------------------------------------
 type Package_COM=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function pckg_Create(Params:TList): Integer;
    function pckg_OleCall(Params:TList): Integer;
    function pckg_OlePropGet(Params:TList): Integer;
    function pckg_OlePropSet(Params:TList): Integer;
    function pckg_GetDispInformation(Params:TList): Integer;
    function pckg_AddRef(Params:TList): Integer;
    function pckg_Release(Params:TList): Integer;
   public
    procedure RegisterFunctions;override;
 end;



 //------ Wrapper Object for IEnumVariant interface
 //------ IEnumVariant not a IDispatch - just IUnknown - so we need wrapper for use it
 //------ along with IDispatch methods. Interface IEnumVariant described in OLE2.PAS
 type TIEnumVariant=class(TPersistent,IEnumVariant)
   private
    xEnum:IEnumVariant;

   public
     constructor Create(iface:IUnknown);
     destructor  Destroy;override;

     //--- Wrap Methods of IEnumVariant ------
     function Next(celt: LongWord; var rgvar : OleVariant;out pceltFetched: LongWord): HResult; stdcall;
     function Skip(celt: LongWord): HResult; stdcall;
     function Reset: HResult; stdcall;
     function Clone(out Enum: IEnumVariant): HResult; stdcall;

     //--- Wrap Methods of IEnumVariant ------
     function _AddRef: Integer; virtual; stdcall;
     function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
     function _Release: Integer; virtual; stdcall;

 end;

 //---- LUA Wrapper for above object for use IEnumVariant from LUA ----
 type Package_TIEnumVariant=class(TLuaPackage)
     function pckg_Create(Params:TList): Integer;
     function pckg_Next(Params:TList): Integer;
     function pckg_Skip(Params:TList): Integer;
     function pckg_Reset(Params:TList): Integer;
     function pckg_Clone(Params:TList): Integer;

   public
    procedure RegisterFunctions;override;
 end;

{////////////////////////////////////////////////////////////////
Name of unit: DispatchLib
Purpose of unit:
    Exposes function to manipulate COM objects that implement
    IDispatch interface.
    You can call methods or properties directly or you can
    list all the functions to a TStringList object.

    An example:

    procedure fa(sl: TStringList);
    var
        a: variant;
        s: string;
    begin
        a := CreateOLEObject("microsoft.msxml");
        DocumentIDispatch(a, sl);
        ExecuteOnDispatchMultiParam(a, "loadxml", ["b"]);
        s := ExecuteOnDispatchMultiParam(a, "xml", []);
        MessageDlg(s, mtInformation, [mbOk], 0);
    end;

    Code is based on a unit I found on the internet, but it contained
    some serious bugs and it didn't support more than one parameter.

Anything unusual:
Coded by: VJ
Date: 17.07.2001
Revision history:
////////////////////////////////////////////////////////////////}

type

  exMethodNotSupported = class(Exception);
  exIDispatchCallError = class(Exception);

//function ExecuteOnDispatchMultiParam(TargetObj: IDispatch; MethodName: string; ParamValues: array of const): OleVariant;
function ExecuteOnDispatchMultiParamList(ParamsList:TList;CallType:Word): OleVariant;
procedure DocumentIDispatch(ID: IDispatch; var SL: TStringList);
procedure DocumentIDispatch2(ID: IDispatch; var SLNames: TStringList);

function ElementDescriptionToString(a: TElemDesc): string;
procedure SetOleParamByTable(pVarArg:PVariantArgList;Idx:integer;ParamDescrTbl:TLuaTable);

//---------------------------------------------------------
// Global Instances of above Packages-Classes
//---------------------------------------------------------
var
  //-- Package Instances (created in Initialization section)
  PACK_COM:Package_COM;
  LUA_COM_INITITALIZED:boolean;
  OleTypesStringList:TStringList;
  PACK_IENUMVARIANT:Package_TIEnumVariant;

///////////////////////////////////////////
implementation

//----------------------------------------------------------------
// COM Class package.
// Implements Creation of COM objects and collects some methods
//----------------------------------------------------------------
procedure Package_COM.RegisterFunctions;
begin
  Methods.AddObject('Create',TUserFuncObject.CreateWithName('Create',pckg_Create));
  Methods.AddObject('AddRef',TUserFuncObject.CreateWithName('AddRef',pckg_AddRef));
  Methods.AddObject('Release',TUserFuncObject.CreateWithName('Release',pckg_Release));
  Methods.AddObject('GetDispInformation',TUserFuncObject.CreateWithName('GetDispInformation',pckg_GetDispInformation));
  Methods.AddObject('OleCall',TUserFuncObject.CreateWithName('OleCall',pckg_OleCall));
  Methods.AddObject('OlePropGet',TUserFuncObject.CreateWithName('OlePropGet',pckg_OlePropGet));
  Methods.AddObject('OlePropSet',TUserFuncObject.CreateWithName('OlePropSet',pckg_OlePropSet));

  HandledProps:=TStringList.Create; //--- only for show that it is Class package
end;

//---------------------------------------------------------
// Create with file name
//---------------------------------------------------------
function Package_COM.pckg_Create(Params:TList): Integer;
var
 ObjID:String;
 IxObj:IDispatch;
 //IxObj:IUnknown;
begin
  if(NOT LUA_COM_INITITALIZED)then begin
     CoInitialize(NIL);
     LUA_COM_INITITALIZED:=true;
  end;
  Result:=0;
  ObjID:=String(TXVariant(Params.Items[0]).V);
  IxObj:=CreateOLEObject(ObjID);
  TXVariant(Params.Items[0]).V:=IxObj; //-- save as IDispatch
end;


//---------------------------------------------------------
// Call To OLE Dispatch method by it's name
// Params:
//  0 - Method Name:String
//  1 - TXVariant with value IDispatch
// .. - Call Parameters
//---------------------------------------------------------
function Package_COM.pckg_OleCall(Params:TList): Integer;
var
 MethodResult:OleVariant;
begin
  Result:=0;
  //MethodName:=TXVariant(Params.Items[0]).V;
  //Interf:=IDispatch(TXVariant(Params.Items[1]).V);

  MethodResult:=ExecuteOnDispatchMultiParamList(Params,DISPATCH_METHOD or DISPATCH_PROPERTYGET); // ParamValues: array of const): OleVariant;
  TXVariant(Params.Items[1]).V:=MethodResult; //--- return result back
end;



//---------------------------------------------------------
// Call To OLE Dispatch method by it's name
// Params:
//  0 - input Method Name:String, output - Property value (method result)
//  1 - TXVariant with value IDispatch
// .. - Call Parameters
//---------------------------------------------------------
function Package_COM.pckg_OlePropGet(Params:TList): Integer;
var
 MethodResult:OleVariant;
begin
  Result:=0;
  MethodResult:=ExecuteOnDispatchMultiParamList(Params,DISPATCH_PROPERTYGET); // ParamValues: array of const): OleVariant;
  TXVariant(Params.Items[0]).V:=MethodResult; //--- return result back
end;


//---------------------------------------------------------
// Call To OLE Dispatch method by it's name
// Params:
//  0 - Method Name:String
//  1 - TXVariant with value IDispatch
// .. - Call Parameters
//---------------------------------------------------------
function Package_COM.pckg_OlePropSet(Params:TList): Integer;
var
 MethodResult:OleVariant;
begin
  Result:=0;
  //MethodName:=TXVariant(Params.Items[0]).V;
  //Interf:=IDispatch(TXVariant(Params.Items[1]).V);

  MethodResult:=ExecuteOnDispatchMultiParamList(Params,DISPATCH_PROPERTYPUT or DISPATCH_METHOD); // ParamValues: array of const): OleVariant;
  // TXVariant(Params.Items[1]).V:=MethodResult; //--- return result back
end;



//----------------------------------------------------------------------
// Return Info about IDispatch interface to specified stringlist
// example:
//  _COM.GetDispInformation(IDispatch,StringList);
//
// NOTE: because of Dispatch specific you can't call this function as
// MyIDispatchOBject:GetDispInformation(StringList); - because of in this case
// method "GetDispInformation" of object "MyIDispatchOBject" being tried to call.
//----------------------------------------------------------------------
function Package_COM.pckg_GetDispInformation(Params:TList): Integer;
var
  xDisp:IDispatch;
  xSList:TStringList;
begin
  xDisp:=IDispatch(TXVariant(Params.Items[0]).V);
  xSList:=TStringList(TXVariant(Params.Items[1]).Ptr);
  DocumentIDispatch(xDisp,xSList);
  Result:=0;
end;



//-------- Other COM functions ------------------------

function ElementDescriptionToString(a: TElemDesc): string;
begin
  case a.tdesc.vt of
    VT_I4: Result := 'int';
    VT_R8: Result := 'double';
    VT_BSTR: Result := 'string';
  else
    Result := '';
  end;
end;


//---------------------------------------------------------
// Function for obtain Information about IDispatch
//
//---------------------------------------------------------
procedure DocumentIDispatch(ID: IDispatch; var SL: TStringList);
var
  res: HResult;
  Count, loop, loop2, loop3: integer;
  TI: ITypeinfo;
  pTA: PTypeAttr;
  pFD: PFuncDesc;
  varDesc: pVarDesc;
  numFunctions: integer;
  numParams: integer;
  funcDispID: integer;
  names: TBStrList;
  numReturned: integer;
  functionstr: widestring;
  hide: boolean;
begin
  assert(SL <> nil, 'SL may not be nil');
  SL.Clear;

  res := ID.GetTypeInfoCount(Count);
  if succeeded(res) then begin
    for loop := 0 to Count - 1 do begin
      res := ID.GetTypeInfo(loop, 0, TI);
      if succeeded(res) then begin
        res := TI.GetTypeAttr(pTA);
        if succeeded(res) then begin
          if pTA^.typekind = TKIND_DISPATCH then begin
            numFunctions := pTA^.cFuncs;
            for loop2 := 0 to numFunctions - 1 do begin
              res := TI.GetFuncDesc(loop2, pFD);
              if succeeded(res) then begin
                funcDispID := pFD^.memid;
                numParams := pFD^.cParams;
                res := TI.GetNames(funcDispID, @names, numParams + 1, numReturned);
                if succeeded(res) then begin
                  functionstr := '';
                  if numReturned > 0 then
                    functionstr := functionstr + names[0];

                  if numReturned > 1 then begin
                    functionstr := functionStr + '(';
                    for loop3 := 1 to numReturned - 1 do begin
                      if loop3 > 1 then
                        functionstr := functionstr + ', ';
                      functionstr :=
                        functionstr +
                        names[loop3] + ':' +
                        ElementDescriptionToString(pFD^.lprgelemdescParam^[loop3 - 1]);
                    end;

                    //functionstr := functionstr + names[numReturned - 1] + ')';
                    functionstr := functionstr + ')';
                  end;
                  hide := False;

                  // Hides the non-dispatch functions
                  if (pFD^.wFuncFlags and FUNCFLAG_FRESTRICTED) = FUNCFLAG_FRESTRICTED then
                    hide := True;

                  // Hides the functions not intended for scripting: basically redundant functions
                  if (pFD^.wFuncFlags and FUNCFLAG_FHIDDEN) = FUNCFLAG_FHIDDEN then
                    hide := True;

                  if not hide then
                    SL.add(functionstr);
                end;

                TI.ReleaseFuncDesc(pFD);
              end;
            end;
          end;
          TI.ReleaseTypeAttr(pTA);
        end;
      end;
    end;
  end
  else
    raise Exception.Create('GetTypeInfoCount Failed');
end;

//---------------------------------------------------------
// Function for obtain Information about IDispatch
//
//---------------------------------------------------------
procedure DocumentIDispatch2(ID: IDispatch; var SLNames: TStringList);
var
  res: HResult;
  Count, loop, loop2, loop3: integer;
  TI: ITypeinfo;
  pTA: PTypeAttr;
  pFD: PFuncDesc;
  varDesc: pVarDesc;
  numFunctions: integer;
  numParams: integer;
  funcDispID: integer;
  names: TBStrList;
  numReturned: integer;
  functionstr: widestring;
  hide: boolean;
begin
  SLNames.Clear;

  res := ID.GetTypeInfoCount(Count);
  if succeeded(res) then begin
    for loop := 0 to Count - 1 do begin
      res := ID.GetTypeInfo(loop, 0, TI);
      if succeeded(res) then begin
        res := TI.GetTypeAttr(pTA);
        if succeeded(res) then begin
          if pTA^.typekind = TKIND_DISPATCH then begin
            numFunctions := pTA^.cFuncs;
            for loop2 := 0 to numFunctions - 1 do begin
              res := TI.GetFuncDesc(loop2, pFD);
              if not succeeded(res) then
                Continue;

              funcDispID := pFD^.memid;
              numParams := pFD^.cParams;
              res := TI.GetNames(funcDispID, @names, numParams + 1, numReturned);

              if not succeeded(res) then begin
                TI.ReleaseFuncDesc(pFD);
                Continue;
              end;

              // Hides the non-dispatch functions
              if (pFD^.wFuncFlags and FUNCFLAG_FRESTRICTED) = FUNCFLAG_FRESTRICTED then
                Continue;

              // Hides the functions not intended for scripting: basically redundant functions
              if (pFD^.wFuncFlags and FUNCFLAG_FHIDDEN) = FUNCFLAG_FHIDDEN then
                Continue;

              functionstr := '';
              if numReturned > 0 then begin
                functionstr := functionstr + names[0];
              end;

              functionstr := functionstr + '(';
              if numReturned > 1 then begin
                for loop3 := 1 to numReturned - 1 do begin
                  if loop3 > 1 then
                    functionstr := functionstr + ',';
                  functionstr :=
                    functionstr +
                    ElementDescriptionToString(pFD^.lprgelemdescParam^[loop3 - 1]);
                end;
              end;
              SLNames.Add(functionstr + ')');
              TI.ReleaseFuncDesc(pFD);

            end;
          end;
          TI.ReleaseTypeAttr(pTA);
        end;
      end;
    end;
  end
  else
    raise Exception.Create('GetTypeInfoCount Failed');
end;

(*
{////////////////////////////////////////////////////////////////
Name: ExecuteOnDispatchMultiParam
Purpose:
    To execute arbitrary method on given COM object.
Author: VJ
Date: 07.07.2001
History:
////////////////////////////////////////////////////////////////}

function ExecuteOnDispatchMultiParam(
  TargetObj: IDispatch;
  MethodName: string;
  ParamValues: array of const): OleVariant;
var
  wide: widestring;
  disps: TDispIDList;
  panswer: ^olevariant;
  answer: olevariant;
  dispParams: TDispParams;
  aexception: TExcepInfo;
  pVarArg: PVariantArgList;
  res: HResult;
  ParamCount, i: integer;
begin
  Result := false;

  // prepare for function call
  ParamCount := High(ParamValues) + 1;
  wide := MethodName;
  pVarArg := nil;
  if ParamCount > 0 then
    GetMem(pVarArg, ParamCount * sizeof(TVariantArg));

  try
    // get dispid of requested method
    if not succeeded(TargetObj.GetIDsOfNames(GUID_NULL, @wide, 1, 0, @disps)) then
      raise exMethodNotSupported.Create('This object does not support this method');
    pAnswer := @answer;

    // prepare parameters
    for i := 0 to ParamCount - 1 do begin
      case ParamValues[ParamCount - 1 - i].VType of
        vtInteger: begin
            pVarArg^[i].vt := VT_I4;
            pVarArg^[i].lVal := ParamValues[ParamCount - 1 - i].VInteger;
          end;
        vtExtended: begin
            pVarArg^[i].vt := VT_R8;
            pVarArg^[i].dblVal := ParamValues[ParamCount - 1 - i].VExtended^;
          end;
        vtString, vtAnsiString, vtChar: begin
            pVarArg^[i].vt := VT_BSTR;
            pVarArg^[i].bstrVal := PWideChar(WideString(PChar(ParamValues[ParamCount - 1 - i].VString)));
          end;
      else
        raise Exception.CreateFmt('Unsuported type for parameter with index %d', [i]);
      end;
    end;

    // prepare dispatch parameters
    dispparams.rgvarg := pVarArg;
    dispparams.rgdispidNamedArgs := nil;
    dispparams.cArgs := ParamCount;
    dispparams.cNamedArgs := 0;

    // make IDispatch call
    res := TargetObj.Invoke(disps[0],
      GUID_NULL, 0, DISPATCH_METHOD or DISPATCH_PROPERTYGET,
      dispParams, pAnswer, @aexception, nil);

    // check the result
    if res <> 0 then
      raise exIDispatchCallError.CreateFmt(
        'Method call unsuccessfull. %s (%s).',
        [string(aexception.bstrDescription), string(aexception.bstrSource)]);

    // return the result
    Result := answer;
  finally
    if ParamCount > 0 then
      FreeMem(pVarArg, ParamCount * sizeof(TVariantArg));
  end;
end;
*)
//-----------------------------------------------------------------------------------------
// Call by Params List - list of TXVariant Objects
// NOTE: First 2- parameters are: "MethodName" and Pointer to IDispatch object,
// other - parameters of callable method.
//-----------------------------------------------------------------------------------------
function ExecuteOnDispatchMultiParamList(ParamsList:TList;CallType:Word): OleVariant;
var
  wide: widestring;
  disps: TDispIDList;
  panswer: ^olevariant;
  answer: olevariant;
  dispParams: TDispParams;
  aexception: TExcepInfo;
  pVarArg: PVariantArgList;
  res: HResult;
  ParamCount, i: integer;
  xParam:TXVariant;

  TargetObj: IDispatch;
  MethodName: string;
  ParamIdx:integer;
  //InvokeFlags:Word;
  ParamDescrTable:TLuaTable;
  dispidNamed:TDISPID;

begin
  Result := 0;

  dispidNamed:=DISPID_PROPERTYPUT; //-- needs only for PutProperty

  //-------- First Parameter always contains Ole Method name ---------
  MethodName:=TXVariant(ParamsList.Items[0]).V;

  //-------- Second Parameter always contains IDispatch of Ole object --------
  TargetObj:=IDispatch(TXVariant(ParamsList.Items[1]).V);

  // prepare for function call
  ParamCount := ParamsList.Count-2;
  wide := MethodName;
  pVarArg := nil;

  //-- Allocate mem for array or TVariantArg records ---
  if(ParamCount > 0)then begin
    GetMem(pVarArg, ParamCount * sizeof(TVariantArg));
  end;

  try
    //---- get dispid of requested method
    if(not succeeded(TargetObj.GetIDsOfNames(GUID_NULL, @wide, 1, 0, @disps))) then begin
      raise exMethodNotSupported.Create('This object does not support this method');
    end;
    pAnswer := @answer;

    //---- prepare parameters
    for i := 0 to ParamCount - 1 do begin
      //--- NOTE: paramters for IDispatch Invoke MUST GOES in BACKWORD ORDER!!!!
      //--- Ohhh- Ms-CRAZY!!! I spent more than week for realize this!!!
      ParamIdx:=ParamCount-i-1;

      pVarArg^[ParamIdx].vt:=0;
      pVarArg^[ParamIdx].dblVal:=0; //--- Clear Variant

      xParam:=TXVariant(ParamsList.Items[i+2]);  //-- +2 because first 2 Items of ParamList are IDispatch and Method name

      //-- If xParam is refference to another Variant Object - get it's value ----
      if(xParam.IsObject and (xParam.Ptr <> NullPtrObject))then begin
        if(TObject(xParam.Ptr) is TXVariant)then begin
          xParam:=TXVariant(xParam.Ptr);  //--- get indirect variable ----
        end else if(TObject(xParam.Ptr) is TLuaTable)then begin
          //------- Special kind of param description: TLuaTable for example:
          //--- Obj:Method({ppDisp=SomeObject,Out=true},{Date="12may2005"}); -- here ppDisp and Date are keywords of table
          ParamDescrTable:=TLuaTable(TObject(xParam.Ptr));
          SetOleParamByTable(pVarArg,ParamIdx,ParamDescrTable);
          //------ Delete temporary param description table ------
          //....
          //---- First Delete Info about table from Owners list ---
          if(ParamDescrTable.TableOwnerList <> Nil)then begin
             if(ParamDescrTable.TableOwnerList.Items[ParamDescrTable.OwnerListIdx] = ParamDescrTable)then begin
                  ParamDescrTable.TableOwnerList.Items[ParamDescrTable.OwnerListIdx]:=NIL; //--- Delete reference to table
             end;
          end;

          ParamDescrTable.Free; //-- Delete table itself

          continue;
        end;
      end;

      //--- Special case - NULL as parameter ----
      if(xParam.Ptr = NullPtrObject)then begin

           // pVarArg^[i].vt:=VT_BYREF or VT_DISPATCH;
           // pVarArg^[i].dispVal:=0;//NIL;

            //pVarArg^[i].vt:=VT_BYREF;
            //pVarArg^[i].byRef:=NIL;//NIL;

            pVarArg^[ParamIdx].vt:=VT_ERROR; //--- indicate NULL as ommitted parameter
            pVarArg^[ParamIdx].scode:=DISP_E_PARAMNOTFOUND;

      end else begin
          //------- Handle parameters by Default types: String, Double, Integer
          //------- other must be used as LuaTable {pDisp=xxIIdidid}
          case xParam.VarType  of

            varInteger: begin
                pVarArg^[ParamIdx].vt:=VT_I4;
                pVarArg^[ParamIdx].lVal:=xParam.V;
              end;

            varDouble: begin
                pVarArg^[ParamIdx].vt:=VT_R8;
                pVarArg^[ParamIdx].dblVal:=xParam.V;
              end;
            varDispatch: begin
                pVarArg^[ParamIdx].vt:=VT_DISPATCH;
                pVarArg^[ParamIdx].dispVal:=Pointer(IDispatch(xParam.V));
              end;

            varString: begin
                pVarArg^[ParamIdx].vt := VT_BSTR;
                pVarArg^[ParamIdx].bstrVal :=PWideChar(WideString(PChar(String(xParam.V))));
              end;
          else
            raise Exception.CreateFmt('Unsuported type for parameter with index %d', [i]);
          end;
      end;
    end; //--- For all parameters ------

    //----- prepare to dispatch call ------------
    dispparams.rgvarg := pVarArg;
    dispparams.rgdispidNamedArgs := nil;
    dispparams.cArgs := ParamCount;
    dispparams.cNamedArgs := 0;


    if((CallType and DISPATCH_PROPERTYPUT) <> 0)then begin
      dispparams.cNamedArgs := 1;
      dispparams.rgdispidNamedArgs:=@dispidNamed;
    end;


//    if(PropGet)then begin
//        InvokeFlags:=DISPATCH_PROPERTYGET;
//    end else begin
//       InvokeFlags:=DISPATCH_METHOD or DISPATCH_PROPERTYGET;
//    end;

    //---------- make IDispatch Invoke call
    res := TargetObj.Invoke(disps[0],
                            GUID_NULL, 0, CallType,
                            dispParams, pAnswer, @aexception, nil);

    //-------- check the result -----------
    if(res <> 0)then begin
      raise exIDispatchCallError.CreateFmt(
        'OLE Method call unsuccessfull (code:%d,0x%x) %s (%s).',
        [res,res,string(aexception.bstrDescription), string(aexception.bstrSource)]);
    end;

    //---- return the result
    Result := answer;
  finally
    //---- Free parameter memory --------
    if(ParamCount > 0) then begin
      //---- Delete All temp. tables ------

      //---- Bstr generated --------


      //---- Finally - release memory obtained for params array ----
      FreeMem(pVarArg, ParamCount * sizeof(TVariantArg));

    end;
  end;
end;


//=====================================================================================
// Get OLE parameter description from Table as Key=value and convert it to valid value
//=====================================================================================
procedure  SetOleParamByTable(pVarArg:PVariantArgList;Idx:integer;ParamDescrTbl:TLuaTable);
var
  xSLst:TStringList;
  StrIdx:integer;
  FlagVal:integer;
  S:String;
  i:integer;
  V1:TxVariant;
begin
    xSLst:=ParamDescrTbl.sList;
    if((xSLst = Nil) or (xSLst.Count = 0))then begin
        Exit;
    end;

    for i:=0 to xSLst.Count-1 do begin
       S:=xSLst.Strings[i];
       //-- Check for known keywords like "In=true" -----
       if((S <> 'In') and (S <> 'Out') and (S <> 'InOut'))then begin
           if(OleTypesStringList.Find(S,StrIdx))then begin
                FlagVal:=Integer(OleTypesStringList.Objects[StrIdx]);

                V1:=TxVariant(xSLst.Objects[i]); //--- get variant itself.Can be Value or pointer

                pVarArg^[Idx].vt:=FlagVal;

                case FlagVal of
                  VT_UI1:
                     begin
                       //---   (bVal: Byte);
                       pVarArg^[Idx].bVal:=Byte(Integer(V1.V));
                     end;
                  VT_I2:
                     begin
                       //---   (iVal: Smallint);
                       pVarArg^[Idx].iVal:=Integer(V1.V);
                     end;
                  VT_I4:
                     begin
                       //---  (lVal: Longint);
                       pVarArg^[Idx].lVal:=Integer(V1.V);
                     end;
                  VT_R4:
                     begin
                       //---   (fltVal: Single);
                       pVarArg^[Idx].fltVal:=Single(V1.V);
                     end;
                  VT_R8:
                     begin
                       //---   (dblVal: Double);
                       pVarArg^[Idx].dblVal:=Double(V1.V);
                     end;
                  VT_BOOL:
                     begin
                       //---  (vbool: TOleBool);
                       pVarArg^[Idx].vbool:=TOleBool(Boolean(V1.V));
                     end;
                  VT_ERROR:
                     begin
                       //---   (scode: HResult);
                       pVarArg^[Idx].scode:=Integer(V1.V);
                     end;
                  VT_CY:
                     begin
                       //---   (cyVal: Currency);
                     end;
                  VT_DATE:
                     begin
                       //---   (date: TOleDate);
                       if(V1.VarType = varString)then begin
                           pVarArg^[Idx].date:=StrToDate(String(V1.V));
                       end else begin
                           pVarArg^[Idx].date:=double(V1.V);
                       end;

                     end;
                  VT_BSTR:
                     begin
                        //---   (bstrVal: PWideChar{WideString});
                         pVarArg^[Idx].bstrVal:=PWideChar(WideString(PChar(String(V1.V))));
                     end;
                  VT_UNKNOWN:
                     begin
                       //---   (unkVal: Pointer{IUnknown});
                       pVarArg^[Idx].unkVal:=Pointer(Integer(V1.V));
                     end;
                  VT_DISPATCH:
                     begin
                       //---   (dispVal: Pointer{IDispatch});
                       if(V1.Ptr = NullPtrObject)then begin
                          pVarArg^[Idx].dispVal:=Pointer(0);
                       end else begin
                          pVarArg^[Idx].dispVal:=Pointer(Integer(V1.V));
                       end;
                     end;
                  VT_ARRAY:
                     begin
                       //---   (parray: PSafeArray);  ???
                     end;
                  VT_BYREF or VT_UI1:
                     begin
                       //---   (pbVal: ^Byte);
                     end;
                  VT_BYREF or VT_I2:
                     begin
                       //---   (piVal: ^Smallint);
                     end;
                  VT_BYREF or VT_I4:
                     begin
                       //---   (plVal: ^Longint);
                     end;
                  VT_BYREF or VT_R4:
                     begin
                       //---   (pfltVal: ^Single);
                     end;
                  VT_BYREF or VT_R8:
                     begin
                       //---   (pdblVal: ^Double);
                     end;
                  VT_BYREF or VT_BOOL:
                     begin
                       //---   (pbool: ^TOleBool);
                     end;
                  VT_BYREF or VT_ERROR:
                     begin
                       //---   (pscode: ^HResult);
                     end;
                  VT_BYREF or VT_CY:
                     begin
                       //---   (pcyVal: ^Currency);
                     end;
                  VT_BYREF or VT_DATE:
                     begin
                       //---   (pdate: ^TOleDate);
                     end;
                  VT_BYREF or VT_BSTR:
                     begin
                       //---   (pbstrVal: ^WideString);
                     end;
                  VT_BYREF or VT_UNKNOWN:
                     begin
                       //---   (punkVal: ^IUnknown);
                     end;
                  VT_BYREF or VT_DISPATCH:
                     begin
                       //---   (pdispVal: ^IDispatch);
                       if(V1.Ptr = NullPtrObject)then begin
                          pVarArg^[Idx].pdispVal:=Pointer(0);
                       end else begin
                          pVarArg^[Idx].pdispVal:=Pointer(Integer(V1.V));
                       end;
                     end;
                  VT_BYREF or VT_ARRAY:
                     begin
                       //---   (pparray: ^PSafeArray);
                     end;
                  VT_BYREF or VT_VARIANT:
                     begin
                       //---   (pvarVal: PVariant);
                     end;
                  VT_BYREF:
                     begin
                       //---   (byRef: Pointer);
                     end;
                  VT_I1:
                     begin
                       //---   (cVal: Char);
                     end;
                  VT_UI2:
                     begin
                       //---   (uiVal: Word);
                     end;
                  VT_UI4:
                     begin
                       //---   (ulVal: LongWord);
                     end;
                  VT_INT:
                     begin
                       //---   (intVal: Integer);
                     end;
                  VT_UINT:
                     begin
                       //---   (uintVal: LongWord);
                     end;
                  VT_BYREF or VT_DECIMAL:
                     begin
                       //---   (pdecVal: PDecimal);
                     end;
                  VT_BYREF or VT_I1:
                     begin
                       //---   (pcVal: PChar);
                     end;
                  VT_BYREF or VT_UI2:
                     begin
                       //---  (puiVal: PWord);
                     end;
                  VT_BYREF or VT_UI4:
                     begin
                       //---   (pulVal: PInteger);
                     end;
                  VT_BYREF or VT_INT:
                     begin
                       //---   (pintVal: PInteger);
                     end;
                  VT_BYREF or VT_UINT:
                     begin
                       //---   (puintVal: PLongWord);
                     end;
              end;







           end;
       end;
    end;


end;

//---------------------------------------------
constructor TIEnumVariant.Create(iface:IUnknown);
begin
    Inherited Create;
    xEnum:=iface as IEnumVariant;
end;

//---------------------------------------------
destructor TIEnumVariant.Destroy;
begin
   //xEnum._Release;
   Inherited Destroy;
end;

//---------------------------------------------
function TIEnumVariant.Next(celt: LongWord; var rgvar : OleVariant;out pceltFetched: LongWord): HResult; stdcall;
begin
  Result:=xEnum.Next(celt,rgvar,pceltFetched);
end;

//---------------------------------------------
function TIEnumVariant.Skip(celt: LongWord): HResult; stdcall;
begin
 Result:=xEnum.Skip(celt);
end;

//---------------------------------------------
function TIEnumVariant.Reset: HResult; stdcall;
begin
 Result:=xEnum.Reset;
end;

//---------------------------------------------
function TIEnumVariant.Clone(out Enum: IEnumVariant): HResult; stdcall;
begin
 Result:=xEnum.Clone(Enum);
end;

//---------------------------------------------
function TIEnumVariant._AddRef: Integer;stdcall;
begin
  Result:=xEnum._AddRef;
end;

//---------------------------------------------
function TIEnumVariant._Release: Integer;stdcall;
begin
  Result:=xEnum._Release;
end;

//---------------------------------------------
function  TIEnumVariant.QueryInterface(const IID: TGUID; out Obj): HResult;stdcall;
begin
   Result:=xEnum.QueryInterface(IID,Obj);
end;

//--------------------------------------------------------
// Lua wrapper for TIEnumVariant
// Here because of we have Create method with parameter
// we must create TIEnumVariant something like this
// local Enum=TIEnumVariant.Create(xObj:_NewEnum());
//--------------------------------------------------------
procedure Package_TIEnumVariant.RegisterFunctions;
begin
  Methods.AddObject('Create',TUserFuncObject.CreateWithName('Create',pckg_Create));
  Methods.AddObject('Next',TUserFuncObject.CreateWithName('Next',pckg_Next));
  Methods.AddObject('Skip',TUserFuncObject.CreateWithName('Skip',pckg_Skip));
  Methods.AddObject('Reset',TUserFuncObject.CreateWithName('Reset',pckg_Reset));
  Methods.AddObject('Clone',TUserFuncObject.CreateWithName('Clone',pckg_Clone));

  HandledProps:=TStringList.Create; //--- only for show that it is Class package
end;

//--------------------------------------------------------
// Create Lua wrapper for TIEnumVariant
// Here because of we have Create method with parameter
// we must create TIEnumVariant something like this
// local Enum=TIEnumVariant.Create(xObj:_NewEnum());
//--------------------------------------------------------
function Package_TIEnumVariant.pckg_Create(Params:TList): Integer;
var
   xLuaObj:TxVariant;
   xxEnum:TIEnumVariant;
begin
   Result:=0;

   xLuaObj:=TxVariant(Params.Items[0]);
   xxEnum:=TIEnumVariant.Create(xLuaObj.V);

   //if((xComObj.VarType = varDispatch) or (xComObj.VarType = varDispatch))then begin
   //end;

   xLuaObj.Ptr:=xxEnum; //-- return value back
end;

//--------------------------------------------------------
// TIEnumVariant:
// Wrapper for function IEnumVariant.Next(celt: LongWord; var rgvar : OleVariant;out pceltFetched: LongWord): HResult; stdcall;
//  Here we use LUA abililty return few parameters , so "Next" Must be called as follows:
//  Result,NextObject,CeltFetched=MyEnum:Next(celt)
//--------------------------------------------------------
function Package_TIEnumVariant.pckg_Next(Params:TList): Integer;
var
   xxEnum:TIEnumVariant;
   xRes:HResult;
   dblRes:Double;
   celt:LongWord;
   pceltFetched:LongWord;
   OutVar:OleVariant;
   xVariant:TXVariant;
begin
   Result:=0;

   //-- Get Object itself -----
   xxEnum:=TIEnumVariant(TxVariant(Params.Items[0]).Ptr);
   celt:=LongWord(TxVariant(Params.Items[1]).V);
   OutVar:=0;

   xRes:=xxEnum.Next(celt,OutVar,pceltFetched);
   dblRes:=xRes;
   TxVariant(Params.Items[0]).V:=dblRes;
   TxVariant(Params.Items[1]).V:=OutVar;

   dblRes:=pceltFetched;
   xVariant:=TXVariant.Create;
   Params.Add(xVariant);
   TxVariant(Params.Items[2]).V:=dblRes;
end;

//--------------------------------------------------------
function Package_TIEnumVariant.pckg_Skip(Params:TList): Integer;
var
  Celt:integer;
begin
   Result:=0;
   Celt:=Integer(TxVariant(Params.Items[1]).V);
   TIEnumVariant(TxVariant(Params.Items[0]).Ptr).Skip(Celt);
end;

//--------------------------------------------------------
function Package_TIEnumVariant.pckg_Reset(Params:TList): Integer;
begin
   Result:=0;
   TIEnumVariant(TxVariant(Params.Items[0]).Ptr).Reset;
end;

//--------------------------------------------------------
function Package_TIEnumVariant.pckg_Clone(Params:TList): Integer;
var
 xNewEnum:IEnumVariant;
begin
   Result:=0;
   TIEnumVariant(TxVariant(Params.Items[0]).Ptr).Clone(xNewEnum);
   //-- Create new wrapper object and return it to caller --------- 
   TxVariant(Params.Items[0]).Ptr:=TIEnumVariant.Create(xNewEnum);
end;

//---------------------------------------------------------
// Call To COM AddRef() method
// Params:
//  0 - COM object
//---------------------------------------------------------
function Package_COM.pckg_AddRef(Params:TList): Integer;
var
 pV1:TxVariant;
begin
  Result:=0;
  pV1:=TXVariant(Params.Items[0]);
  iUnknown(pV1.V)._AddRef;
end;

//---------------------------------------------------------
// Call To COM Release() method
// Params:
//  0 - COM object
//---------------------------------------------------------
function Package_COM.pckg_Release(Params:TList): Integer;
var
 pV1:TxVariant;
begin
  Result:=0;
  pV1:=TXVariant(Params.Items[0]);
  iUnknown(pV1.V)._Release;
end;


//=======================================================================
// Initialization: Init data, Register variables and package itself.
//=======================================================================
initialization

    //--- Create Stringlist of OLE types -------------
    OleTypesStringList:=TStringList.Create;
    OleTypesStringList.AddObject('bVal',Pointer(VT_UI1));
    OleTypesStringList.AddObject('iVal',Pointer(VT_I2));
    OleTypesStringList.AddObject('lVal',Pointer(VT_I4));
    OleTypesStringList.AddObject('fltVal',Pointer(VT_R4));
    OleTypesStringList.AddObject('dblVal',Pointer(VT_R8));
    OleTypesStringList.AddObject('vbool',Pointer(VT_BOOL));
    OleTypesStringList.AddObject('scode',Pointer(VT_ERROR));
    OleTypesStringList.AddObject('cyVal',Pointer(VT_CY));
    OleTypesStringList.AddObject('date',Pointer(VT_DATE));
    OleTypesStringList.AddObject('bstrVal',Pointer(VT_BSTR));
    OleTypesStringList.AddObject('unkVal',Pointer(VT_UNKNOWN));
    OleTypesStringList.AddObject('dispVal',Pointer(VT_DISPATCH));
    OleTypesStringList.AddObject('parray',Pointer(VT_ARRAY));
    OleTypesStringList.AddObject('pbVal',Pointer(VT_BYREF or VT_UI1));
    OleTypesStringList.AddObject('piVal',Pointer(VT_BYREF or VT_I2));
    OleTypesStringList.AddObject('plVal',Pointer(VT_BYREF or VT_I4));
    OleTypesStringList.AddObject('pfltVal',Pointer(VT_BYREF or VT_R4));
    OleTypesStringList.AddObject('pdblVal',Pointer(VT_BYREF or VT_R8));
    OleTypesStringList.AddObject('pbool',Pointer(VT_BYREF or VT_BOOL));
    OleTypesStringList.AddObject('pscode',Pointer(VT_BYREF or VT_ERROR));
    OleTypesStringList.AddObject('pcyVal',Pointer(VT_BYREF or VT_CY));
    OleTypesStringList.AddObject('pdate',Pointer(VT_BYREF or VT_DATE));
    OleTypesStringList.AddObject('pbstrVal',Pointer(VT_BYREF or VT_BSTR));
    OleTypesStringList.AddObject('punkVal',Pointer(VT_BYREF or VT_UNKNOWN));
    OleTypesStringList.AddObject('pdispVal',Pointer(VT_BYREF or VT_DISPATCH));
    OleTypesStringList.AddObject('pparray',Pointer(VT_BYREF or VT_ARRAY));
    OleTypesStringList.AddObject('pvarVal',Pointer(VT_BYREF or VT_VARIANT));
    OleTypesStringList.AddObject('byRef',Pointer(VT_BYREF));
    OleTypesStringList.AddObject('cVal',Pointer(VT_I1));
    OleTypesStringList.AddObject('uiVal',Pointer(VT_UI2));
    OleTypesStringList.AddObject('ulVal',Pointer(VT_UI4));
    OleTypesStringList.AddObject('intVal',Pointer(VT_INT));
    OleTypesStringList.AddObject('uintVal',Pointer(VT_UINT));
    OleTypesStringList.AddObject('pdecVal',Pointer(VT_BYREF or VT_DECIMAL));
    OleTypesStringList.AddObject('pcVal',Pointer(VT_BYREF or VT_I1));
    OleTypesStringList.AddObject('puiVal',Pointer(VT_BYREF or VT_UI2));
    OleTypesStringList.AddObject('pulVal',Pointer(VT_BYREF or VT_UI4));
    OleTypesStringList.AddObject('pintVal',Pointer(VT_BYREF or VT_INT));
    OleTypesStringList.AddObject('puintVal',Pointer(VT_BYREF or VT_UINT));
    OleTypesStringList.Sorted:=true;


LUA_COM_INITITALIZED:=false;

//--- Create string package -----
PACK_COM:=Package_COM.Create;
PACK_COM.RegisterFunctions;

PACK_IENUMVARIANT:=Package_TIEnumVariant.Create;
PACK_IENUMVARIANT.RegisterFunctions;


//--- Register this package -----
LuaInter.RegisterGlobalVar('_COM',PACK_COM);
LuaInter.RegisterGlobalVar('TIEnumVariant',PACK_IENUMVARIANT);

end.
