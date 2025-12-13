#include "win32_window.h"

#include <flutter_windows.h>
#include <windowsx.h>

#include <cassert>

#include "resource.h"
#include "utils.h"

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

}  // namespace

Win32Window::Win32Window() = default;

Win32Window::~Win32Window() { DestroyWindow(window_); }

bool Win32Window::CreateAndShow(const std::wstring& title, const Point& origin, const Size& size) {
  RegisterWindowClass();

  UINT dpi = GetDpiForSystem();
  double scale_factor = dpi / 96.0;
  HWND window = CreateWindow(kWindowClassName, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                             Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
                             Scale(size.width, scale_factor), Scale(size.height, scale_factor),
                             nullptr, nullptr, GetModuleHandle(nullptr), this);
  if (!window) {
    return false;
  }
  window_ = window;
  return true;
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_);
  RECT frame;
  GetClientRect(window_, &frame);
  MoveWindow(content, frame.left, frame.top, frame.right - frame.left, frame.bottom - frame.top, true);
  SetFocus(child_content_);
}

HWND Win32Window::GetHandle() { return window_; }

void Win32Window::OnDestroy() { PostQuitMessage(0); }

LRESULT Win32Window::MessageHandler(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      OnDestroy();
      return 0;
    case WM_SIZE:
      if (child_content_ != nullptr) {
        RECT frame;
        GetClientRect(hwnd, &frame);
        MoveWindow(child_content_, frame.left, frame.top, frame.right - frame.left, frame.bottom - frame.top, TRUE);
      }
      return 0;
    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    auto that = static_cast<Win32Window*>(create_struct->lpCreateParams);
    SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(that));
    return that->MessageHandler(window, message, wparam, lparam);
  }

  auto that = reinterpret_cast<Win32Window*>(GetWindowLongPtr(window, GWLP_USERDATA));
  if (that) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

void Win32Window::RegisterWindowClass() {
  WNDCLASS window_class = {0};
  window_class.lpfnWndProc = Win32Window::WndProc;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.lpszClassName = kWindowClassName;
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  RegisterClass(&window_class);
}
