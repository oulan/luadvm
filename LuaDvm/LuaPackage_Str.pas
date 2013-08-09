//---------------------------------------------------------
// Package for work with Strings
// wrap some usefull Delphi Strings functions
//--------------------------------------------------------
unit LuaPackage_Str;

interface
 uses Windows, Messages, SysUtils,Classes,LuaInter,Grids,BMH_Search;

 //--------------------------------------------------------------------
 // Pachage Class for collect some general purpose functions
 //--------------------------------------------------------------------
 type Package_Str=class(TLuaPackage)
  public
    //--- Functions in Package ---------
    function pckg_Pos(Params:TList): Integer;
    function pckg_Copy(Params:TList):integer;
    function pckg_CopyBuf(Params:TList):integer;
    function pckg_ExtractFileName(Params:TList):integer;
    function pckg_ExtractFilePath(Params:TList):integer;
    function pckg_Length(Params:TList):integer;
    function pckg_SetLength(Params:TList):integer;
    function pckg_StringOfChar(Params:TList):integer;
    function pckg_ExTrim(Params:TList):integer;
    function pckg_ParseFields(Params:TList):integer;
    function pckg_AnsiUpperCase(Params:TList):integer;

    function pckg_isalpha(Params:TList):integer;
    function pckg_isdigit(Params:TList):integer;
    function pckg_isValidForIdentifier(Params:TList):integer;
    function pckg_CharCode(Params:TList):integer;
    function pckg_ToHex(Params:TList):integer;
    function pckg_HexToNum(Params:TList):integer;
    function pckg_HexToStrBuf(Params:TList):integer;
    function pckg_StrBufToHex(Params:TList):integer;
    function pckg_QuickSearch(Params:TList):integer;

  public
    procedure RegisterFunctions;override;
 end;

 //--------------------------------------------------------------------
 // TStringGrid Class Package
 //--------------------------------------------------------------------
 type ClassTStringGridPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function GetCols(Params:TList): Integer;
    function GetCell(Params:TList): Integer;
    function SetCell(Params:TList): Integer;
    function GetObject(Params:TList): Integer;
    function SetObject(Params:TList): Integer;
    function GetSelectionRect(Params:TList): Integer;
    function Clear(Params:TList):Integer;

    function HandleProperties(Params:TList):integer;

  public
    procedure RegisterFunctions;override;
 end;

 //--------------------------------------------------------------------
 // TFileStream Class Package
 //--------------------------------------------------------------------
 type ClassTFileStreamPackage=class(TLuaPackage)
  private
    //--- Functions in Package ---------
    function xCreate(Params:TList): Integer;
    function xSeek(Params:TList): Integer;
    function xRead(Params:TList): Integer;
    function xWrite(Params:TList): Integer;
    function xGetSize(Params:TList): Integer;

    function HandleProperties(Params:TList):integer;

  public
    procedure RegisterFunctions;override;
 end;

//----------------
// Internal functions
function ConvHexStringToByteArray(inStr:String;var pBuf:PChar;var AllockedSize:integer):integer;

//---------------------------------------------------------
// Global Instances of above Packages-Classes
//---------------------------------------------------------
var
  //-- Package Instances (created in Initialization section)
  PACK_STR:Package_Str;

  PackageClassTStringGrid:ClassTStringGridPackage;
  PackageClassTFileStream:ClassTFileStreamPackage;


implementation
//---------------------------------------------------------
// Add all functions to internal list
//---------------------------------------------------------
procedure Package_Str.RegisterFunctions;
begin
  Methods.AddObject('Pos',TUserFuncObject.CreateWithName('Pos',pckg_Pos));
  Methods.AddObject('Copy',TUserFuncObject.CreateWithName('Copy',pckg_Copy));
  Methods.AddObject('CopyBuf',TUserFuncObject.CreateWithName('CopyBuf',pckg_CopyBuf));
  Methods.AddObject('ExtractFileName',TUserFuncObject.CreateWithName('ExtractFileName',pckg_ExtractFileName));
  Methods.AddObject('ExtractFilePath',TUserFuncObject.CreateWithName('ExtractFilePath',pckg_ExtractFilePath));
  Methods.AddObject('Length',TUserFuncObject.CreateWithName('Length',pckg_Length));
  Methods.AddObject('SetLength',TUserFuncObject.CreateWithName('SetLength',pckg_SetLength));
  Methods.AddObject('StringOfChar',TUserFuncObject.CreateWithName('StringOfChar',pckg_StringOfChar));

  Methods.AddObject('ExTrim',TUserFuncObject.CreateWithName('ExTrim',pckg_ExTrim));
  Methods.AddObject('ParseFields',TUserFuncObject.CreateWithName('ParseFields',pckg_ParseFields));
  Methods.AddObject('AnsiUpperCase',TUserFuncObject.CreateWithName('AnsiUpperCase',pckg_AnsiUpperCase));


  Methods.AddObject('isalpha',TUserFuncObject.CreateWithName('isalpha',pckg_isalpha));
  Methods.AddObject('isdigit',TUserFuncObject.CreateWithName('isdigit',pckg_isdigit));
  Methods.AddObject('isValidForIdentifier',TUserFuncObject.CreateWithName('isValidForIdentifier',pckg_isValidForIdentifier));
  Methods.AddObject('CharCode',TUserFuncObject.CreateWithName('CharCode',pckg_CharCode));
  Methods.AddObject('ToHex',TUserFuncObject.CreateWithName('ToHex',pckg_ToHex));
  Methods.AddObject('HexToNum',TUserFuncObject.CreateWithName('HexToNum',pckg_HexToNum));
  Methods.AddObject('HexToStrBuf',TUserFuncObject.CreateWithName('HexToStrBuf',pckg_HexToStrBuf));
  Methods.AddObject('StrBufToHex',TUserFuncObject.CreateWithName('StrBufToHex',pckg_StrBufToHex));
  Methods.AddObject('QuickSearch',TUserFuncObject.CreateWithName('QuickSearch',pckg_QuickSearch));

end;

//---------------------------------------------------------
// Pos wrapper
// Pos(Substring,InString)
//---------------------------------------------------------
function Package_Str.pckg_Pos(Params:TList): Integer;
var
 iR:Lua_Number;
 i:integer;
 S1,S2:String;
begin
  Result:=0;
  S1:=String(TXVariant(Params.Items[0]).V);
  S2:=String(TXVariant(Params.Items[1]).V);
  i:=Pos(S1,S2);
  iR:=i;

  TXVariant(Params.Items[0]).V:=iR; //-- return result
end;

//---------------------------------------------------------
// Copy wrapper:get part of string
// MyPart=str.Copy(MyStr);
// MyPart=str.Copy(MyStr,Pos);
// MyPart=str.Copy(MyStr,Pos,Count);
//---------------------------------------------------------
function Package_Str.pckg_Copy(Params:TList):integer;
var
 S:String;
 SSrc:String;
 Idx:Integer;
 ICount:Integer;
begin
  Result:=0;
  // Copy(S; Index, Count: Integer): string;
  SSrc:=String(TXVariant(Params.Items[0]).V);
  Idx:=1;
  ICount:=Length(SSrc);
  if(Params.Count > 1)then begin
     Idx:=TXVariant(Params.Items[1]).V;
     ICount:=ICount-Idx+1;
  end;
  if(Params.Count > 2)then begin
     ICount:=TXVariant(Params.Items[2]).V;
  end;

  S:=Copy(SSrc,Idx,ICount);
  TXVariant(Params.Items[0]).V:=S; //-- return result
end;

//---------------------------------------------------------
// Copy Buffer:set part of string from another string as
// copy memory.
// str.CopyBuf(DstStr,PosInDst,SrcStr);
// str.CopyBuf(DstStr,PosInDst,SrcStr,Count);
// str.CopyBuf(DstStr,PosInDst,SrcStr,PosInSrc,Count);
// NOTE:
//  Positions are 1-based (as in strings Str[1] - first char)
//  If PosInDst=-1 then append to Destination string applayed!
//---------------------------------------------------------
function Package_Str.pckg_CopyBuf(Params:TList):integer;
var
 SDst:String;
 SSrc:String;
 iDstPos:integer;
 iSrcPos:integer;
 iNChars:integer;
 pSrc:PChar;
 pDst:PChar;
 iLen:integer;
begin
  Result:=0;
  SDst:=TXVariant(Params.Items[0]).V;
  iDstPos:=TXVariant(Params.Items[1]).V;
  SSrc:=TXVariant(Params.Items[2]).V;

  iSrcPos:=0;
  iNChars:=0;

  if(Params.Count = 3)then begin
    iNChars:=Length(SSrc);
  end else if(Params.Count = 4)then begin
    iNChars:=TXVariant(Params.Items[3]).V;
  end else if(Params.Count = 5)then begin
    iSrcPos:=TXVariant(Params.Items[3]).V;
    iNChars:=TXVariant(Params.Items[4]).V;
    Dec(iSrcPos); //-- make zero based
  end;

  //--- Use append Src to Dst string ---
  if(iDstPos <= 0)then begin
    iDstPos:=Length(SDst);
    iLen:=iDstPos+iNChars;
    SetLength(SDst,iLen); //-- enhance length of Dst string
    Inc(iDstPos);
  end;

  pSrc:=PChar(SSrc)+iSrcPos;
  pDst:=PChar(SDst)+iDstPos-1;
  Move(pSrc^,pDst^,iNChars);
end;

//----------------------------------------------------------------
// ExtractFilePath
//----------------------------------------------------------------
function Package_Str.pckg_ExtractFilePath(Params:TList):integer;
var
 S:String;
begin
  Result:=0;
  S:=ExtractFilePath(String(TXVariant(Params.Items[0]).V));
  TXVariant(Params.Items[0]).V:=S; //-- return result
end;

//----------------------------------------------------------------
// ExtractFileName
//----------------------------------------------------------------
function Package_Str.pckg_ExtractFileName(Params:TList):integer;
var
 S:String;
begin
  Result:=0;
  S:=ExtractFileName(String(TXVariant(Params.Items[0]).V));
  TXVariant(Params.Items[0]).V:=S; //-- return result
end;

//----------------------------------------------------------------
// Get String Length
//----------------------------------------------------------------
function Package_Str.pckg_Length(Params:TList):integer;
var
 r:LUA_NUMBER;
begin
  Result:=0;
  r:=Length(String(TXVariant(Params.Items[0]).V));
  TXVariant(Params.Items[0]).V:=r; //-- return result
end;

//----------------------------------------------------------------
// Set Length of Stirng
// MyString=str.SetLength(MyString,10000);
//----------------------------------------------------------------
function Package_Str.pckg_SetLength(Params:TList):integer;
var
 S:String;
 r:LUA_NUMBER;
 NewLen:integer;
begin
  Result:=0;
  S:=String(TXVariant(Params.Items[0]).V);
  r:=TXVariant(Params.Items[1]).V;
  NewLen:=Trunc(r);
  SetLength(S,NewLen);
  S[NewLen]:=' ';
  TXVariant(Params.Items[0]).V:=S;
end;



//---------------------------------------------------------------------------------------------
// Extended Trim function:
//    ExTrim("xxxxStr",TrimMode);
//    ExTrim("xxxxStr",TrimMode,TrimChar1);
//    ExTrim("xxxxStr",TrimMode,TrimChar1,TrimChar2);
//
//    TrimMode:=0 or "LT"   -- Trim leading/trailing spaces
//    TrimMode:=1 or "All"  -- Trim spaces in all string leave only one from spaces sequence
//    TrimMode:=2 or "Full" -- Delete all occurances of spaces in string
//
//    TrimChar1,TrimChar2 - decimal code of deleted chars. By default it is space and Tab chars.
//---------------------------------------------------------------------------------------------
function Package_Str.pckg_ExTrim(Params:TList):integer;
var
 xStr:String;
 InSpaceBlock:boolean;
 i:integer;
 InStr:String;
 TrimMode:integer;
 TrimChar1:Char;
 TrimChar2:Char;
begin
    Result:=0;

    if(TXVariant(Params.Items[1]).VarType = varDouble)then begin
       TrimMode:=TXVariant(Params.Items[1]).V; //--- Mode as Numeric 0/1/2
    end else begin
       InStr:=String(TXVariant(Params.Items[1]).V);
       if(InStr[1] = 'L')then begin          //--- ExTrim(sdfsdf,"LEAD_TAIL")
          TrimMode:=0;
       end else if(InStr[1] = 'A')then begin //--- ExTrim(sdfsdf,"ALL")
          TrimMode:=1;
       end else if(InStr[1] = 'F')then begin //--- ExTrim(sdfsdf,"FULL")
          TrimMode:=2;
       end else begin
          Exit;
       end;
    end;

    TrimChar1:=#32; //--- Spaces
    TrimChar2:=#9;  //--- Tabulations

    //---If params contans first Char Code for delete (specified as decimal)--
    if(Params.Count > 2)then begin
       i:=TXVariant(Params.Items[2]).V;
       TrimChar1:=CHAR(i);
    end;

    //---If params contans second Char Code for delete (specified as decimal)--
    if(Params.Count > 3)then begin
       i:=TXVariant(Params.Items[3]).V;
       TrimChar2:=CHAR(i);
    end;

    //---- Get Input string for tream --------
    InStr:=String(TXVariant(Params.Items[0]).V);

    //--- if only leading/trailing spaces ----
    if(TrimMode = 0)then begin
       xStr:=Trim(InStr);
       TXVariant(Params.Items[0]).V:=xStr;
       Exit;
    end;

    //--- if all spaces/tabs ----
    InStr:=Trim(InStr);
    for i:=1 to Length(InStr) do begin
       if((InStr[i] <> TrimChar1) and (InStr[i] <> TrimChar2))then begin
         xStr:=xStr+InStr[i];
         InSpaceBlock:=false;
       end else begin
         if(not InSpaceBlock)then begin
          if(TrimMode = 1)then begin
           xStr:=xStr+' '; //--- copy only first space
          end;
          InSpaceBlock:=true;
         end;
       end;
    end;

    TXVariant(Params.Items[0]).V:=xStr;
end;




//--------------------------------------------------------
// Check first char of string for Alpha
//--------------------------------------------------------
function Package_Str.pckg_isalpha(Params:TList):integer;
var
 Res:boolean;
 c:char;
begin
  Result:=0;
  Res:=false;
  c:=String(TXVariant(Params.Items[0]).V)[1];
  case c of
      'a'..'z':
        Res:=true;
      'A'..'Z':
        Res:=true;
   else
        Res:=false;
   end;
   TXVariant(Params.Items[0]).V:=Res;
end;

//--------------------------------------------------------
// Check first char of string for Digit
//--------------------------------------------------------
function Package_Str.pckg_isdigit(Params:TList):integer;
var
 Res:boolean;
 c:char;
begin
  Result:=0;
  Res:=false;
  c:=String(TXVariant(Params.Items[0]).V)[1];
  case c of
      '0'..'9':
        Res:=true;
   else
        Res:=false;
   end;
   TXVariant(Params.Items[0]).V:=Res;
end;

//--------------------------------------------------------
// Check first char of string for Valid for Identificator
//--------------------------------------------------------
function Package_Str.pckg_isValidForIdentifier(Params:TList):integer;
var
 Res:boolean;
 c:char;
begin
  Result:=0;
  Res:=false;
  c:=String(TXVariant(Params.Items[0]).V)[1];
  case c of
      'a'..'z','A'..'Z','0'..'9','_':
        Res:=true;
   else
        Res:=false;
   end;
   TXVariant(Params.Items[0]).V:=Res;
end;

//--------------------------------------------------------
// Return Char code of first char of string
//--------------------------------------------------------
function Package_Str.pckg_CharCode(Params:TList):integer;
var
 c:char;
 Res:LUA_NUMBER;
begin
  Result:=0;
  c:=String(TXVariant(Params.Items[0]).V)[1];
  Res:=Ord(c);
  TXVariant(Params.Items[0]).V:=Res;
end;

//--------------------------------------------------------
// Return String Hex representation of Int part of number
// usage:
//    HexStr=str.ToHex(Val)
//or  HexStr=str.ToHex(Val,Digits)
//--------------------------------------------------------
function Package_Str.pckg_ToHex(Params:TList):integer;
var
 i64:Int64;
 Val:LUA_NUMBER;
 Ndigits:integer;
begin
  Result:=0;

  Ndigits:=8;
  if(Params.Count = 2)then begin
    Val:=TXVariant(Params.Items[1]).V;
    Ndigits:=Trunc(Val);
  end;

  Val:=TXVariant(Params.Items[0]).V;
  i64:=Trunc(Val);

  TXVariant(Params.Items[0]).V:=IntToHex(i64,Ndigits);
end;

//--------------------------------------------------------
// Return Numeric of String Hex representation.
// usage:
//    NumVal=str.HexToInt(Val)
//--------------------------------------------------------
function Package_Str.pckg_HexToNum(Params:TList):integer;
var
 i64:Int64;
 Val:LUA_NUMBER;
 S1:String;
begin
  Result:=0;

  S1:=TXVariant(Params.Items[0]).V;
  i64:=StrToInt64Def('$'+S1,0);
  Val:=i64;

  TXVariant(Params.Items[0]).V:=Val;
end;


//----------------------------------------------------------------
// Set Length of Stirng
// MyString=str.StringOfChar(" ",1000);
// MyString=str.StringOfChar(0,1000);
//----------------------------------------------------------------
function Package_Str.pckg_StringOfChar(Params:TList):integer;
var
 S:String;
 r:LUA_NUMBER;
 NewLen:integer;
 Ch1:Char;
 ChCode:Integer;
begin
  Result:=0;

  if(TXVariant(Params.Items[0]).VarType = varDouble)then begin
     ChCode:=TXVariant(Params.Items[0]).V; //--- get char code
     ChCode:=ChCode and $000000FF;
     Ch1:=Chr(BYTE(ChCode));
  end else begin
     Ch1:=String(TXVariant(Params.Items[0]).V)[1];
  end;

  S:=String(TXVariant(Params.Items[0]).V);
  r:=TXVariant(Params.Items[1]).V;
  NewLen:=Trunc(r);
  S:=StringOfChar(Ch1,NewLen);
  TXVariant(Params.Items[0]).V:=S;
end;


//---------------------------------------------------------------------------
// Convert Hex representation of Bytes to String internal buffer
// usage:
//    StrBuf=str.HexToStrBuf("F0101A1BFFF0101A1BFFF0101A1BFF...")
// Length of input str must have only hex digits and must have even length
//---------------------------------------------------------------------------
function Package_Str.pckg_HexToStrBuf(Params:TList):integer;
var
 S1:String;
 ActualLen:integer;
 pBuf:PChar;
 AllockedSize:integer;
begin
  Result:=0;
  S1:=TXVariant(Params.Items[0]).V;
  ActualLen:=ConvHexStringToByteArray(S1,pBuf,AllockedSize);
  SetLength(S1,ActualLen);
  Move(pBuf^,PChar(S1)^,ActualLen);
  FreeMem(pBuf,AllockedSize);
  TXVariant(Params.Items[0]).V:=S1;
end;



//---------------------------------------------------------------------------
// Quick Search substring in another using Bouer-Moore Search alghoritm
// usage:
//    SerachedPos=str.QuickSearch(StrWhereToFind,PosInStrWhereToFind,StrWhichFind)
//    SerachedPos=str.QuickSearch(StrWhereToFind,PosInStrWhereToFind,StrWhichFind,BoolCaseInsensitive)

// Pos is 1-based (S[1]-first char of string)
// Result: if <= 0 - not found, else pos in string where found
//---------------------------------------------------------------------------
function Package_Str.pckg_QuickSearch(Params:TList):integer;
var
 S1,WhatToSearchStr:String;
 iPos:integer;
 CaseInsens:boolean;
 SearchedIdx:integer;
 xTbl:ChrTable;
 PBuf:PChar;
 BufLen:integer;
 r:Lua_Number;
begin
  Result:=0;
  CaseInsens:=false; //-- normally case sensitive
  S1:=TXVariant(Params.Items[0]).V;
  iPos:=TXVariant(Params.Items[1]).V;
  Dec(iPos); //-- do zero based
  WhatToSearchStr:=TXVariant(Params.Items[2]).V;

  if(Params.Count = 4)then begin
    CaseInsens:=TXVariant(Params.Items[3]).V;
  end;

  PBuf:=PChar(S1)+iPos;
  BufLen:=Length(S1)-iPos;

  //--- Prepare for search ---------
  BMH_Search.MakeBMHTable(WhatToSearchStr,xTbl,CaseInsens);
  SearchedIdx:=BMH_Search.DoBMHSearchCase(WhatToSearchStr,PBuf,BufLen,xTbl,CaseInsens);
  if(SearchedIdx >= 0)then begin
     SearchedIdx:=SearchedIdx+iPos+1;
  end;
  //-- Return result as lua number ------
  r:=SearchedIdx;
  TXVariant(Params.Items[0]).V:=r;
end;

//---------------------------------------------------------------------------
// Convert Bytes in String to Hex representation (2 chars per Byte)
// usage:
//    HexStr=str.StrBufToHex(Str)
//    HexStr=str.StrBufToHex(Str,Pos)
//    HexStr=str.StrBufToHex(Str,Pos,Len)
//    HexStr=str.StrBufToHex(Str,Pos,Len,SpacesBetweenHexBytes)
//
// Pos is 1-based (S[1]-first char of string)
//---------------------------------------------------------------------------
function Package_Str.pckg_StrBufToHex(Params:TList):integer;
const HexDigs:array [0..15] of Char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
var
 S1:String;
 iPos,iLen:integer;
 pBuf:PChar;
 AllockedSize:integer;
 iB:Byte;
 SResult:String;
 HexC:Char;
 i,idx,SpaceIdx:integer;
 iSpaces:integer;
begin
  Result:=0;
  S1:=TXVariant(Params.Items[0]).V;
  iPos:=0;
  iLen:=Length(S1);
  SResult:='';
  iSpaces:=0;

  if(Params.Count = 2)then begin
    iPos:=TXVariant(Params.Items[1]).V-1;
  end else if(Params.Count = 3)then begin
    iPos:=TXVariant(Params.Items[1]).V-1;
    iLen:=TXVariant(Params.Items[2]).V;
  end else if(Params.Count = 4)then begin
    iPos:=TXVariant(Params.Items[1]).V-1;
    iLen:=TXVariant(Params.Items[2]).V;
    iSpaces:=TXVariant(Params.Items[3]).V;
  end;

  SetLength(SResult,iLen*(2+iSpaces)); //-- each byte as 2 chars---
  pBuf:=PChar(S1)+iPos;

  for i:=0 to iLen-1 do begin
     iB:=Byte(pBuf^);
     HexC:=HexDigs[(iB shr 4) and $0F]; //-- Upper byte tetrade first
     idx:=i*(2+iSpaces)+1;
     SResult[idx]:=HexC;

     HexC:=HexDigs[(iB and $0F)]; //-- Lower byte tetrade then
     SResult[idx+1]:=HexC;

     if(iSpaces > 0)then begin
       idx:=idx+2;
       SpaceIdx:=iSpaces;
       while(SpaceIdx > 0)do begin
         SResult[idx]:=' ';
         Inc(idx);
         Dec(SpaceIdx);
       end;
     end;

     Inc(pBuf);
  end;

  TXVariant(Params.Items[0]).V:=SResult;
end;







//-----------------------------------------------------------
// Helper function for search
//-----------------------------------------------------------
function xSearch(InString:String;Start:integer;SearchedString:String):integer;
var
    cp1:PChar;
    cp2:PChar;
    cpResult:PChar;
begin
     Result:=-1;

     if(Start > Length(InString))then begin
        Exit;
     end;

     cp1:=PChar(InString)+Start;
     cp2:=PChar(SearchedString);
     cpResult:=AnsiStrPos(cp1,cp2);
     if(cpResult <> Nil)then begin
        Result:=cpResult-PChar(InString)+1; //-- +1 for make result 1-based.
     end;
end;

//--------------------------------------------------------------------------
// Parse Specified String to FieldsList,
// using Delimiters list.
// Delimiters strings can contain more then one symbol
// eg.
// local DelimList={"(" , "," , "," ,")"};
// local ResultList=ParseFields("Myfunc(xxx,yyy,zzz)",DelimList);
// ResultList is StringList containing following strings
//  "Myfunc"
//  "xxx"
//  "yyy"
//  "zzz"
// Modifications:$VS26MAY2004
//  Add parameter logic:if function has 3 params then last delimiter used
//  in cycle..
//  For example: DelimList={","}
//  local ResultList=ParseFields("xxx,yyy,zzz",DelimList,true);
//  ResultList must contains strings:"xxx" "yyy" "zzz"
//--------------------------------------------------------------------------
function Package_Str.pckg_ParseFields(Params:TList):integer;
label lblFin;
var
 FoundPositions:TList;
 i,idx,curIdx:integer;
 SelString:String;
 StartPos:integer;
 PosAfterDelimiter:integer;
 FieldsList:TStringList;
 DelimitersList:TStringList;
 InternDelimitersList:boolean;
 pV:TXVariant;
 LastDelimiter:String;
 dLen:integer;
begin
   Result:=0;
   DelimitersList:=Nil;
   InternDelimitersList:=false;
   FoundPositions:=Nil;
   FieldsList:=TStringList.Create;
   if(NOT TXVariant(Params.Items[1]).IsObject)then begin
      TXVariant(Params.Items[0]).Ptr:=FieldsList; //--- return empty list
      Exit;
   end;
   //---- Fetch delimiters from LuaTable --------
   if(TObject(TXVariant(Params.Items[1]).Ptr) is TLuaTable )then begin
      InternDelimitersList:=true;
      DelimitersList:=TStringList.Create;
      FoundPositions:=TLuaTable(TXVariant(Params.Items[1]).Ptr).IndexedList;
      for i:=0 to FoundPositions.Count-1 do begin
         pV:=TXVariant(FoundPositions.Items[i]);
         DelimitersList.Add(String(pV.V));
      end;
      FoundPositions:=Nil;
   end else if(TObject(TXVariant(Params.Items[1]).Ptr) is TStringList)then begin
      //--- Else get String list
      DelimitersList:=TStringList(TXVariant(Params.Items[1]).Ptr);
   end;

   if((DelimitersList = Nil) or (DelimitersList.Count = 0))then begin
    goto lblFin;
   end;

   FoundPositions:=TList.Create;

   //--- Get Input string from params ------
   SelString:=String(TXVariant(Params.Items[0]).V);
   if(SelString = '')then goto lblFin;

   StartPos:=0;
   //--- find delimiters in string ------
   for i:=0 to DelimitersList.Count-1 do begin
      idx:=xSearch(SelString,StartPos,DelimitersList.Strings[i]);
      FoundPositions.Add(Pointer(idx));
      if(idx < 0)then Continue;
      PosAfterDelimiter:=idx+Length(DelimitersList.Strings[i]);
      StartPos:=PosAfterDelimiter-1; //-- because StartPos is 0-based
   end;

   //--- If last delimiter of table must be used multiple times ($VS26MAY2004)---
   LastDelimiter:=DelimitersList.Strings[DelimitersList.Count-1];
   if(Params.Count = 3)then begin
      //--- if last delimiter was found at least one time - search next --------
      if(integer(FoundPositions.Items[FoundPositions.Count-1]) > 0)then begin
        while(true)do begin
          idx:=xSearch(SelString,StartPos,LastDelimiter);
          if(idx < 0)then break;
          FoundPositions.Add(Pointer(idx));
          PosAfterDelimiter:=idx+Length(LastDelimiter);
          StartPos:=PosAfterDelimiter-1; //-- because StartPos is 0-based
        end;
      end;
   end;

   FoundPositions.Add(Pointer(Length(SelString)+1)); //--- Last virutal delimiter is always - end of string

   //--- Create Fields using positions of found delimiters ------
   if(FoundPositions.Count = 0)then  goto lblFin;

   idx:=1;
   for i:=0 to FoundPositions.Count-1 do begin
        curIdx:=integer(FoundPositions.Items[i]);
        if(idx = -1)then begin
          FieldsList.Add('');
        end else begin
          FieldsList.Add(Copy(SelString,idx,curIdx-idx));
        end;
        if(i < (FoundPositions.Count-1))then begin

         //--- Get Length of delimeter -----------
         if(i >= DelimitersList.Count)then begin //-- $VS26MAY2004
            //--- If last delimiter used many times ----
            dLen:=Length(LastDelimiter);
         end else begin
            //--- for next delimiter from list ----
            dLen:=Length(DelimitersList.Strings[i]);
         end;

         idx:=curIdx+dLen;
        end;
   end;

lblFin:
   if(FoundPositions <> Nil)then begin
      FoundPositions.Destroy;
   end;

   if(InternDelimitersList)then begin
      DelimitersList.Destroy;
   end;
   TXVariant(Params.Items[0]).Ptr:=FieldsList; //--- return empty list

end;

//-------------------------------------------------
//UpperString=str.AnsiUpperCase(String)
//-------------------------------------------------
function Package_Str.pckg_AnsiUpperCase(Params:TList):integer;
var
 S:String;
begin
  Result:=0;
  S:=AnsiUpperCase(String(TXVariant(Params.Items[0]).V));
  TXVariant(Params.Items[0]).V:=S; //-- return result
end;



//===========================================================================
// TStringGrid Package impl.
//===========================================================================
procedure ClassTStringGridPackage.RegisterFunctions;
begin
  Methods.AddObject('GetCols',TUserFuncObject.CreateWithName('GetCols',GetCols));
  Methods.AddObject('GetCell',TUserFuncObject.CreateWithName('GetCell',GetCell));
  Methods.AddObject('SetCell',TUserFuncObject.CreateWithName('SetCell',SetCell));
  Methods.AddObject('GetObject',TUserFuncObject.CreateWithName('GetObject',GetObject));
  Methods.AddObject('SetObject',TUserFuncObject.CreateWithName('SetObject',SetObject));
  Methods.AddObject('GetSelectionRect',TUserFuncObject.CreateWithName('GetSelectionRect',GetSelectionRect));
  Methods.AddObject('Clear',TUserFuncObject.CreateWithName('Clear',Clear));

  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));

  HandledProps:=TStringList.Create;
  HandledProps.Add('Row');
  HandledProps.Add('Col');
  HandledProps.Add('TopRow');
  HandledProps.Add('LeftCol');
  HandledProps.Add('VisibleRowCount');
  HandledProps.Add('VisibleColCol');

end;


//-------------------------------------------------------------------
// TStringGrod properties:
//  Row - get current row (also can use GetSelectionRect function)
//-------------------------------------------------------------------
function  ClassTStringGridPackage.HandleProperties(Params:TList):integer;
var
  xGrd:TObject;
  Cmd,PropName:String;
  R:LUA_NUMBER;
  i:integer;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    xGrd:=TStrings(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;         //-- Property name

    if(NOT (xGrd is TStringGrid))then begin
       raise Exception.Create('Attempt to use Property of non "TStringGrid" Object.');
    end;

    //----- "Row" property -------------------------
    if(PropName = 'Row')then begin
        if(Cmd = 'G')then begin
          R:=TStringGrid(xGrd).Row;
          TXVariant(Params.Items[3]).V:=R;
          Result:=1;
        end else begin
          i:=TXVariant(Params.Items[3]).V;
          TStringGrid(xGrd).Row:=i;
          Result:=1;
        end;
    end else if(PropName = 'Col')then begin
        if(Cmd = 'G')then begin
          R:=TStringGrid(xGrd).Col;
          TXVariant(Params.Items[3]).V:=R;
          Result:=1;
        end else begin
          i:=TXVariant(Params.Items[3]).V;
          TStringGrid(xGrd).Col:=i;
          Result:=1;
        end;
    end else if(PropName = 'TopRow')then begin
        if(Cmd = 'G')then begin
          R:=TStringGrid(xGrd).TopRow;
          TXVariant(Params.Items[3]).V:=R;
          Result:=1;
        end else begin
          i:=TXVariant(Params.Items[3]).V;
          TStringGrid(xGrd).TopRow:=i;
          Result:=1;
        end;
    end else if(PropName = 'LeftCol')then begin
        if(Cmd = 'G')then begin
          R:=TStringGrid(xGrd).LeftCol;
          TXVariant(Params.Items[3]).V:=R;
          Result:=1;
        end else begin
          i:=TXVariant(Params.Items[3]).V;
          TStringGrid(xGrd).LeftCol:=i;
          Result:=1;
        end;
    end else if(PropName = 'VisibleRowCount')then begin
        if(Cmd = 'G')then begin
          R:=TStringGrid(xGrd).VisibleRowCount;
          TXVariant(Params.Items[3]).V:=R;
          Result:=1;
        end;
    end else if(PropName = 'VisibleColCount')then begin
        if(Cmd = 'G')then begin
          R:=TStringGrid(xGrd).VisibleColCount;
          TXVariant(Params.Items[3]).V:=R;
          Result:=1;
        end;
    end;

end;


//------------------------------------------------------------
// xStrings=xGrid:GetCols(iCol);
//------------------------------------------------------------
function ClassTStringGridPackage.GetCols(Params:TList):Integer;
label
 lblErr,lblErr2;
var
 xStrings:TStrings;
 xObj:TObject;
begin
  Result:=0;

  if(Params.Count <> 2)then begin
     goto lblErr2;
  end;


  if(not TXVariant(Params.Items[0]).IsObject)then begin
     goto lblErr;
  end;
  xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
  if(not (xObj is TStringGrid))then begin
       goto lblErr;
  end;

  xStrings:=TStringGrid(xObj).Cols[integer(TXVariant(Params.Items[1]).V)];
  TXVariant(Params.Items[0]).ptr:=xStrings; //-- return result
  Exit;

lblErr:
    raise Exception.Create('Function:GetCell() called for non "TStringGrid" Object.');

lblErr2:
    raise Exception.Create('TStringGrid:GetCell() invalid number of parameters.');
end;


//------------------------------------------------------------
// S=xGrid:GetCell(iCol,iRow);
//------------------------------------------------------------
function ClassTStringGridPackage.GetCell(Params:TList):Integer;
label
 lblErr,lblErr2;
var
 S:String;
 xObj:TObject;
begin
  Result:=0;

  if(Params.Count <> 3)then begin
     goto lblErr2;
  end;


  if(not TXVariant(Params.Items[0]).IsObject)then begin
     goto lblErr;
  end;
  xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
  if(not (xObj is TStringGrid))then begin
       goto lblErr;
  end;

  S:=TStringGrid(xObj).Cells[integer(TXVariant(Params.Items[1]).V),integer(TXVariant(Params.Items[2]).V)];

  TXVariant(Params.Items[0]).V:=S; //-- return result
  Exit;

lblErr:
    raise Exception.Create('Function:GetCell() called for non "TStringGrid" Object.');

lblErr2:
    raise Exception.Create('TStringGrid:GetCell() invalid number of parameters.');
end;

//------------------------------------------------------------
// xGrid:SetCell(iCol,iRow,String);
//------------------------------------------------------------
function ClassTStringGridPackage.SetCell(Params:TList):Integer;
label
 lblErr,lblErr2;
var
 S:String;
 xObj:TObject;
begin
  Result:=0;

  if(Params.Count <> 4)then begin
     goto lblErr2;
  end;


  if(not TXVariant(Params.Items[0]).IsObject)then begin
     goto lblErr;
  end;

  xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
  if(not (xObj is TStringGrid))then begin
       goto lblErr;
  end;

  S:=String(TXVariant(Params.Items[3]).V);
  TStringGrid(xObj).Cells[integer(TXVariant(Params.Items[1]).V),
                          integer(TXVariant(Params.Items[2]).V)]:=S;

  Exit;

lblErr:
    raise Exception.Create('Function:SetCell() called for non "TStringGrid" Object.');

lblErr2:
    raise Exception.Create('TStringGrid:SetCell() invalid number of parameters.');

end;

//------------------------------------------------------------
function ClassTStringGridPackage.GetObject(Params:TList):Integer;
begin
  Result:=0;
end;

//------------------------------------------------------------
function ClassTStringGridPackage.SetObject(Params:TList):Integer;
begin
  Result:=0;
end;

//------------------------------------------------------------
// Input must be a Lua table with keys:
// xxx={Left,Top,Right,Bottom};
//------------------------------------------------------------
function ClassTStringGridPackage.GetSelectionRect(Params:TList): Integer;
label
 lblErr,lblErr2;
var
 xObj:TObject;
 xRect:TGridRect;
 xTbl:TLuaTable;
 //xStrList:TStringList;
 //Idx:integer;
 pKey:TXVariant;
 pVal:TXVariant;
 VDbl:Real;
begin
  Result:=0;

  if(not TXVariant(Params.Items[0]).IsObject)then begin
     goto lblErr;
  end;

  if(not TXVariant(Params.Items[1]).IsObject)then begin
     goto lblErr2;
  end;


  xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
  if(not (xObj is TStringGrid))then begin
       goto lblErr;
  end;

  xTbl:=TLuaTable(TXVariant(Params.Items[1]).Ptr);
  if(not (xTbl is TLuaTable))then begin
       goto lblErr2;
  end;


  xRect:=TStringGrid(xObj).Selection;

  //-- Get Table's String list (List of Keys)
  //xStrList:=xTbl.sList;

  pKey:=TXVariant.Create;
  pVal:=TXVariant.Create;

  pKey.V:='Left';
  pVal.V:=xRect.Left;
  xTbl.SetTableValue(pKey,pVal);

  pKey.V:='Top';
  VDbl:=xRect.Top;
  pVal.V:=VDbl;
  xTbl.SetTableValue(pKey,pVal);

  pKey.V:='Right';
  VDbl:=xRect.Right;
  pVal.V:=VDbl;
  xTbl.SetTableValue(pKey,pVal);

  pKey.V:='Bottom';
  VDbl:=xRect.Bottom;
  pVal.V:=VDbl;
  xTbl.SetTableValue(pKey,pVal);

  pKey.Free;
  pVal.Free;

  Exit; //-- OK

//------ err exits --------------
lblErr:
    raise Exception.Create('Function:SetCell() called for non "TStringGrid" Object.');

lblErr2:
    raise Exception.Create('TStringGrid:GetSelectionRect(param) -"param" must be a Table.');

end;

//------------------------------------------------------------
// xStrings=xGrid:GetCols(iCol);
//------------------------------------------------------------
function ClassTStringGridPackage.Clear(Params:TList):Integer;
label
 lblErr,lblErr2;
var
 xStrings:TStrings;
 xGrid:TStringGrid;
 xObj:TObject;
 i:integer;
begin
  Result:=0;

  if(Params.Count <> 1)then begin
     goto lblErr2;
  end;


  if(not TXVariant(Params.Items[0]).IsObject)then begin
     goto lblErr;
  end;
  xObj:=TObject(TXVariant(Params.Items[0]).Ptr);
  if(not (xObj is TStringGrid))then begin
       goto lblErr;
  end;

  xGrid:=TStringGrid(xObj);

  for i:=0 to xGrid.ColCount-1 do begin
    xStrings:=xGrid.Cols[i];
    xStrings.Clear;
  end;
  Exit;

  //---- Err handlers --

lblErr:
    raise Exception.Create('Function:GetCell() called for non "TStringGrid" Object.');

lblErr2:
    raise Exception.Create('TStringGrid:GetCell() invalid number of parameters.');
end;



//----------------------------------------------------------------------------------------
// Allocate Array of Bytes.
// Convert inStr - hex dump String to bytes in array.
// Return: actual Number of bytes in Array.
// pBuf:pointer to allocated buffer.
// AllockedSize is summary size of buffer. (Must be used in FreeMem(pBuf,AllockedSize);)
// NOTE:
//  You must free allocked buffer with "FreeMem(pBuf,AllockedSize);" after use it.
//----------------------------------------------------------------------------------------
function ConvHexStringToByteArray(inStr:String;var pBuf:PChar;var AllockedSize:integer):integer;
var
  Str:String;
  SummaryLength:integer;
  cpOut,xBuf:PByte;
  j:integer;
  ResultingByte:Byte;
  bit4Idx:integer;
  x4bits:Byte;
  xOrd0:Byte;
  xOrdA:Byte;
  ch1:Char;
begin
       //--- Get Next Hex string from List ---
       Str:=UpperCase(inStr); //??

       SummaryLength:=Length(Str) div 2; //-- assumed each byte is 2chars (Hex dump).
       GetMem(xBuf,SummaryLength);
       cpOut:=xBuf;

       //--- Write 00 Delta Time to output array ------
       ResultingByte:=0;
       bit4Idx:=0;
       xOrd0:=Ord('0');
       xOrdA:=Ord('A');

       //--- Scan char in String,scipping Blanks ---
       for j:=1 to Length(Str) do begin
         ch1:=Str[j];
         if(ch1 = ' ')then Continue;

         case ch1 of
           '0'..'9':
             x4bits:=Ord(ch1)-xOrd0;
           'A'..'F':
             x4bits:=10+Ord(ch1)-xOrdA;
            else
             x4bits:=0;
         end;//case

         if(bit4Idx = 0)then begin
            ResultingByte:=x4bits;
            Inc(bit4Idx);
         end else begin
            ResultingByte:=(ResultingByte shl 4) or x4bits;
            //--- Write Resulting byte to output array ------
            cpOut^:=ResultingByte;
            Inc(cpOut);

            ResultingByte:=0;
            bit4Idx:=0; //-- prepare for nex byte
         end;


       end;//for

       //--- return data to caller ------
       Result:=PChar(cpOut)-PChar(xBuf);
       pBuf:=pChar(xBuf);
       AllockedSize:=SummaryLength;
end;


//===========================================================================
// TStringGrid Package impl.
//===========================================================================
procedure ClassTFileStreamPackage.RegisterFunctions;
begin
  Methods.AddObject('Create',TUserFuncObject.CreateWithName('Create',xCreate));
  Methods.AddObject('Seek',TUserFuncObject.CreateWithName('Seek',xSeek));
  Methods.AddObject('Read',TUserFuncObject.CreateWithName('Read',xRead));
  Methods.AddObject('Write',TUserFuncObject.CreateWithName('Write',xWrite));
  Methods.AddObject('GetSize',TUserFuncObject.CreateWithName('GetSize',xGetSize));


  Methods.AddObject('HandleProperties',TUserFuncObject.CreateWithName('HandleProperties',HandleProperties));

  HandledProps:=TStringList.Create;
  //HandledProps.Add('Length');

end;

//------------------------------------------------------------
// local MyStream=TFileStream.Create("Fname",Access)
// Access: 1- read,2-write 1+2 - read/write
//------------------------------------------------------------
function ClassTFileStreamPackage.xCreate(Params:TList):Integer;
label
 lblErr,lblErr2;
var
 Fn:String;
 xMode:integer;
 r:Lua_Number;
 xAccess:Word;
 xStream:TFileStream;
begin
  Result:=0;

  Fn:=TXVariant(Params.Items[0]).V;

  xAccess:=fmOpenRead;

  if(Params.Count = 2)then begin
       r:=TXVariant(Params.Items[1]).V;
       xMode:=Trunc(r);
       if((xMode and 1) <> 0)then begin
          xAccess:=xAccess or fmOpenRead;
       end;
       if((xMode and 2) <> 0)then begin
          xAccess:=xAccess or fmOpenWrite;
       end;
  end;

  if(Not FileExists(Fn))then begin
     xAccess:=fmCreate;
  end;

  try
    xStream:=TFileStream.Create(Fn,(xAccess or fmShareDenyNone));
    TXVariant(Params.Items[0]).Ptr:=xStream;
  except
    raise;
  end;

  Exit;
  //---- Err handlers --

lblErr:
    raise Exception.Create('TFileStream.Create() error.');

lblErr2:
    raise Exception.Create('TFileStream.Create() invalid number of parameters.');
end;


//------------------------------------------------------------
// MyStream:Seek(1000)
// Do Seek in stream.Always from begining
//------------------------------------------------------------
function ClassTFileStreamPackage.xSeek(Params:TList):Integer;
var
 r:Lua_Number;

 xStream:TFileStream;
 Offset:LongInt;
begin
  Result:=0;

  xStream:=TFileStream(TXVariant(Params.Items[0]).Ptr);
  r:=TXVariant(Params.Items[1]).V;
  Offset:=Trunc(r);
  xStream.Seek(Offset,soFromBeginning);
end;

//------------------------------------------------------------
// StreamSize=MyStream:GetSize()
// Do Seek in stream.Always from begining
//------------------------------------------------------------
function ClassTFileStreamPackage.xGetSize(Params:TList):Integer;
var
 r:Lua_Number;
 xStream:TFileStream;
begin
  Result:=0;
  xStream:=TFileStream(TXVariant(Params.Items[0]).Ptr);
  r:=xStream.Size;
  TXVariant(Params.Items[0]).V:=r;
end;


//---------------------------------------------------------------------
// MyStr=MyStream:Read(1000)
// Try to read specified number of bytes from current pos into string (buffer)
//---------------------------------------------------------------------
function ClassTFileStreamPackage.xRead(Params:TList):Integer;
var
 S1:String;
 xStream:TFileStream;
 NBytes:LongInt;
 ActualNBytes:LongInt;
begin
  Result:=0;

  xStream:=TFileStream(TXVariant(Params.Items[0]).Ptr);
  NBytes:=TXVariant(Params.Items[1]).V;
  if(NBytes > xStream.Size)then begin
    NBytes:=xStream.Size;
  end;

  SetLength(S1,NBytes);
  ActualNBytes:=xStream.Read(PChar(S1)^,NBytes);
  if(ActualNBytes <> NBytes)then begin
     SetLength(S1,ActualNBytes);
  end;
  TXVariant(Params.Items[0]).V:=S1;
end;

//------------------------------------------------------------------
// Write from String(Buffer) to stream from it's current position.
// MyStream:Write(StrBuf)
// MyStream:Write(StrBuf,Size)
// MyStream:Write(StrBuf,Pos,Size)
//-------------------------------------------------------------------
function ClassTFileStreamPackage.xWrite(Params:TList):Integer;
label
 lblErr,lblErr2;
var
 r:Lua_Number;

 xStream:TFileStream;
 S1:String;
 iOffset:LongInt;
 iSize:LongInt;
 pS:PChar;
begin
  Result:=0;

  iOffset:=0;
  iSize:=0;

  xStream:=TFileStream(TXVariant(Params.Items[0]).Ptr);
  S1:=TXVariant(Params.Items[1]).V;
  iSize:=Length(S1);

  if(Params.Count = 3)then begin
     iSize:=TXVariant(Params.Items[2]).V;
  end else if(Params.Count = 4)then begin
     iOffset:=TXVariant(Params.Items[2]).V;
     iSize:=TXVariant(Params.Items[3]).V;
  end;
  pS:=PChar(S1)+iOffset;

  xStream.Write(pS^,iSize);
end;

//-------------------------------------------------------------------
// NOT WORK, because TFileStream not TPersistent!!!
// TFileStream properties:
//  "Size"
//-------------------------------------------------------------------
function  ClassTFileStreamPackage.HandleProperties(Params:TList):integer;
var
  xStream:TFileStream;
  Cmd,PropName:String;
  R:LUA_NUMBER;
  i:integer;
begin
    Result:=0;
    Cmd:=TXVariant(Params.Items[0]).V; //--Command: 'S' - set prop 'G' - get prop

    xStream:=TFileStream(TXVariant(Params.Items[1]).Ptr); //--- Object
    PropName:=TXVariant(Params.Items[2]).V;         //-- Property name

    //----- "Length" property -------------------------
    if(PropName = 'Size')then begin
        if(Cmd = 'G')then begin
          R:=xStream.Size;
          TXVariant(Params.Items[3]).V:=R;
          Result:=1;
        end else begin
          i:=TXVariant(Params.Items[3]).V;
          xStream.Size:=i;
          Result:=1;
        end;
    end;
end;

//=======================================================================
initialization
//--- Create string package -----
PACK_STR:=Package_Str.Create;
PACK_STR.RegisterFunctions;

PackageClassTStringGrid:=ClassTStringGridPackage.Create;
PackageClassTStringGrid.RegisterFunctions;

PackageClassTFileStream:=ClassTFileStreamPackage.Create;
PackageClassTFileStream.RegisterFunctions;

//--- Register this package -----
LuaInter.RegisterGlobalVar('str',PACK_STR);
LuaInter.RegisterGlobalVar('TStringGrid',PackageClassTStringGrid);
LuaInter.RegisterGlobalVar('TFileStream',PackageClassTFileStream);

end.

