#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

bool RegisterWindowsUriScheme(const std::wstring& scheme,
                               const std::wstring& command,
                               const std::wstring& description) {
  const std::wstring key_path = L"Software\\Classes\\" + scheme;
  HKEY key = nullptr;
  if (::RegCreateKeyExW(
          HKEY_CURRENT_USER,
          key_path.c_str(),
          0,
          nullptr,
          REG_OPTION_NON_VOLATILE,
          KEY_WRITE,
          nullptr,
          &key,
          nullptr) != ERROR_SUCCESS) {
    return false;
  }

  const std::wstring default_value = description;
  ::RegSetValueExW(
      key,
      nullptr,
      0,
      REG_SZ,
      reinterpret_cast<const BYTE*>(default_value.c_str()),
      static_cast<DWORD>((default_value.size() + 1) * sizeof(wchar_t)));

  const std::wstring url_protocol = L"";
  ::RegSetValueExW(
      key,
      L"URL Protocol",
      0,
      REG_SZ,
      reinterpret_cast<const BYTE*>(url_protocol.c_str()),
      static_cast<DWORD>(sizeof(wchar_t)));

  const std::wstring command_key_path = key_path + L"\\shell\\open\\command";
  HKEY command_key = nullptr;
  if (::RegCreateKeyExW(
          HKEY_CURRENT_USER,
          command_key_path.c_str(),
          0,
          nullptr,
          REG_OPTION_NON_VOLATILE,
          KEY_WRITE,
          nullptr,
          &command_key,
          nullptr) == ERROR_SUCCESS) {
    ::RegSetValueExW(
        command_key,
        nullptr,
        0,
        REG_SZ,
        reinterpret_cast<const BYTE*>(command.c_str()),
        static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
    ::RegCloseKey(command_key);
  }

  ::RegCloseKey(key);
  return true;
}
