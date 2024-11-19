#include <string.h>
#include <riscv.h>

/* *
 * strlen - calculate the length of the string @s, not including
 * the terminating '\0' character.
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
        cnt ++;
    }
    return cnt;
}

/* *
 * strnlen - calculate the length of the string @s, not including
 * the terminating '\0' char acter, but at most @len.
 * @s:      the input string
 * @len:    the max-length that function will scan
 *
 * Note that, this function looks only at the first @len characters
 * at @s, and never beyond @s + @len.
 *
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
        cnt ++;
    }
    return cnt;
}

/* *
 * strcpy - copies the string pointed by @src into the array pointed by @dst,
 * including the terminating null character.
 * @dst:    pointer to the destination array where the content is to be copied
 * @src:    string to be copied
 *
 * The return value is @dst.
 *
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}

/* *
 * strncpy - copies the first @len characters of @src to @dst. If the end of string @src
 * if found before @len characters have been copied, @dst is padded with '\0' until a
 * total of @len characters have been written to it.
 * @dst:    pointer to the destination array where the content is to be copied
 * @src:    string to be copied
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
}

/* *
 * strcmp - compares the string @s1 and @s2
 * @s1:     string to be compared
 * @s2:     string to be compared
 *
 * This function starts comparing the first character of each string. If
 * they are equal to each other, it continues with the following pairs until
 * the characters differ or until a terminanting null-character is reached.
 *
 * Returns an integral value indicating the relationship between the strings:
 * - A zero value indicates that both strings are equal;
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}

/* *
 * strncmp - compares up to @n characters of the string @s1 to those of the string @s2
 * @s1:     string to be compared
 * @s2:     string to be compared
 * @n:      maximum number of characters to compare
 *
 * This function starts comparing the first character of each string. If
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
}

/* *
 * strchr - locates first occurrence of character in string
 * @s:      the input string
 * @c:      character to be located
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
}

/* *
 * strfind - locates first occurrence of character in string
 * @s:      the input string
 * @c:      character to be located
 *
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
        if (*s == c) {
            break;
        }
        s ++;
    }
    return (char *)s;
}

/* *
 * strtol - converts string to long integer
 * @s:      the input string that contains the representation of an integer number
 * @endptr: reference to an object of type char *, whose value is set by the
 *          function to the next character in @s after the numerical value. This
 *          parameter can also be a null pointer, in which case it is not used.
 * @base:   x
 *
 * The function first discards as many whitespace characters as necessary until
 * the first non-whitespace character is found. Then, starting from this character,
 * takes as many characters as possible that are valid following a syntax that
 * depends on the base parameter, and interprets them as a numerical value. Finally,
 * a pointer to the first character following the integer representation in @s
 * is stored in the object pointed by @endptr.
 *
 * If the value of base is zero, the syntax expected is similar to that of
 * integer constants, which is formed by a succession of:
 * - An optional plus or minus sign;
 * - An optional prefix indicating octal or hexadecimal base ("0" or "0x" respectively)
 * - A sequence of decimal digits (if no base prefix was specified) or either octal
 *   or hexadecimal digits if a specific prefix is present
 *
 * If the base value is between 2 and 36, the format expected for the integral number
 * is a succession of the valid digits and/or letters needed to represent integers of
 * the specified radix (starting from '0' and up to 'z'/'Z' for radix 36). The
 * sequence may optionally be preceded by a plus or minus sign and, if base is 16,
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
        s ++;
    }
    else if (*s == '-') {
        s ++, neg = 1;
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
        s += 2, base = 16;
    }
    else if (base == 0 && s[0] == '0') {
        s ++, base = 8;
    }
    else if (base == 0) {
        base = 10;
    }

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
            dig = *s - '0';
        }
        else if (*s >= 'a' && *s <= 'z') {
            dig = *s - 'a' + 10;
        }
        else if (*s >= 'A' && *s <= 'Z') {
            dig = *s - 'A' + 10;
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
        *endptr = (char *) s;
    }
    return (neg ? -val : val);
}

/*
 * memset - 将内存区域的前 n 个字节设置为指定的值
 * @s: 指向目标内存区域的指针
 * @c: 要填充的值（以字节为单位）
 * @n: 要填充的字节数
 *
 * 描述：
 * - 此函数将从指针 s 指向的内存区域开始，连续填充 n 个字节为值 c。
 * - 如果定义了 __HAVE_ARCH_MEMSET，将使用体系结构相关的优化版本。
 * - 否则，使用通用 C 实现，通过逐字节操作完成填充。
 *
 * 返回：
 * - 返回指向目标内存区域的指针 s。
 */
void *
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    /*
     * 如果存在体系结构相关的 memset 实现（如汇编优化版本），
     * 则直接调用优化函数 __memset(s, c, n)，提高性能。
     */
    return __memset(s, c, n);
#else
    /*
     * 通用 C 实现：
     * - 使用一个字符指针 p 遍历内存区域。
     * - 循环 n 次，每次设置内存中的一个字节为值 c。
     */
    char *p = s;             // 转换目标地址为字符指针，方便逐字节操作
    while (n-- > 0) {        // 每次操作一个字节，直到 n 减为 0
        *p++ = c;            // 设置当前字节为 c，并移动指针到下一个字节
    }
    return s;                // 返回目标内存区域的起始指针
#endif /* __HAVE_ARCH_MEMSET */
}

/* *
 * memmove - copies the values of @n bytes from the location pointed by @src to
 * the memory area pointed by @dst. @src and @dst are allowed to overlap.
 * @dst     pointer to the destination array where the content is to be copied
 * @src     pointer to the source of data to by copied
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    if (s < d && s + n > d) {
        s += n, d += n;
        while (n -- > 0) {
            *-- d = *-- s;
        }
    } else {
        while (n -- > 0) {
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}

/* *
 * memcpy - copies the value of @n bytes from the location pointed by @src to
 * the memory area pointed by @dst.
 * @dst     pointer to the destination array where the content is to be copied
 * @src     pointer to the source of data to by copied
 * @n:      number of bytes to copy
 *
 * The memcpy() returns @dst.
 *
 * Note that, the function does not check any terminating null character in @src,
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}

/* *
 * memcmp - compares two blocks of memory
 * @v1:     pointer to block of memory
 * @v2:     pointer to block of memory
 * @n:      number of bytes to compare
 *
 * The memcmp() functions returns an integral value indicating the
 * relationship between the content of the memory blocks:
 * - A zero value indicates that the contents of both memory blocks are equal;
 * - A value greater than zero indicates that the first byte that does not
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
}

