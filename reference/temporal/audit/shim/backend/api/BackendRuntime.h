#pragma once
#include <cstdlib>
#include <cstring>
#include <new>
namespace backend {
enum class MemcpyKind { DeviceToDevice, DeviceToHost, HostToDevice };
inline void memcpy_async(void* d, const void* s, size_t n, MemcpyKind) { std::memcpy(d, s, n); }
inline void memcpy_sync(void* d, const void* s, size_t n, MemcpyKind k) { memcpy_async(d, s, n, k); }
inline void device_synchronize() {}
inline void* device_malloc_checked(size_t n, const char*) {
    void* p = std::malloc(n);
    if (!p) throw std::bad_alloc();
    return p;
}
inline void device_free(void* p) { std::free(p); }
}
