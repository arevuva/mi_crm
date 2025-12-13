#include "utils.h"

#include <windows.h>
#include <shlobj.h>

#include <codecvt>
#include <locale>

std::string Utf8FromUtf16(const std::wstring& utf16_string) {
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
  return converter.to_bytes(utf16_string);
}

int Scale(int source, double scale_factor) { return static_cast<int>(source * scale_factor); }

std::wstring GetExecutableDirectory() {
  wchar_t buffer[MAX_PATH];
  GetModuleFileName(nullptr, buffer, MAX_PATH);
  std::wstring full_path(buffer);
  size_t last_slash = full_path.find_last_of(L"\\/");
  return full_path.substr(0, last_slash);
}
