//-----------------------------------------
// Unit for work with Windows mapped files
// Author: Sergei Vertiev: Moscow 2002.
//-----------------------------------------
unit MappedFile;

interface

uses
  Windows, Messages, SysUtils, Classes;


const MAP_PORTION_SIZE=2000000; //-- 10 Mbyte mapping portion size

//------ Structure for Open and Map files into Memeory ----
type TMapFileInfo=class(TObject)
   FileName:PChar;
   FHandle:THANDLE ;
   hMapping:THANDLE ;
   //pView:PChar;

   FileLowSize:DWORD;
   FileSize:Int64;

   pViewStart:PChar;
   pViewEnd:PChar;

   pViewStartOffset:DWORD; //----calculated real offset in file where partial mapping starts
   pViewEndOffset:DWORD;   //----calculated real offset in file where partial mapping ends

   //pFileStart:PChar;
   //pFileEnd:PChar;

   dwSysGran:DWORD; //-- system granularity for need for file partially mapping
end;

function OpenAndMapFile(FileInfo:TMapFileInfo):PChar;
function AssertMapForOffset(FileInfo:TMapFileInfo;xFileOffset:DWORD):PChar;
function CloseMappedFile(FileInfo:TMapFileInfo):integer;

implementation
//---------------------------------------------------------------------------
// Open And map file using MapFileInfo structure
// NOTE: this function opens file in READONLY mode
//---------------------------------------------------------------------------
function OpenAndMapFile(FileInfo:TMapFileInfo):PChar;
var
  SysInfo:SYSTEM_INFO;
begin

    Result:=NIL;
    if(FileInfo = NIL)then Exit;

    FileInfo.pViewStart:=NIL;

    FileInfo.FHandle:=CreateFile(FileInfo.FileName, GENERIC_READ, FILE_SHARE_READ, NIL, OPEN_EXISTING, FILE_ATTRIBUTE_READONLY or FILE_FLAG_SEQUENTIAL_SCAN, 0);

    if(FileInfo.FHandle <> INVALID_HANDLE_VALUE)then begin
       FileInfo.hMapping:=CreateFileMapping(FileInfo.FHandle, NIL, PAGE_READONLY, 0, 0, NIL);
       if (FileInfo.hMapping <> 0)then begin
            //--- First get and save System granularity
            //--- which needs for file partially mapping
            GetSystemInfo(SysInfo);
            FileInfo.dwSysGran:=SysInfo.dwAllocationGranularity;
            //--- Set Available file size ----------
            FileInfo.FileLowSize:=GetFileSize(FileInfo.FHandle,@(FileInfo.FileSize));

            //--- Try to Map first portion of file. All calculations are in AssertMapForOffset function
            if(AssertMapForOffset(FileInfo,0) = NIL)then begin
              CloseHandle(FileInfo.hMapping);
              CloseHandle(FileInfo.FHandle);
            end;
       end else begin
          CloseHandle(FileInfo.FHandle);
      end;
    end;
    Result:=FileInfo.pViewStart;
end;

//---------------------------------------------------------------------------
// Remap portion of file using specified pointer
// If succes -
//  return pointer to specified offset of mapped file.
// Else - return NIL
//---------------------------------------------------------------------------
function AssertMapForOffset(FileInfo:TMapFileInfo;xFileOffset:DWORD):PChar;
var
 dwMapViewSize:DWORD;
begin
     if((xFileOffset >= FileInfo.pViewStartOffset) and
        (xFileOffset <  FileInfo.pViewEndOffset))then begin

        //--- calculate pointer from offsets---
        Result:=FileInfo.pViewStart+(xFileOffset-FileInfo.pViewStartOffset);
        Exit;
     end;

     UnmapViewOfFile(FileInfo.pViewStart);
     FileInfo.pViewStart:=Nil;
     FileInfo.pViewEnd:=Nil;

     //--- calculate where real start of mapping will be
     //--- with granularity
     FileInfo.pViewStartOffset:=(xFileOffset div FileInfo.dwSysGran) * FileInfo.dwSysGran;

     //---- Calculate real size of the file mapping view with granularity
     dwMapViewSize:=(xFileOffset mod FileInfo.dwSysGran) + MAP_PORTION_SIZE;

     //--- Check if we demand map beyond EOF -----
     if((FileInfo.pViewStartOffset + dwMapViewSize) > FileInfo.FileLowSize)then begin
         dwMapViewSize:=FileInfo.FileLowSize-FileInfo.pViewStartOffset;
     end;

     //--- Try to Map this part --------------
     FileInfo.pViewStart:= MapViewOfFile(FileInfo.hMapping,
                                         FILE_MAP_READ,0,
                                         FileInfo.pViewStartOffset,
                                         dwMapViewSize);

     //--- Exit if ERROR  -------
     if(FileInfo.pViewStart = NIL)then begin
        Result:=NIL;
        EXIT;
     end;

     //--- Save info in FileInfo struct -----
     FileInfo.pViewEnd:=FileInfo.pViewStart+dwMapViewSize;
     FileInfo.pViewEndOffset:=FileInfo.pViewStartOffset+dwMapViewSize;

     //--- calculate pointer from offsets---
     Result:=FileInfo.pViewStart+(xFileOffset-FileInfo.pViewStartOffset);
end;


//---------------------------------------------------------------------------
// Close mapped file using MapFileInfo structure
//---------------------------------------------------------------------------
function CloseMappedFile(FileInfo:TMapFileInfo):integer;
begin
    Result:=-1;
    if(FileInfo = Nil)then Exit;
    if(FileInfo.pViewStart <> Nil)then begin
       UnmapViewOfFile(FileInfo.pViewStart);
       FileInfo.pViewStart:=Nil;
       FileInfo.pViewStartOffset:=0;
       FileInfo.pViewEndOffset:=0;
    end;

    if(FileInfo.hMapping <> 0)then begin
      CloseHandle(FileInfo.hMapping);
      FileInfo.hMapping:=0;
    end;
end;

end.
