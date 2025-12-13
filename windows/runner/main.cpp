#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <memory>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE prev, wchar_t* command_line, int show_command) {
  std::vector<std::string> arguments = {Utf8FromUtf16(command_line)};

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(arguments);

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.CreateAndShow(L"mi_crm", origin, size)) {
    return EXIT_FAILURE;
  }

  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  return EXIT_SUCCESS;
}
