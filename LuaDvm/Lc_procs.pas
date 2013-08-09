//=========================================================
// additional functions for work with RTTI
// -----------------------------------------
// Author:Serge Vertiev (c) 1999.
//=========================================================
unit Lc_procs;

interface
uses
   Windows, SysUtils, Classes, Graphics, Controls, Forms,ComCtrls,TypInfo,StdCtrls;

//--------------------------------------------------
// Functions prototypes
//--------------------------------------------------
//----- functions for get/set individual properties of object ------
procedure LC_GetListOfPropRefferences(xObject:TObject;xClassName:String;xRef:TObject;SummaryList:TStringList;Recursive:boolean);
function  LC_GetRefferencesListForObject(xRefObject:TObject;PropsAndObjList:TStringList):integer;
function  LC_GetSetOrdPropValue(Cmd:Char;xObject:TObject;PropName:String;var Value:integer):boolean;
procedure LC_SetOrdProp(Instance: TObject; const PropName: string;Value: Longint);
function  LC_GetPropAsString(xObject:TObject;PropName:String;var Value:String;NumFormat:String):boolean; //$VS9AUG2002

function  LC_GetSetPropAsVariant(cmd:char;xObject:TObject;PropName:String;var Value:Variant;var PropIsObject:boolean):boolean;
function  LC_GetPropAsVariant(xObject:TObject;PropName:String;var Value:Variant;var PropIsObject:boolean):boolean;
function  LC_SetPropAsVariant(xObject:TObject;PropName:String;var Value:Variant;var PropIsObject:boolean):boolean;

function  LC_FindComponentByName(xComponent:TComponent;xName:String):TComponent;
procedure GetListOfMethods(xObject:TObject;SummaryList:TStringList);
procedure AddClassToCash(ObjName:String;xObj:TObject;OwnerName:String);
function  LC_GetPropList(TypeInfo: PTypeInfo; TypeKinds: TTypeKinds;PropList:TStringList): Integer;

//----- Common Dialogs --------------
function  LC_GetStringDialog(Description:String;frmCaption:String;DefaultValue:String;PossibleValues:TStringList):String;

implementation
const MAX_FIND_CLASS_CASH_SIZE = 32;
var
FindClassCashLst:TStringList;


//--------------------------------------------------------------------------------
// Make image list from resource bitmaps and attach it TreeView.
// Bmp names contained in input StringList.
// Resourcse bmp names must be BMP_xxxx where xxx is strings from NamesList
//--------------------------------------------------------------------------------
function LC_MakeImageListByResNames(AOwner:TComponent;NamesList:TStringList;MaskColor:TColor):TImageList;
var
 i:integer;
 xBmp:TBitMap;
begin
   Result:=TImageList.Create(AOwner);
   xBmp:=TBitmap.Create;

   //---- Load bitmaps from resource and add them to ImageList ----
   for i:=0 to NamesList.Count-1 do begin
      xBmp.LoadFromResourceName(HInstance,'BMP_'+NamesList.Strings[i]);
      Result.AddMasked(xBmp,MaskColor);
   end;
   xBmp.Free;
end;

//----------------------------------------------------------------------
// Assign Image Indexes for TreeView nodes.
// Assumed that TreeView already have ImageList constructed by
// function LC_MakeImageListByResNames.
// Nodes have Data as pointers to objects with class names which
// presents in NamesList.
//----------------------------------------------------------------------
procedure LC_AssignTreeImages(NamesList:TStringList;xTreeView:TTreeView);
var
 xNode:TTreeNode;
 xClassName:String;
 idx:integer;
 i:integer;
begin
   ///i:=xTreeView.Items.Count;
   for i:=0 to xTreeView.Items.Count-1 do begin
        xNode:=xTreeView.Items[i];
        if(xNode.Data <> Nil)then begin
           xClassName:=TObject(xNode.Data).ClassName;
           idx:=NamesList.IndexOf(xClassName);
           if(idx <> -1)then begin
              xNode.ImageIndex:=idx;
           end;
        end;
   end;
end;


//----------------------------------------------------------------------
// Add objects from specified list as childs of specified tree node
// Usefull for build complex tree from many forms.
//----------------------------------------------------------------------
procedure LC_AddObjectsToTreeNode(ObjList:TList;Node:TTreeNode;xTreeView:TTreeView);
var
  //xTreeView:TTreeView;
  NewNode:TTreeNode;
  i:integer;
begin
    //xTreeView:=TTreeView(Node.TreeView);
    for i:=0 to ObjList.Count-1 do begin
        //--- add object from list as tree node --------
        NewNode:=xTreeView.Items.AddChild(Node,TControl(ObjList.Items[i]).Name);
        NewNode.Data:=ObjList.Items[i];
    end;
end;


//-----------------------------------------------------------------------------------------
// Collect all Properties/Objects to StringList
// if type of property = xClass.
// if xRef specified then collect only
// properties/Objects with value = xRef.
// Internal function with circular refferences checking:
//-----------------------------------------------------------------------------------------
procedure GetListOfPropRefferences(xRecursionList:TList;xObject:TObject;xClassName:String;xRef:TObject;SummaryList:TStringList;Recursive:boolean);
var
  ptrTypeInf    : PTypeInfo;
  ptrTypeData   : PTypeData;
  xPropLst:PPropList;
  xAllPropCount:integer;
  xPropCount:integer;
  I:integer;
  aTypeInf  :PTypeInfo;
  Value:TObject;
  xCollectionItem:TCollectionItem;
  CollectionIdx:integer;
begin
   ptrTypeInf:=xObject.ClassInfo;
   ptrTypeData:=GetTypeData(ptrTypeInf);

   //--- Allocate space for all properties list -----------
   xAllPropCount:=ptrTypeData^.PropCount;
   GetMem(xPropLst,xAllPropCount*sizeof(pointer)); {alloc block of pointers}

   //--- Get only list of publised properties -----------
   xpropCount:=GetPropList(ptrTypeInf,tkProperties,xPropLst);

   //---- Scan all props for find Property with specified name ----
   for I:=0 to xpropCount-1 do begin
      aTypeInf:=xPropLst^[I]^.PropType^;
      //------- Use only Integer or Enumeration property types ------
      if(aTypeInf^.Kind = tkClass)then begin

          Value:=TObject(GetOrdProp(xObject,xPropLst^[I])); //--- get actual pointer to object from property

          if(aTypeInf^.Name = xClassName)then begin
              //--- if specified - add this property to list only if equeal --
              if(xRef <> Nil)then begin
                 if(Value = xRef)then begin
                    //---- add this property to list -----
                    SummaryList.AddObject(xPropLst^[I]^.Name,xObject); //--- add to list
                 end;
              end else begin
                 //---- else add property unconditionally -----
                 SummaryList.AddObject(xPropLst^[I]^.Name,xObject); //--- add to list
              end;
          end else begin
              //---- If pointer to some other object - we need to test this object -----
              //---- For collections and Internal objects (non TControl) call Recursive if needs ----
              if((Recursive) and (Value <> Nil))then begin
                 //----- If we have - collection - check all it's items ------
                 if(Value is TCollection)then begin
                     for CollectionIdx:=0 to TCollection(Value).Count-1 do begin
                        xCollectionItem:=TCollection(Value).Items[CollectionIdx];
                        if(xRecursionList.IndexOf(xCollectionItem) < 0)then begin
                           xRecursionList.Add(xCollectionItem);
                           GetListOfPropRefferences(xRecursionList,xCollectionItem,xClassName,xRef,SummaryList,Recursive);
                        end;
                     end;
                 end;
                 //----- check internal object of specified object (in Case of Collection - check it's props also)
                 if( (not (Value is TControl)) and (Value is TPersistent))then begin
                    if(xRecursionList.IndexOf(Value) < 0)then begin
                      xRecursionList.Add(Value);
                      GetListOfPropRefferences(xRecursionList,Value,xClassName,xRef,SummaryList,Recursive);
                    end;
                 end;
              end;
          end;
      end;
   end;
   FreeMem(xPropLst,xAllPropCount*sizeof(pointer));

end;

//-----------------------------------------------------------------------------------------------
// Collect all Properties/Objects to StringList
// if type of property = xClass.
// if xRef specified then collect only
// properties/Objects with value = xRef
// If Recursive = true - then objects pointed from specified object are also scanned...
// This function handle circular refferences by collecting all objects checked in Recursive mode.
//-----------------------------------------------------------------------------------------------
procedure LC_GetListOfPropRefferences(xObject:TObject;xClassName:String;xRef:TObject;SummaryList:TStringList;Recursive:boolean);
var
  xRecursionList:TList;
begin
   xRecursionList:=TList.Create;
   GetListOfPropRefferences(xRecursionList,xObject,xClassName,xRef,SummaryList,Recursive);
   xRecursionList.Free;
end;

//-----------------------------------------------------------------
// Get/set value of Order property by class and property name.
// Cmd:
//  'G' - Get property
//  'S' - Set property
//-----------------------------------------------------------------
function LC_GetSetOrdPropValue(Cmd:Char;xObject:TObject;PropName:String;var Value:integer):boolean;
var
  ptrTypeInf    : PTypeInfo;
  ptrTypeData   : PTypeData;
  xPropLst:PPropList;
  xAllPropCount:integer;
  xPropCount:integer;
  I:integer;
  aTypeInf  :PTypeInfo;
  xLongInt:LongInt;
begin
   Result:=false;
   ptrTypeInf:=xObject.ClassInfo;
   ptrTypeData:=GetTypeData(ptrTypeInf);

   //--- Allocate space for all properties list -----------
   xAllPropCount:=ptrTypeData^.PropCount;
   GetMem(xPropLst,xAllPropCount*sizeof(pointer)); {alloc block of pointers}

   //--- Get only list of publised properties -----------
   xpropCount:=GetPropList(ptrTypeInf,tkProperties,xPropLst);

   //---- Scan all props for find Property with specified name ----
   for I:=0 to xpropCount-1 do begin
      if(xPropLst^[I]^.Name = PropName)then begin
        aTypeInf:=xPropLst^[I]^.PropType^;
        //------- Use only Integer or Enumeration property types ------
        if((aTypeInf^.Kind = tkInteger) or (aTypeInf^.Kind = tkEnumeration))then begin
          try
            if((Cmd = 'G') or (Cmd ='g'))then begin
               Value:=GetOrdProp(xObject,xPropLst^[I]);
            end else begin
               xLongInt:=Value;
               SetOrdProp(xObject,xPropLst^[I],xLongInt);
            end;
            Result:=true;
            break;
          except
            break;
          end;
        end;
      end;
   end;
   FreeMem(xPropLst,xAllPropCount*sizeof(pointer));

end;

//----------------------------------------
// Wrapper for TypeInfo procedure
//----------------------------------------
procedure LC_SetOrdProp(Instance: TObject; const PropName: string;Value: Longint);
begin
    SetOrdProp(Instance,PropName,Value);
end;



//--------------------------------------------------------------
// Common dialog for enter (or select from list) some string...
//--------------------------------------------------------------
function LC_GetStringDialog(Description:String;frmCaption:String;DefaultValue:String;PossibleValues:TStringList):String;
var
  StrEdDlg:TForm;
  StrEd:TControl;
  btnOK:TButton;
  btnCancel:TButton;
  xLabel:TLabel;
  xLeft:integer;
  xTop:integer;
  MaxWidth:integer;
  DescriptionList:TStringList;
  i:integer;
  const xBtnWidth=50;
begin
  Result:='';

  StrEdDlg:=TForm.Create(Nil);
  StrEdDlg.Height:=90;
  StrEdDlg.Width:=430;
  StrEdDlg.BorderStyle:=bsDialog;
  StrEdDlg.Caption:=frmCaption;
  StrEdDlg.Position:=poScreenCenter;

  DescriptionList:=TStringList.Create;
  DescriptionList.SetText(PChar(Description));

  //----- Create labels for each string in Description Text ---
  xLeft:=10;
  xTop:=10;
  MaxWidth:=0;
  for i:=0 to DescriptionList.Count-1 do begin
     xLabel:=TLabel.Create(StrEdDlg);
     xLabel.Left:=xLeft;
     xLabel.Top:=xTop;
     xLabel.Caption:=DescriptionList.Strings[i];
     xLabel.Width:=StrEdDlg.Canvas.TextWidth(DescriptionList.Strings[i])+10;
     xLabel.Parent:=StrEdDlg;
     if(xLabel.Width > MaxWidth)then begin
        MaxWidth:=xLabel.Width;
     end;
     xTop:=xLabel.Top+StrEdDlg.Canvas.TextHeight(DescriptionList.Strings[i])+4;
  end;

  MaxWidth:=MaxWidth+40;
  xTop:=xTop+4;

  if(MaxWidth > StrEdDlg.Width)then begin
    StrEdDlg.Width:=MaxWidth;
  end;

  if(StrEdDlg.ClientHeight < (xTop+50))then begin
    StrEdDlg.ClientHeight:=xTop+50;
  end;


  if(PossibleValues <> NIL)then begin
    StrEd:=TComboBox.Create(StrEdDlg);
    StrEd.Parent:=StrEdDlg;
    if(PossibleValues.Count > 0)then begin
      TComboBox(StrEd).Items.Assign(PossibleValues);
    end;
  end else begin
    StrEd:=TEdit.Create(StrEdDlg);
  end;

  StrEd.Height:=20;
  StrEd.Width:=StrEdDlg.Width-8-((xBtnWidth+8)*2)-40;
  StrEd.Top:=xTop;
  StrEd.Left:=10;
  StrEd.Parent:=StrEdDlg;

  btnOK:=TButton.Create(StrEdDlg);
  btnOK.Height:=StrEd.Height;
  btnOK.Width:=xBtnWidth;
  btnOK.Top:=StrEd.Top;
  btnOK.Left:=StrEd.Left+StrEd.Width+8;
  btnOK.Caption:='OK.';
  btnOK.ModalResult:=mrOK;
  btnOK.Parent:=StrEdDlg;

  btnCancel:=TButton.Create(StrEdDlg);
  btnCancel.Height:=StrEd.Height;
  btnCancel.Width:=xBtnWidth;
  btnCancel.Top:=StrEd.Top;
  btnCancel.Left:=btnOK.Left+btnOK.Width+8;
  btnCancel.Caption:='Cancel';
  btnCancel.ModalResult:=mrCancel;
  btnCancel.Parent:=StrEdDlg;

  StrEdDlg.Width:=btnCancel.Left+btnCancel.Width+10;

  if(DefaultValue <> '')then begin
      if(StrEd is TEdit)then begin
         TEdit(StrEd).Text:=DefaultValue;
      end else begin
         TCombobox(StrEd).Text:=DefaultValue;
      end;
  end;


  StrEdDlg.ShowModal;

  if(StrEdDlg.ModalResult = mrOK)then begin
      if(StrEd is TEdit)then begin
         Result:=TEdit(StrEd).Text;
      end else begin
         Result:=TCombobox(StrEd).Text;
      end;
  end;

  DescriptionList.Free;
  StrEdDlg.Free;
end;


//-----------------------------------------------------------------
// Get string representation of property by class and property name.
// NumFormat is Format string for Format function. E.g '%.8d'
// NOTE: Assumed that Property is String/Char or Ordinal.
//-----------------------------------------------------------------
function LC_GetPropAsString(xObject:TObject;PropName:String;var Value:String;NumFormat:String):boolean;
var
  ptrTypeInf    : PTypeInfo;
  ptrTypeData   : PTypeData;
  xPropLst:PPropList;
  xAllPropCount:integer;
  xPropCount:integer;
  I:integer;
  aTypeInf  :PTypeInfo;

  OrdValue:integer;
  FloatValue:Extended;
  StrValue:String;

begin
   Result:=false;
   ptrTypeInf:=xObject.ClassInfo;
   ptrTypeData:=GetTypeData(ptrTypeInf);

   //--- Allocate space for all properties list -----------
   xAllPropCount:=ptrTypeData^.PropCount;
   GetMem(xPropLst,xAllPropCount*sizeof(pointer)); {alloc block of pointers}

   //--- Get only list of publised properties -----------
   xpropCount:=GetPropList(ptrTypeInf,tkProperties,xPropLst);

   //---- Scan all props for find Property with specified name ----
   for I:=0 to xpropCount-1 do begin
      if(xPropLst^[I]^.Name = PropName)then begin
        try
          aTypeInf:=xPropLst^[I]^.PropType^;
          //------- Use only Integer or Enumeration property types ------
          case (aTypeInf^.Kind) of
            tkString,tkWString,tkLString,tkChar:
               begin
                 StrValue:=GetStrProp(xObject,xPropLst^[I]);
                 Result:=true;
               end;
            tkInteger,tkEnumeration,tkSet:
               begin
                 OrdValue:=GetOrdProp(xObject,xPropLst^[I]);
                 StrValue:=Format(NumFormat,[OrdValue]);
                 Result:=true;
               end;
            tkFloat:
               begin
                 FloatValue:=GetFloatProp(xObject,xPropLst^[I]);
                 StrValue:=FloatToStr(FloatValue);
                 Result:=true;
               end;
          end;//-case
        except
          break;
        end;//-try
      end;//-if
   end;//-for

   FreeMem(xPropLst,xAllPropCount*sizeof(pointer));

   if(Result)then begin
      Value:=StrValue; //-- return to caller
   end;
end;


//----------------------------------------------------------------------
// Scan all objects on form and
// find all refferences (in published properties) to specified object
// and collect them to specified list.
// Return : List Count
// xList contains PropName as Strings[i] and Object which contains
// this property in Objects[i]
//-----------------------------------------------------------------------
function LC_GetRefferencesListForObject(xRefObject:TObject;PropsAndObjList:TStringList):integer;
var
  xForm:TForm;
  i:integer;
  xComponent:TComponent;
  Recursive:boolean;
  // PropName:String;
begin
  ///Result:=0;
  PropsAndObjList.Clear;

  xForm:=TForm(TControl(xRefObject).Owner);

  Recursive:=true; //--- for scan all subobjects and items in collections ---
  for i:=0 to xForm.ComponentCount-1 do begin
      xComponent:=xForm.Components[i];
      if(TObject(xComponent) <> xRefObject)then begin
         LC_GetListOfPropRefferences(xComponent,xRefObject.ClassName,xRefObject,PropsAndObjList,Recursive);
      end;
  end;

  Result:=PropsAndObjList.Count;
end;


//-----------------------------------------------------------------
// Get or Set Property as Variant value
// cmd:'G' - get 'S' - set
//-----------------------------------------------------------------
function LC_GetSetPropAsVariant(cmd:char;xObject:TObject;PropName:String;var Value:Variant;var PropIsObject:boolean):boolean;
var
  ptrTypeInf    : PTypeInfo;
  ptrTypeData   : PTypeData;
  xPropLst:PPropList;
  xAllPropCount:integer;
  xPropCount:integer;
  I:integer;
  aTypeInf  :PTypeInfo;

  OrdValue:integer;
  FloatValue:Extended;
  StrValue:String;

begin
   Result:=false;
   PropIsObject:=false;

   ptrTypeInf:=xObject.ClassInfo;
   ptrTypeData:=GetTypeData(ptrTypeInf);

   //--- Allocate space for all properties list -----------
   xAllPropCount:=ptrTypeData^.PropCount;
   GetMem(xPropLst,xAllPropCount*sizeof(pointer)); {alloc block of pointers}

   //--- Get only list of publised properties -----------
   xpropCount:=GetPropList(ptrTypeInf,tkProperties,xPropLst);

   //---- Scan all props for find Property with specified name ----
   for I:=0 to xpropCount-1 do begin
      if(xPropLst^[I]^.Name = PropName)then begin
        try
          aTypeInf:=xPropLst^[I]^.PropType^;
          //---- get type data for this property --------
          ptrTypeData:=GetTypeData(aTypeInf);
          
          //------- Use only Integer or Enumeration property types ------
          //PropKind:=aTypeInf^.Kind; //-- return type of property

          case (aTypeInf^.Kind) of
            //---------------------------------
            tkString,tkWString,tkLString,tkChar:
               begin
                 if(cmd ='G')then begin
                   StrValue:=GetStrProp(xObject,xPropLst^[I]);
                   Value:=StrValue;
                 end else begin
                   StrValue:=Value;
                   SetStrProp(xObject,xPropLst^[I],StrValue);
                 end;
                 Result:=true;
               end;

            //---------------------------------
            tkInteger,tkEnumeration,tkSet:
               begin
                 if(cmd ='G')then begin
                   //--- Get property ----------
                   OrdValue:=GetOrdProp(xObject,xPropLst^[I]);
                   //--- Specially handle Boolean prop -------------
                   if((aTypeInf^.Kind = tkEnumeration) and (ptrTypeData^.BaseType^ = TypeInfo(Boolean)))then begin
                       Value:=Boolean(GetOrdProp(xObject,xPropLst^[I]));
                   end else begin
                       //--- Get other integer value and save it as Real because
                       //--- we use only Reals in Lua for any numeric types ----
                       FloatValue:=OrdValue;
                       Value:=FloatValue;
                   end;
                 end else begin
                   //--- Set property ----------

                   if((aTypeInf^.Kind = tkEnumeration) and (ptrTypeData^.BaseType^ = TypeInfo(Boolean)))then begin
                       //--- Specially handle Boolean prop -------------
                       if(boolean(Value))then begin
                         OrdValue:=integer(true);
                       end else begin
                         OrdValue:=integer(false);
                       end;
                   end else begin
                       //--- All other integer values ----
                       OrdValue:=Integer(Value);
                   end;
                   SetOrdProp(xObject,xPropLst^[I],OrdValue);
                 end;
                 Result:=true;
               end;

            //---------------------------------
            tkClass:
               begin
                  PropIsObject:=true;
                  if(cmd ='G')then begin
                    OrdValue:=GetOrdProp(xObject,xPropLst^[I]);
                    Value:=OrdValue;
                  end else begin
                    OrdValue:=Value;
                    SetOrdProp(xObject,xPropLst^[I],OrdValue);
                  end;
                  Result:=true;
               end;

            //---------------------------------
            tkFloat:
               begin
                 if(cmd ='G')then begin
                   FloatValue:=GetFloatProp(xObject,xPropLst^[I]);
                   Value:=FloatValue;
                 end else begin
                   FloatValue:=Value;
                   SetFloatProp(xObject,xPropLst^[I],FloatValue);
                 end;
                 Result:=true;
               end;
          end;//-case
        except
          break;
        end;//-try
      end;//-if
   end;//-for

   FreeMem(xPropLst,xAllPropCount*sizeof(pointer));
end;

//------------------------------------------
// Get property as Variant wrapper.
//------------------------------------------
function  LC_GetPropAsVariant(xObject:TObject;PropName:String;var Value:Variant;var PropIsObject:boolean):boolean;
begin
   Result:=LC_GetSetPropAsVariant('G',xObject,PropName,Value,PropIsObject);
end;

//------------------------------------------
// Set property as Variant wrapper.
//------------------------------------------
function  LC_SetPropAsVariant(xObject:TObject;PropName:String;var Value:Variant;var PropIsObject:boolean):boolean;
begin
   Result:=LC_GetSetPropAsVariant('S',xObject,PropName,Value,PropIsObject);
end;

//------------------------------------------------------------------------------
// Find control hawing name "xName" owned by specified xComponent
//------------------------------------------------------------------------------
function  LC_FindComponentByName(xComponent:TComponent;xName:String):TComponent;
var
  i:integer;
begin
    //--- Don't use component cash because Names can changed and cash can save old value
    //--- So we need explicitly clear cash. It is borry. 
    //-- First find in cash -----------
    //if(FindClassCashLst.Find(xName+'$'+xComponent.Name,i))then begin
    //   Result:=TComponent(FindClassCashLst.Objects[i]);
    //   Exit;
    //end;

    for i:=0 to xComponent.ComponentCount-1 do begin
         if(not (xComponent.Components[i] is TComponent))then Continue;

         if(TComponent(xComponent.Components[i]).Name = xName)then begin
           Result:=xComponent.Components[i];
           //AddClassToCash(xName,Result,'$'+xComponent.Name);
           Exit;
         end;
    end;
    Result:=Nil;
end;


//-----------------------------------------------------------------------------------------
// Collect all Properties/Objects to StringList
// if type of property = xClass.
// if xRef specified then collect only
// properties/Objects with value = xRef.
// Internal function with circular refferences checking:
//-----------------------------------------------------------------------------------------
procedure GetListOfMethods(xObject:TObject;SummaryList:TStringList);
var
  ptrTypeInf    : PTypeInfo;
  ptrTypeData   : PTypeData;
  xPropLst:PPropList;
  xAllPropCount:integer;
  xPropCount:integer;
  I:integer;
  aTypeInf  :PTypeInfo;
  //Value:TObject;
  //xCollectionItem:TCollectionItem;
  //CollectionIdx:integer;
begin
   ptrTypeInf:=xObject.ClassInfo;
   ptrTypeData:=GetTypeData(ptrTypeInf);

   //--- Allocate space for all properties list -----------
   xAllPropCount:=ptrTypeData^.PropCount;
   GetMem(xPropLst,xAllPropCount*sizeof(pointer)); {alloc block of pointers}

   //--- Get only list of publised properties -----------
   xpropCount:=GetPropList(ptrTypeInf,tkMethods,xPropLst);

   //---- Scan all props for find Property with specified name ----
   for I:=0 to xpropCount-1 do begin
      aTypeInf:=xPropLst^[I]^.PropType^;
      //------- Use only Integer or Enumeration property types ------
      //if(aTypeInf^.Kind = tkMethod)then begin
         SummaryList.Add(xPropLst^[I]^.Name+':'+aTypeInf^.Name);
      //end;
   end;
   FreeMem(xPropLst,xAllPropCount*sizeof(pointer));

end;

//----------------------------------------------
// Add class to cash
//----------------------------------------------
procedure AddClassToCash(ObjName:String;xObj:TObject;OwnerName:String);
begin
   if(FindClassCashLst = Nil)then begin
      FindClassCashLst:=TStringList.Create;
      FindClassCashLst.Sorted:=true;
      FindClassCashLst.Duplicates:=dupIgnore;
   end;
   if(FindClassCashLst.Count > MAX_FIND_CLASS_CASH_SIZE)then begin
      FindClassCashLst.Clear; //-- fully renew cash
   end;
   FindClassCashLst.AddObject(ObjName+OwnerName,xObj);
end;

//----------------------------------------------------------------
// Return list of Properties as:
// Strings - PropNames
// Objects - PPropInfo
// Result:Count of props
//----------------------------------------------------------------
function LC_GetPropList(TypeInfo: PTypeInfo; TypeKinds: TTypeKinds;PropList:TStringList): Integer;
var
  I, Count: Integer;
  PropInfo: PPropInfo;
  TempList: PPropList;
begin
  Result := 0;
  Count := GetTypeData(TypeInfo)^.PropCount;
  if Count > 0 then
  begin
    GetMem(TempList, Count * SizeOf(Pointer));
    try
      GetPropInfos(TypeInfo, TempList);
      for I := 0 to Count - 1 do
      begin
        PropInfo := TempList^[I];
        if PropInfo^.PropType^.Kind in TypeKinds then
        begin
          if PropList <> nil then begin
            PropList.AddObject(PropInfo^.Name,TObject(PropInfo));
            Inc(Result);
          end;
        end;
      end;
      //if (PropList <> nil) and (Result > 1) then begin
      //  SortPropList(PropList, Result);
      //end;
    finally
      FreeMem(TempList, Count * SizeOf(Pointer));
    end;
  end;
end;

initialization
FindClassCashLst:=TStringList.Create;


END.
