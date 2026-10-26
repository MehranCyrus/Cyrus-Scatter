#include "asset_jpeg.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <limits.h>
#include <jpeglib.h>

typedef struct StrictState {
    struct jpeg_decompress_struct jpeg;
    struct jpeg_error_mgr error;
    jmp_buf escape;
    char message[JMSG_LENGTH_MAX];
    unsigned char* row;
    uint64_t budget,charged,requests;
    CyrusJpegObserve observe;void* observe_context;
    void* (*small)(j_common_ptr,int,size_t);
    void* (*large)(j_common_ptr,int,size_t);
    JSAMPARRAY (*samples)(j_common_ptr,int,JDIMENSION,JDIMENSION);
    JBLOCKARRAY (*blocks)(j_common_ptr,int,JDIMENSION,JDIMENSION);
    jvirt_sarray_ptr (*virtual_samples)(j_common_ptr,int,boolean,JDIMENSION,JDIMENSION,JDIMENSION);
    jvirt_barray_ptr (*virtual_blocks)(j_common_ptr,int,boolean,JDIMENSION,JDIMENSION,JDIMENSION);
} StrictState;

static StrictState* state(j_common_ptr jpeg){return (StrictState*)jpeg->client_data;}
static void failure(StrictState* s,const char* text){strncpy_s(s->message,sizeof(s->message),text,_TRUNCATE);longjmp(s->escape,1);}
static void fatal(j_common_ptr jpeg){StrictState* s=state(jpeg);(*jpeg->err->format_message)(jpeg,s->message);longjmp(s->escape,1);}
static void emit(j_common_ptr jpeg,int level){if(level<0)fatal(jpeg);}
static void observe(StrictState* s){if(s->observe)s->observe(s->observe_context);}
static uint64_t multiply(StrictState* s,uint64_t a,uint64_t b){if(b&&a>UINT64_MAX/b)failure(s,"JPEG memory request overflows its bound.");return a*b;}
static uint64_t addition(StrictState* s,uint64_t a,uint64_t b){if(a>UINT64_MAX-b)failure(s,"JPEG memory request overflows its bound.");return a+b;}
static void charge(StrictState* s,uint64_t amount){
    /* Monotonic request accounting is deliberately conservative. Extra space
       bounds row-pointer/pool bookkeeping, while libjpeg's independent virtual
       array budget prevents disk backing. It is not a process-memory reading. */
    if(amount>UINT64_MAX-65536||s->charged>s->budget||amount+65536>s->budget-s->charged)failure(s,"JPEG codec allocation requests exceed their explicit budget.");
    s->charged+=amount+65536;++s->requests;
}
static void* small(j_common_ptr jpeg,int pool,size_t size){StrictState* s=state(jpeg);void* p;charge(s,size);p=s->small(jpeg,pool,size);observe(s);return p;}
static void* large(j_common_ptr jpeg,int pool,size_t size){StrictState* s=state(jpeg);void* p;charge(s,size);p=s->large(jpeg,pool,size);observe(s);return p;}
static uint64_t sample_bytes(StrictState* s,JDIMENSION width,JDIMENSION rows){return addition(s,multiply(s,((uint64_t)width+127u)&~127ull,rows),multiply(s,rows,sizeof(JSAMPROW)));}
static uint64_t block_bytes(StrictState* s,JDIMENSION width,JDIMENSION rows){return addition(s,multiply(s,multiply(s,width,rows),sizeof(JBLOCK)),multiply(s,rows,sizeof(JBLOCKROW)));}
static JSAMPARRAY samples(j_common_ptr jpeg,int pool,JDIMENSION width,JDIMENSION rows){StrictState* s=state(jpeg);JSAMPARRAY p;charge(s,sample_bytes(s,width,rows));p=s->samples(jpeg,pool,width,rows);observe(s);return p;}
static JBLOCKARRAY blocks(j_common_ptr jpeg,int pool,JDIMENSION width,JDIMENSION rows){StrictState* s=state(jpeg);JBLOCKARRAY p;charge(s,block_bytes(s,width,rows));p=s->blocks(jpeg,pool,width,rows);observe(s);return p;}
static jvirt_sarray_ptr virtual_samples(j_common_ptr jpeg,int pool,boolean zero,JDIMENSION width,JDIMENSION rows,JDIMENSION access){StrictState* s=state(jpeg);jvirt_sarray_ptr p;charge(s,sample_bytes(s,width,rows));p=s->virtual_samples(jpeg,pool,zero,width,rows,access);observe(s);return p;}
static jvirt_barray_ptr virtual_blocks(j_common_ptr jpeg,int pool,boolean zero,JDIMENSION width,JDIMENSION rows,JDIMENSION access){StrictState* s=state(jpeg);jvirt_barray_ptr p;charge(s,block_bytes(s,width,rows));p=s->virtual_blocks(jpeg,pool,zero,width,rows,access);observe(s);return p;}
static void copy_error(char* target,size_t capacity,const char* source){if(target&&capacity)strncpy_s(target,capacity,source,_TRUNCATE);}

int cyrus_strict_jpeg(const unsigned char* bytes,size_t count,uint64_t codec_budget,
    CyrusJpegInfo* result,char* error,size_t error_size,CyrusJpegObserve observer,void* observer_context){
    StrictState* s;
    if(result)memset(result,0,sizeof(*result));if(error&&error_size)error[0]=0;
    if(!bytes||!result||count<4||count>32u*1024u*1024u||codec_budget<1048576||codec_budget>256u*1024u*1024u){copy_error(error,error_size,"Invalid bounded JPEG input or codec budget.");return 0;}
    if(bytes[0]!=255||bytes[1]!=216||bytes[count-2]!=255||bytes[count-1]!=217){copy_error(error,error_size,"JPEG requires its complete SOI/EOI container.");return 0;}
    s=(StrictState*)calloc(1,sizeof(*s));if(!s){copy_error(error,error_size,"Cannot allocate JPEG decoder state.");return 0;}
    s->budget=codec_budget;s->observe=observer;s->observe_context=observer_context;
    s->jpeg.err=jpeg_std_error(&s->error);s->jpeg.client_data=s;s->error.error_exit=fatal;s->error.emit_message=emit;
    if(setjmp(s->escape)){
        copy_error(error,error_size,s->message);result->charged_bytes=s->charged;result->allocation_requests=s->requests;
        observe(s);if(s->jpeg.mem)jpeg_destroy_decompress(&s->jpeg);free(s->row);free(s);return 0;
    }
    charge(s,sizeof(*s)+65536u);
    jpeg_create_decompress(&s->jpeg);s->jpeg.client_data=s;
    s->small=s->jpeg.mem->alloc_small;s->large=s->jpeg.mem->alloc_large;s->samples=s->jpeg.mem->alloc_sarray;s->blocks=s->jpeg.mem->alloc_barray;s->virtual_samples=s->jpeg.mem->request_virt_sarray;s->virtual_blocks=s->jpeg.mem->request_virt_barray;
    s->jpeg.mem->alloc_small=small;s->jpeg.mem->alloc_large=large;s->jpeg.mem->alloc_sarray=samples;s->jpeg.mem->alloc_barray=blocks;s->jpeg.mem->request_virt_sarray=virtual_samples;s->jpeg.mem->request_virt_barray=virtual_blocks;
    s->jpeg.mem->max_memory_to_use=(long)codec_budget;
    jpeg_mem_src(&s->jpeg,bytes,(unsigned long)count);
    if(jpeg_read_header(&s->jpeg,TRUE)!=JPEG_HEADER_OK)failure(s,"JPEG header is incomplete.");
    if(s->jpeg.data_precision!=8||(s->jpeg.num_components!=1&&s->jpeg.num_components!=3)||s->jpeg.arith_code||s->jpeg.image_width==0||s->jpeg.image_height==0||s->jpeg.image_width>8192||s->jpeg.image_height>8192||(uint64_t)s->jpeg.image_width*s->jpeg.image_height>64u*1024u*1024u)failure(s,"JPEG is outside 8-bit Gray/RGB and 8192/64 Mpixel profile.");
    if(s->jpeg.jpeg_color_space!=JCS_GRAYSCALE&&s->jpeg.jpeg_color_space!=JCS_RGB&&s->jpeg.jpeg_color_space!=JCS_YCbCr)failure(s,"JPEG has an unsupported encoded color space.");
    result->width=s->jpeg.image_width;result->height=s->jpeg.image_height;result->channels=(unsigned int)s->jpeg.num_components;result->bits_per_channel=8;result->progressive=s->jpeg.progressive_mode?1u:0u;
    s->jpeg.out_color_space=s->jpeg.num_components==1?JCS_GRAYSCALE:JCS_RGB;
    if(!jpeg_start_decompress(&s->jpeg))failure(s,"JPEG could not start a complete decode.");
    if(s->jpeg.output_width!=result->width||s->jpeg.output_height!=result->height||(unsigned int)s->jpeg.output_components!=result->channels)failure(s,"JPEG decoder changed the declared pixel representation.");
    {const size_t stride=(size_t)s->jpeg.output_width*(unsigned int)s->jpeg.output_components;charge(s,stride);s->row=(unsigned char*)malloc(stride);if(!s->row)failure(s,"Cannot allocate JPEG scanline.");}
    observe(s);
    while(s->jpeg.output_scanline<s->jpeg.output_height){JSAMPROW row=s->row;if(jpeg_read_scanlines(&s->jpeg,&row,1)!=1)failure(s,"JPEG scanline is incomplete.");}
    if(!jpeg_finish_decompress(&s->jpeg))failure(s,"JPEG finish is incomplete.");
    if(s->jpeg.src->bytes_in_buffer!=0)failure(s,"JPEG contains trailing data or another image.");
    result->charged_bytes=s->charged;result->allocation_requests=s->requests;observe(s);jpeg_destroy_decompress(&s->jpeg);free(s->row);free(s);return 1;
}
