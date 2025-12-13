#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>
#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    int x;
    int y;
    Point(int x, int y) : x(x), y(y) {}
  };

  struct Size {
    int width;
    int height;
    Size(int width, int height) : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  bool CreateAndShow(const std::wstring& title, const Point& origin, const Size& size);
  void SetChildContent(HWND content);
  HWND GetHandle();

 protected:
  virtual void OnDestroy();
  virtual LRESULT MessageHandler(HWND window, UINT message, WPARAM wparam, LPARAM lparam) noexcept;

 private:
  static LRESULT CALLBACK WndProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) noexcept;
  void RegisterWindowClass();

  HWND window_ = nullptr;
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
