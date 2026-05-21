#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Creates a console for the process, and redirects stdout and stderr to
// it for both the runner and the Flutter library.
void CreateAndAttachConsole();

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string
// encoded in UTF-8. Returns an empty std::string on failure.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed in as a std::vector<std::string>,
// encoded in UTF-8. Returns an empty std::vector<std::string> on failure.
std::vector<std::string> GetCommandLineArguments();

// Registers a custom URI scheme handler for the current user on Windows.
// This allows the app to open directly when a link like `zedu://...` is clicked.
bool RegisterWindowsUriScheme(const std::wstring& scheme,
                               const std::wstring& command,
                               const std::wstring& description);

#endif  // RUNNER_UTILS_H_
