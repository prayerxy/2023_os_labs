#include <defs.h>
#include <string.h>
#include <bitmap.h>
#include <kmalloc.h>
#include <error.h>
#include <assert.h>

#define WORD_TYPE           uint32_t
#define WORD_BITS           (sizeof(WORD_TYPE) * CHAR_BIT)

struct bitmap {
    uint32_t nbits;   //位图的总位数
    uint32_t nwords;  //给map分配的字word数
    WORD_TYPE *map;   //位图的指针
};

// bitmap_create - allocate a new bitmap object.
//传入的是位图的总位数
struct bitmap *
bitmap_create(uint32_t nbits) {
    static_assert(WORD_BITS != 0);
    //避免加法溢出
    assert(nbits != 0 && nbits + WORD_BITS > nbits);

    //分配位图结构体
    struct bitmap *bitmap;
    if ((bitmap = kmalloc(sizeof(struct bitmap))) == NULL) {
        return NULL;
    }
    //向上取整字数，可能超过实际的位数
    uint32_t nwords = ROUNDUP_DIV(nbits, WORD_BITS);
    WORD_TYPE *map;
    if ((map = kmalloc(sizeof(WORD_TYPE) * nwords)) == NULL) {
        kfree(bitmap);
        return NULL;
    }

    bitmap->nbits = nbits, bitmap->nwords = nwords;
    //置位，表示初始全部没有被占用
    bitmap->map = memset(map, 0xFF, sizeof(WORD_TYPE) * nwords);

    /* mark any leftover bits at the end in use(0) */
    //由于字数超过位数，所以要进行处理 
    if (nbits != nwords * WORD_BITS) {
        //ix是nbits在的字 overbits是超出的位数bits
        uint32_t ix = nwords - 1, overbits = nbits - ix * WORD_BITS;

        assert(nbits / WORD_BITS == ix);
        assert(overbits > 0 && overbits < WORD_BITS);

        //把超出的位数置0
        for (; overbits < WORD_BITS; overbits ++) {
            bitmap->map[ix] ^= (1 << overbits);
        }
    }
    return bitmap;
}

// bitmap_alloc - locate a cleared bit, set it, and return its index.
//从bitmap找到空闲位，把空闲位对应的磁盘块分配给它  索引存在index_store中
int
bitmap_alloc(struct bitmap *bitmap, uint32_t *index_store) {
    WORD_TYPE *map = bitmap->map;
    uint32_t ix, offset, nwords = bitmap->nwords;
    for (ix = 0; ix < nwords; ix ++) {
        if (map[ix] != 0) {
            //找到这个字里面的位
            for (offset = 0; offset < WORD_BITS; offset ++) {
                WORD_TYPE mask = (1 << offset);
                if (map[ix] & mask) {
                    map[ix] ^= mask;

                    //位数就是对应要分配的磁盘块号
                    *index_store = ix * WORD_BITS + offset;
                    return 0;
                }
            }
            assert(0);
        }
    }
    return -E_NO_MEM;
}

// bitmap_translate - according index, get the related word and mask
//把index翻译成对应的map里面第几个字，字的位偏移量  word指向这个字的指针 mask是对应的位
static void
bitmap_translate(struct bitmap *bitmap, uint32_t index, WORD_TYPE **word, WORD_TYPE *mask) {
    assert(index < bitmap->nbits);
    uint32_t ix = index / WORD_BITS, offset = index % WORD_BITS;
    *word = bitmap->map + ix; //map[ix]对应的指针 就是第ix个字
    *mask = (1 << offset);   //map[ix] & mask
}

// bitmap_test - according index, get the related value (0 OR 1) in the bitmap
//测试index对应的位是否被占用
bool
bitmap_test(struct bitmap *bitmap, uint32_t index) {
    WORD_TYPE *word, mask;
    bitmap_translate(bitmap, index, &word, &mask);
    return (*word & mask);
}

// bitmap_free - according index, set related bit to 1
//释放index对应的位
void
bitmap_free(struct bitmap *bitmap, uint32_t index) {
    WORD_TYPE *word, mask;
    bitmap_translate(bitmap, index, &word, &mask);
    assert(!(*word & mask));
    *word |= mask;
}

// bitmap_destroy - free memory contains bitmap
//把位图摧毁
void
bitmap_destroy(struct bitmap *bitmap) {
    kfree(bitmap->map);
    kfree(bitmap);
}

// bitmap_getdata - return bitmap->map, return the length of bits to len_store
//提取bitmap中的map数组，把nwords的总位数返回给len_store
void *
bitmap_getdata(struct bitmap *bitmap, size_t *len_store) {
    if (len_store != NULL) {
        *len_store = sizeof(WORD_TYPE) * bitmap->nwords;
    }
    return bitmap->map;
}

