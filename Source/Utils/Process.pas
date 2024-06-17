// https://github.com/leehoegyu/process

unit Process;

interface

{$R-}
{$Q-}

uses
  Winapi.Windows, System.SysUtils;

type
  TProcess = class
  private
    FId: DWORD;
    FHandle: THandle;
    FWow64: Boolean;
    FInstance: HMODULE;
    FSectionHeaders: TArray<TImageSectionHeader>;
    FProcessEnvironmetBlock: Pointer;
    FLdr: Pointer;
    function GetSectionHeader(SectionName: PAnsiChar): PImageSectionHeader;
    function GetModuleHandle32(lpModuleName: PWideChar): HMODULE;
    function GetModuleHandle64(lpModuleName: PWideChar): HMODULE;
    function GetProcAddress32(hModule: HMODULE; lpProcName: LPCSTR): FARPROC;
    function GetProcAddress64(hModule: HMODULE; lpProcName: LPCSTR): FARPROC;
    function GetModule(Address: SIZE_T): HMODULE;
  public
    property Id: DWORD read FId;
    property Handle: THandle read FHandle;
    property SectionHeader[SectionName: PAnsiChar]: PImageSectionHeader read GetSectionHeader;
    function Is64Bit: Boolean; inline;
    function IsRunning: Boolean;
    property hInstance: HMODULE read FInstance;
    property EnvironmentBlock: Pointer read FProcessEnvironmetBlock;
    property Ldr: Pointer read FLdr;
    function RvaToVa(Rva: SIZE_T): SIZE_T;
    function Read(Address: Pointer; Buffer: Pointer; Size: SIZE_T): Boolean; overload;
    function Read(Address: SIZE_T; Buffer: Pointer; Size: SIZE_T): Boolean; overload;
    function Read<T>(Address: Pointer): T; overload;
    function Read<T>(Address: SIZE_T): T; overload;
    function Write(Address: Pointer; Buffer: Pointer; Size: SIZE_T): Boolean; overload;
    function Write(Address: SIZE_T; Buffer: Pointer; Size: SIZE_T): Boolean; overload;
    function Write<T>(Address: Pointer; Buffer: T): Boolean; overload;
    function Write<T>(Address: SIZE_T; Buffer: T): Boolean; overload;
    function AllocateMemory(Size: SIZE_T): Pointer;
    function FreeMemory(Address: Pointer): Boolean;
    function GetModuleHandle(lpModuleName: PWideChar): HMODULE;
    function GetProcAddress(hModule: HMODULE; lpProcName: LPCSTR): FARPROC;
    function GetClassName(Address: Pointer): string; overload;
    function GetClassName(Address: SIZE_T): string; overload;
    function GetVersion: string;
    function CreateThread(lpStartAddress: Pointer; lpParameter: Pointer; dwCreationFlags: Cardinal; var lpThreadId: Cardinal): THandle;
    constructor Create(ProcessId: DWORD);
    destructor Free;
  end;

implementation

type
  PROCESS_BASIC_INFORMATION = packed record
    Reserved1: Pointer;
    PebBaseAddress: Pointer;
    Reserved2: array [0..1] of Pointer;
    UniqueProcessId: ULONG_PTR;
    Reserved3: Pointer;
  end;

  UNICODE_STRING = record
    Length: USHORT;
    MaximumLength: USHORT;
    Buffer: Pointer;
  end;

  _PEB_LDR_DATA = record
    Length: ULONG;
    Initialized: Boolean;
    SsHandle: Pointer;
    InLoadOrderModuleList: LIST_ENTRY;
    InMemoryOrderModuleList: LIST_ENTRY;
    InInitializationOrderModuleList: LIST_ENTRY;
  end;

  _LDR_DATA_TABLE_ENTRY = record
    InMemoryOrderLinks: LIST_ENTRY;
    Reserved1: array[0..1]of Pointer;
    DllBase: Pointer;
    EntryPoint: Pointer;
    SizeOfImage: SIZE_T;
    FullDllName: UNICODE_STRING;
    BaseDllName: UNICODE_STRING;
  end;

  UNICODE_STRING32 = record
    Length: USHORT;
    MaximumLength: USHORT;
    Buffer: DWORD;
  end;

  _PEB_LDR_DATA32 = record
    Length: ULONG;
    Initialized: Boolean;
    SsHandle: ULONG;
    InLoadOrderModuleList: LIST_ENTRY32;
    InMemoryOrderModuleList: LIST_ENTRY32;
    InInitializationOrderModuleList: LIST_ENTRY32;
  end;

  _LDR_DATA_TABLE_ENTRY32 = record
    InMemoryOrderLinks: LIST_ENTRY32;
    Reserved1: array[0..1]of DWORD;
    DllBase: DWORD;
    EntryPoint: DWORD;
    SizeOfImage: ULONG;
    FullDllName: UNICODE_STRING32;
    BaseDllName: UNICODE_STRING32;
  end;

  _IMAGE_RESOURCE_DIRECTORY = record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: Word;
    MinorVersion: Word;
    NumberOfNamedEntries: Word;
    NumberOfIdEntries: Word;
  end;

  _IMAGE_RESOURCE_DATA_ENTRY = record
    OffsetToData: DWORD;
    Size: DWORD;
    CodePage: DWORD;
    Reserved: DWORD;
  end;

  _IMAGE_RESOURCE_DIRECTORY_ENTRY = record
    case Integer of
      0: (
        NameOffset: DWORD;
        OffsetToData: DWORD
      );
      1: (
        Name: DWORD;
        OffsetToDirectory: DWORD;
      );
      2: (
        Id: WORD;
      );
  end;
  PIMAGE_RESOURCE_DIRECTORY_ENTRY = ^IMAGE_RESOURCE_DIRECTORY_ENTRY;
  IMAGE_RESOURCE_DIRECTORY_ENTRY = _IMAGE_RESOURCE_DIRECTORY_ENTRY;

function NtQueryInformationProcess(ProcessHandle: THandle; ProcessInformationClass: DWORD; ProcessInformation: Pointer;
  ProcessInformationLength: ULONG; ReturnLength: PULONG): LongInt; stdcall; external 'ntdll.dll';

function TProcess.GetSectionHeader(SectionName: PAnsiChar): PImageSectionHeader;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(FSectionHeaders) do
    if AnsiString(SectionName) = PAnsiChar(@FSectionHeaders[i].Name) then
      Exit(@FSectionHeaders[i]);
end;

function TProcess.Is64Bit: Boolean;
begin
  Result := not FWow64;
end;

function TProcess.IsRunning: Boolean;
begin
  Result := WaitForSingleObject(Handle, 0) = WAIT_TIMEOUT;
end;

function TProcess.RvaToVa(Rva: SIZE_T): SIZE_T;
begin
  Result := hInstance + Rva;
end;

function TProcess.Read(Address: Pointer; Buffer: Pointer; Size: SIZE_T): Boolean;
begin
  Result := ReadProcessMemory(Handle, Address, Buffer, Size, PSIZE_T(nil)^);
end;

function TProcess.Read(Address: SIZE_T; Buffer: Pointer; Size: SIZE_T): Boolean;
begin
  Result := Read(Pointer(Address), Buffer, Size);
end;

function TProcess.Read<T>(Address: Pointer): T;
begin
  if not Read(Address, @Result, SizeOf(T)) then
    ZeroMemory(@Result, SizeOf(T));
end;

function TProcess.Read<T>(Address: SIZE_T): T;
begin
  Result := Self.Read<T>(Pointer(Address));
end;

function TProcess.GetModuleHandle32(lpModuleName: PWideChar): HMODULE;
var
  head: Pointer;
  cur: _LDR_DATA_TABLE_ENTRY32;
  DllName: array[0..MAX_PATH]of Char;
begin
  Result := 0;
  cur := Self.Read<_LDR_DATA_TABLE_ENTRY32>(Self.Read<_PEB_LDR_DATA32>(Ldr).InMemoryOrderModuleList.Flink);
  head := Pointer(cur.InMemoryOrderLinks.Blink);
  while Pointer(cur.InMemoryOrderLinks.Flink) <> head do
  begin
    Read(cur.BaseDllName.Buffer, @DllName, cur.BaseDllName.Length);
    DllName[cur.BaseDllName.Length div 2] := #0;
    if lpModuleName = UpperCase(DllName) then
      Exit(HMODULE(cur.DllBase));
    cur := Self.Read<_LDR_DATA_TABLE_ENTRY32>(cur.InMemoryOrderLinks.Flink);
  end;
end;

function TProcess.Write(Address: Pointer; Buffer: Pointer; Size: SIZE_T): Boolean;
begin
  Result := WriteProcessMemory(Handle, Address, Buffer, Size, PSIZE_T(nil)^);
end;

function TProcess.Write(Address: SIZE_T; Buffer: Pointer; Size: SIZE_T): Boolean;
begin
  Result := Write(Pointer(Address), Buffer, Size);
end;

function TProcess.Write<T>(Address: Pointer; Buffer: T): Boolean;
begin
  Result := Write(Address, @Buffer, SizeOf(Buffer));
end;

function TProcess.Write<T>(Address: SIZE_T; Buffer: T): Boolean;
begin
  Result := Write(Address, @Buffer, SizeOf(Buffer));
end;

function TProcess.AllocateMemory(Size: SIZE_T): Pointer;
begin
  Result := VirtualAllocEx(Handle, nil, Size, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
end;

function TProcess.FreeMemory(Address: Pointer): Boolean;
begin
  Result := VirtualFreeEx(Handle, Address, 0, MEM_RELEASE);
end;

function TProcess.GetModuleHandle64(lpModuleName: PWideChar): HMODULE;
var
  head: Pointer;
  cur: _LDR_DATA_TABLE_ENTRY;
  DllName: array[0..MAX_PATH]of Char;
begin
  Result := 0;
  cur := Self.Read<_LDR_DATA_TABLE_ENTRY>(Self.Read<_PEB_LDR_DATA>(Ldr).InMemoryOrderModuleList.Flink);
  head := cur.InMemoryOrderLinks.Blink;
  while cur.InMemoryOrderLinks.Flink <> head do
  begin
    Read(cur.BaseDllName.Buffer, @DllName, cur.BaseDllName.Length);
    DllName[cur.BaseDllName.Length div 2] := #0;
    if lpModuleName = UpperCase(DllName) then
      Exit(HMODULE(cur.DllBase));
    cur := Self.Read<_LDR_DATA_TABLE_ENTRY>(cur.InMemoryOrderLinks.Flink);
  end;
end;

function TProcess.GetModuleHandle(lpModuleName: PWideChar): HMODULE;
begin
  if Is64Bit then
    Result := GetModuleHandle64(PChar(UpperCase(lpModuleName)))
  else
    Result := GetModuleHandle32(PChar(UpperCase(lpModuleName)));
end;

function TProcess.GetProcAddress32(hModule: HMODULE; lpProcName: LPCSTR): FARPROC;
var
  i: Integer;
  DosHeader: TImageDosHeader;
  NtHeaders: TImageNtHeaders32;
  ExportDirectory: TImageExportDirectory;
  ExportDirectoryRva, FunctionNameRva, FunctionRva: DWORD;
  Ordinal: Word;
  FunctionName: array[0..MAX_PATH - 1]of AnsiChar;
begin
  Result := nil;
  DosHeader := Self.Read<TImageDosHeader>(hModule);
  if DosHeader.e_magic <> IMAGE_DOS_SIGNATURE then
    Exit;
  NtHeaders := Self.Read<TImageNtHeaders32>(hModule + SIZE_T(DosHeader._lfanew));
  if NtHeaders.Signature <> IMAGE_NT_SIGNATURE then
    Exit;
  ExportDirectoryRva := NtHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
  if ExportDirectoryRva = 0 then
    Exit;
  ExportDirectory := Self.Read<TImageExportDirectory>(hModule + ExportDirectoryRva);
  if SIZE_T(lpProcName) > 65535 then
  begin
    for i := 0 to ExportDirectory.NumberOfNames - 1 do
    begin
      ZeroMemory(@FunctionName, MAX_PATH);
      FunctionNameRva := Self.Read<DWORD>(hModule + ExportDirectory.AddressOfNames + DWORD(i * 4));
      Self.Read(hModule + FunctionNameRva, @FunctionName, MAX_PATH);
      if UpperCase(string(FunctionName)) = UpperCase(string(lpProcName)) then
      begin
        Ordinal := Self.Read<Word>(hModule + ExportDirectory.AddressOfNameOrdinals + DWORD(i * 2));
        FunctionRva := Self.Read<DWORD>(hModule + ExportDirectory.AddressOfFunctions + (Ordinal * 4));
        Result := Pointer(hModule + FunctionRva);
        Break;
      end;
    end;
  end
  else
  begin
    Ordinal := Word(lpProcName);
    if Ordinal >= ExportDirectory.NumberOfFunctions then
      Exit;
    FunctionRva := Self.Read<DWORD>(hModule + ExportDirectory.AddressOfFunctions + (Ordinal * 4));
    Result := Pointer(hModule + FunctionRva);
  end;
end;

function TProcess.GetProcAddress64(hModule: HMODULE; lpProcName: LPCSTR): FARPROC;
var
  i: Integer;
  DosHeader: TImageDosHeader;
  NtHeaders: TImageNtHeaders;
  ExportDirectory: TImageExportDirectory;
  ExportDirectoryRva, FunctionNameRva, FunctionRva: DWORD;
  Ordinal: Word;
  FunctionName: array[0..MAX_PATH - 1]of AnsiChar;
begin
  Result := nil;
  DosHeader := Self.Read<TImageDosHeader>(hModule);
  if DosHeader.e_magic <> IMAGE_DOS_SIGNATURE then
    Exit;
  NtHeaders := Self.Read<TImageNtHeaders>(hModule + SIZE_T(DosHeader._lfanew));
  if NtHeaders.Signature <> IMAGE_NT_SIGNATURE then
    Exit;
  ExportDirectoryRva := NtHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
  if ExportDirectoryRva = 0 then
    Exit;
  ExportDirectory := Self.Read<TImageExportDirectory>(hModule + ExportDirectoryRva);
  if SIZE_T(lpProcName) > 65535 then
  begin
    for i := 0 to ExportDirectory.NumberOfNames - 1 do
    begin
      ZeroMemory(@FunctionName, MAX_PATH);
      FunctionNameRva := Self.Read<DWORD>(hModule + ExportDirectory.AddressOfNames + DWORD(i * 4));
      Self.Read(hModule + FunctionNameRva, @FunctionName, MAX_PATH);
      if UpperCase(string(FunctionName)) = UpperCase(string(lpProcName)) then
      begin
        Ordinal := Self.Read<Word>(hModule + ExportDirectory.AddressOfNameOrdinals + DWORD(i * 2));
        FunctionRva := Self.Read<DWORD>(hModule + ExportDirectory.AddressOfFunctions + (Ordinal * 4));
        Result := Pointer(hModule + FunctionRva);
        Break;
      end;
    end;
  end
  else
  begin
    Ordinal := Word(lpProcName);
    if Ordinal >= ExportDirectory.NumberOfFunctions then
      Exit;
    FunctionRva := Self.Read<DWORD>(hModule + ExportDirectory.AddressOfFunctions + (Ordinal * 4));
    Result := Pointer(hModule + FunctionRva);
  end;
end;

function TProcess.GetProcAddress(hModule: HMODULE; lpProcName: LPCSTR): FARPROC;
begin
  if Is64Bit then
    Result := GetProcAddress64(hModule, lpProcName)
  else
    Result := GetProcAddress32(hModule, lpProcName);
end;

function TProcess.GetModule(Address: SIZE_T): SIZE_T;
var
  mbi: TMemoryBasicInformation;
begin
  Result := 0;
  if VirtualQueryEx(Handle, Pointer(Address), mbi, SizeOf(mbi)) <> 0 then
    Result := HMODULE(mbi.AllocationBase);
end;

function TProcess.GetClassName(Address: Pointer): string;
var
  vTable, Rtti, Va: SIZE_T;
  Size: Integer;
  RttiRecord: record
    _Type: Integer;
    Reserved1: array[0..1]of DWORD;
    Va: DWORD;
  end;
  Info32: record
    Reserved1: array[0..1]of DWORD;
    Name: array[0..MAX_PATH]of AnsiChar;
  end;
  Info64: record
    Reserved1: array[0..1]of DWORD64;
    Name: array[0..MAX_PATH]of AnsiChar;
  end;
begin
  Result := '';
  if not Is64Bit then
    Size := 4
  else
    Size := 8;
  Rtti := 0;
  vTable := 0;
  if not Read(Address, @vTable, Size) then
    Exit;
  if not Read(vTable - SIZE_T(Size), @Rtti, Size) then
    Exit;
  if not Read(Rtti, @RttiRecord, SizeOf(RttiRecord)) then
    Exit;
  if RttiRecord._Type = 1 then
    Va := GetModule(Rtti) + RttiRecord.Va
  else
    Va := RttiRecord.Va;

  if not Is64Bit then
  begin
    if not Read(Va, @Info32, SizeOf(Info32)) then
      Exit;
    Result := string(Info32.Name);
  end
  else
  begin
    if not Read(Va, @Info64, SizeOf(Info64)) then
      Exit;
    Result := string(Info64.Name);
  end;
  if Copy(Result, 1, 4) = '.?AV' then
    Result := Copy(Result, 5, Length(Result) - 6);
end;

function TProcess.GetClassName(Address: SIZE_T): string;
begin
  Result := GetClassName(Pointer(Address));
end;

function TProcess.GetVersion: string;
var
  i, j, k: SIZE_T;
  DosHeader: TImageDosHeader;
  ResourceRva: DWORD;
  ResourceDirectory, NamesDirectory, LangsDirectory: _IMAGE_RESOURCE_DIRECTORY;
  TypeEntry, NameEntry, LangEntry: IMAGE_RESOURCE_DIRECTORY_ENTRY;
  DataEntry: _IMAGE_RESOURCE_DATA_ENTRY;
  VersionBuffer: Pointer;
  FileInfo: PVSFixedFileInfo;
begin
  Result := '';
  DosHeader := Self.Read<TImageDosHeader>(hInstance);
  if DosHeader.e_magic <> IMAGE_DOS_SIGNATURE then
    Exit;
  if Is64Bit then
    ResourceRva := Self.Read<TImageNtHeaders>(RvaToVa(SIZE_T(DosHeader._lfanew))).OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_RESOURCE].VirtualAddress
  else
    ResourceRva := Self.Read<TImageNtHeaders32>(RvaToVa(SIZE_T(DosHeader._lfanew))).OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_RESOURCE].VirtualAddress;
  if ResourceRva = 0 then
    Exit;
  ResourceDirectory := Self.Read<_IMAGE_RESOURCE_DIRECTORY>(RvaToVa(ResourceRva));
  for i := 0 to ResourceDirectory.NumberOfNamedEntries + ResourceDirectory.NumberOfIdEntries - 1 do
  begin
    TypeEntry := Self.Read<IMAGE_RESOURCE_DIRECTORY_ENTRY>(RvaToVa(ResourceRva + SizeOf(_IMAGE_RESOURCE_DIRECTORY) + SizeOf(IMAGE_RESOURCE_DIRECTORY_ENTRY) * i));
    if TypeEntry.Id <> 16 then
      Continue;
    NamesDirectory := Self.Read<_IMAGE_RESOURCE_DIRECTORY>(RvaToVa((TypeEntry.OffsetToDirectory and $7FFFFFFF) + ResourceRva));
    for j := 0 to NamesDirectory.NumberOfNamedEntries + NamesDirectory.NumberOfIdEntries - 1 do
    begin
      NameEntry := Self.Read<IMAGE_RESOURCE_DIRECTORY_ENTRY>(RvaToVa((TypeEntry.OffsetToDirectory and $7FFFFFFF) + ResourceRva + SizeOf(_IMAGE_RESOURCE_DIRECTORY) + SizeOf(IMAGE_RESOURCE_DIRECTORY_ENTRY) * j));
      LangsDirectory := Self.Read<_IMAGE_RESOURCE_DIRECTORY>(RvaToVa((NameEntry.OffsetToDirectory and $7FFFFFFF) + ResourceRva));
      for k := 0 to LangsDirectory.NumberOfNamedEntries + LangsDirectory.NumberOfIdEntries - 1 do
      begin
        LangEntry := Self.Read<IMAGE_RESOURCE_DIRECTORY_ENTRY>(RvaToVa((NameEntry.OffsetToDirectory and $7FFFFFFF) + ResourceRva + SizeOf(_IMAGE_RESOURCE_DIRECTORY) + SizeOf(IMAGE_RESOURCE_DIRECTORY_ENTRY) * k));
        DataEntry := Self.Read<_IMAGE_RESOURCE_DATA_ENTRY>(RvaToVa(ResourceRva + LangEntry.OffsetToData));
        if DataEntry.Size = 0 then
          Continue;
        GetMem(VersionBuffer, DataEntry.Size);
        if Read(RvaToVa(DataEntry.OffsetToData), VersionBuffer, DataEntry.Size) then
        begin
          if VerQueryValue(VersionBuffer, '\', Pointer(FileInfo), DataEntry.Size) then
          begin
            Result:= InttoStr(FileInfo.dwFileVersionMS div $10000) + '.'
              + IntToStr(FileInfo.dwFileVersionMS mod $10000) + '.'
              + IntToStr(FileInfo.dwFileVersionLS div $10000) + '.'
              + IntToStr(FileInfo.dwFileVersionLS mod $10000);
          end;
        end;
        FreeMem(VersionBuffer);
        Exit;
      end;
    end;
  end;
end;

function TProcess.CreateThread(lpStartAddress: Pointer; lpParameter: Pointer; dwCreationFlags: Cardinal; var lpThreadId: Cardinal): THandle;
begin
  Result := CreateRemoteThread(Handle, nil, 0, lpStartAddress, lpParameter, dwCreationFlags, PDWORD(nil)^);
end;

constructor TProcess.Create(ProcessId: DWORD);
var
  pbi: PROCESS_BASIC_INFORMATION;
  ReturnLength: ULONG;
  DosHeader: TImageDosHeader;
  Header: SIZE_T;
  i: Integer;
  NumberOfSections: Word;
begin
  FHandle := OpenProcess(MAXIMUM_ALLOWED, False, ProcessId);
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('OpenProcess() FAILED');
  IsWow64Process(FHandle, @FWow64);
  NtQueryInformationProcess(FHandle, 0, @pbi, Sizeof(pbi), @ReturnLength);
  FProcessEnvironmetBlock := pbi.PebBaseAddress;
  FInstance := Self.Read<HMODULE>(SIZE_T(FProcessEnvironmetBlock) + $10);
  if Is64Bit then
    FLdr := Self.Read<Pointer>(SIZE_T(FProcessEnvironmetBlock) + $18)
  else
    FLdr := Pointer(Self.Read<DWORD>(SIZE_T(FProcessEnvironmetBlock) + $100C));
  DosHeader := Self.Read<TImageDosHeader>(hInstance);

  if Is64Bit then
  begin
    NumberOfSections := Self.Read<TImageNtHeaders>(hInstance + SIZE_T(DosHeader._lfanew)).FileHeader.NumberOfSections;
    Header := RvaToVa(SIZE_T(DosHeader._lfanew) + SizeOf(TImageNtHeaders));
  end
  else
  begin
    NumberOfSections := Self.Read<TImageNtHeaders32>(hInstance + SIZE_T(DosHeader._lfanew)).FileHeader.NumberOfSections;
    Header := RvaToVa(SIZE_T(DosHeader._lfanew) + SizeOf(TImageNtHeaders32));
  end;

  SetLength(FSectionHeaders, NumberOfSections);
  for i := 0 to NumberOfSections - 1 do
  begin
    FSectionHeaders[i] := Self.Read<TImageSectionHeader>(Header);
    Inc(Header, SizeOf(TImageSectionHeader));
  end;
end;

destructor TProcess.Free;
begin
  CloseHandle(FHandle);
end;

end.
