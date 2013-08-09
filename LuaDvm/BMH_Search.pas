unit BMH_Search;

interface
uses Windows,SysUtils, Classes;

//---- Functions and types for Boyer-Moore quick search algorithm (case-sensitive ASCII search in buffer)
type ChrTable = array [0..255]of Byte; //----- search-jump table definition

function  DoBMHSearchCase(StrToFind:AnsiString;pBuf:PChar;BufLen:integer;var BMHTable:ChrTable;CaseInsensitive:boolean):integer;
function  DoBMHSearch(StrToFind:AnsiString;pBuf:PChar;BufLen:integer;var BMHTable:ChrTable;var CharCaseArray:ChrTable):integer;
procedure MakeBMHTable(StrToFind:AnsiString;var BMHTable:ChrTable;CaseInSensitive:boolean);
function  UpperCaseStrEqueal(xUprCaseStr:String;OtherString:String):boolean;

var
  UpperCharsArray:ChrTable;
  NormalCharsArray:ChrTable;

implementation
var
  xxxIdx:Byte;

function  DoBMHSearchCase(StrToFind:AnsiString;pBuf:PChar;BufLen:integer;var BMHTable:ChrTable;CaseInsensitive:boolean):integer;
begin
      if(CaseInsensitive)then begin
        Result:=DoBMHSearch(StrToFind,pBuf,BufLen,BMHTable,UpperCharsArray);
      end else begin
        Result:=DoBMHSearch(StrToFind,pBuf,BufLen,BMHTable,NormalCharsArray);
      end;
end;


//--------------------------------------------------------------------------
// Performs the Boyer-Moore string searching alghorithm, returning
// the offset in buffer where the string was found.  If not found, then
// -1 is returned.  Adapted from the 'Handbook of Algorithms and Data
// Structures in Pascal and C', Second Edition, by G.H Gonnet and
// R. Baeza-Yates.
//
// BMHTable - table previously created with MakeBMHTable function
// CharCaseArray - table one of   UpperCharsArray or NormalCharsArray
//
// For CaseInsensitive search:
//   StrToFind must be UpperCase
//   UpperCharsArray must be specified as CharCaseArray
//
// For CaseSensitive search:
//   StrToFind - as it is
//   UpperCharsArray must be specified as NormalCharsArray
//--------------------------------------------------------------------------
function  DoBMHSearch(StrToFind:AnsiString;pBuf:PChar;BufLen:integer;var BMHTable:ChrTable;var CharCaseArray:ChrTable):integer;
label
 NotFound;
var
  I, J, K, SLen:integer;
begin
  SLen:=Length(StrToFind);
  J:=SLen-1;
  while(J < BufLen)do begin
    I:= J;
    for K:=SLen-1 downto 0 do begin
      if(CharCaseArray[BYTE((pBuf+I)^)] <> BYTE(StrToFind[K+1]))then begin
          goto NotFound;
      end;
      Dec(I);
    end;
    //--- Sucessfull search return index of start of string
    Result:=I+1;
    Exit;

   NotFound:
     //----- Jump for number of symbols defined from table (BMHTable) prepared before
     J:=J+Integer(BMHTable[CharCaseArray[Integer((pBuf+J)^)]]);
  end;

  //----- Not found - exit --------
  Result:=-1;
end;

//----------------------------------------------------------------------
// Creates a Boyer-Moore-Horspool index table for the search string
// StrToFind in the table BMHTable.  This MUST be called before
// the string is searched for.  But it only needs to be called once
// for each different string.
//----------------------------------------------------------------------
procedure MakeBMHTable(StrToFind:AnsiString;var BMHTable:ChrTable;CaseInSensitive:boolean);
var
 SLen:integer;
 ich,i:integer;
begin
  SLen:=Length(StrToFind);
  for i:=0 to 255 do begin
     BMHTable[i]:=Byte(SLen);
  end;

  for i:=0 to SLen-2 do begin  //-- -2 because last symbol is already set to value SLen
      ich:=integer(StrToFind[i+1]);

      if(CaseInSensitive)then begin
        ich:=UpperCharsArray[ich];
      end;

      BMHTable[ich]:=Byte(SLen-i-1);
  end;

end;


//--------------------------------------------------
// Compare Stings uppercase
// Assumed that first string (xUprCaseStr) is
// already UpperCase
//--------------------------------------------------
function UpperCaseStrEqueal(xUprCaseStr:String;OtherString:String):boolean;
var
  i:integer;
  Len:integer;
begin
    Result:=false; //--- assume unequeal
    Len:=Length(xUprCaseStr);
    if(Len <> Length(OtherString))then begin
       Exit;
    end;
    for i:=1 to Len do begin
       if(BYTE(xUprCaseStr[i]) <> UpperCharsArray[BYTE(OtherString[i])])then begin
          EXIT;
       end;
    end;
    Result:=true;
end;



initialization
begin
     for xxxIdx:=0 to 255 do begin
         NormalCharsArray[xxxIdx]:=xxxIdx;
         UpperCharsArray[xxxIdx]:=BYTE(UpCase(Char(xxxIdx)));
     end;
end;

end.
