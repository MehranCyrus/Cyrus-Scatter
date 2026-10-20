#ifndef CYRUS_ASSET_JPEG_H
#define CYRUS_ASSET_JPEG_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct CyrusJpegInfo {
    unsigned int width,height,channels,bits_per_channel,progressive;
    uint64_t charged_bytes,allocation_requests;
} CyrusJpegInfo;
typedef void (*CyrusJpegObserve)(void* context);
/* Complete warning-fatal decode. Input is borrowed; returned pixels are never
   retained. All longjmp targets and cleanup are contained in the C function. */
int cyrus_strict_jpeg(const unsigned char* bytes,size_t count,uint64_t codec_budget,
    CyrusJpegInfo* result,char* error,size_t error_size,
    CyrusJpegObserve observe,void* observe_context);
#ifdef __cplusplus
}
#endif
#endif
