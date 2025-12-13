#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

std::string Utf8FromUtf16(const std::wstring& utf16_string);

int Scale(int source, double scale_factor);

std::wstring GetExecutableDirectory();

#endif  // RUNNER_UTILS_H_
