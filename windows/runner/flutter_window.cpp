#include "flutter_window.h"

#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>

#include <optional>

#include "generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project) : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_->StopRendering();
  }
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result = flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_) {
        flutter_controller_->Engine()->ReloadSystemFonts();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

bool FlutterWindow::CreateAndShow(const std::wstring& title, const Point& origin, const Size& size) {
  if (!Win32Window::CreateAndShow(title, origin, size)) {
    return false;
  }

  flutter::FlutterViewController::ViewProperties view_properties = {};
  view_properties.width = size.width;
  view_properties.height = size.height;
  view_properties.view_mode = flutter::FlutterViewController::ViewMode::kWindowingApi;

  auto controller = std::make_unique<flutter::FlutterViewController>(project_, view_properties);
  if (!controller->engine() || !controller->view()) {
    return false;
  }
  flutter_controller_ = std::move(controller);
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}
