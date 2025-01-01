import math
from collections import Optional
from memory import Span
from sys.info import simdwidthof


# TODO: split this all out and create similar abstractions as the Rust bstr crate
# TODO: add an ascii to lower case


alias SIMD_U8_WIDTH: Int = simdwidthof[DType.uint8]()


@always_inline
fn arg_true[simd_width: Int](v: SIMD[DType.bool, simd_width]) -> Int:
    for i in range(simd_width):
        if v[i]:
            return i
    return -1


@always_inline
fn find_chr_next_occurance_simd(
    haystack: Span[UInt8], chr: UInt8, start: Int = 0
) -> Int:
    """
    Function to find the next occurrence of character using SIMD instruction.
    The function assumes that the tensor is always in-bounds. any bound checks should be in the calling function.
    """
    var haystack_len = len(haystack) - start
    var aligned = start + math.align_down(haystack_len, SIMD_U8_WIDTH)

    for s in range(start, aligned, SIMD_U8_WIDTH):
        var v = haystack[s:].unsafe_ptr().load[width=SIMD_U8_WIDTH]()
        var mask = v == chr
        if mask.reduce_or():
            return s + arg_true(mask)

    for i in range(aligned, len(haystack)):
        if haystack[i] == chr:
            return i

    return -1


fn find(haystack: Span[UInt8], needle: Span[UInt8]) -> Optional[Int]:
    """Look for the substring `needle` in the haystack.

    This returns the index of the start of the first occurance of needle.
    """
    # TODO: memchr/memmem probably
    # https://github.com/BurntSushi/bstr/blob/master/src/ext_slice.rs#L3094
    # https://github.com/BurntSushi/memchr/blob/master/src/memmem/searcher.rs

    # Naive-ish search. Use our simd accel searcher to find the first char in the needle
    # check for extension, and move forward
    var start = 0
    while start < len(haystack):
        start = find_chr_next_occurance_simd(haystack, needle[0], start)
        if start == -1:
            return None
        # Try extension
        var matched = True
        for i in range(1, len(needle)):
            if haystack[start + i] != needle[i]:
                matched = False
                break
        if matched:
            return start
        else:
            start = start + 1
    return None


@value
@register_passable
struct _StartEnd:
    var start: Int
    var end: Int


@value
struct SplitIterator[is_mutable: Bool, //, origin: Origin[is_mutable]]:
    var inner: Span[UInt8, origin]
    var split_on: UInt8
    var current: Int
    var len: Int
    var next_split: Optional[_StartEnd]

    fn __init__(out self, to_split: Span[UInt8, origin], split_on: UInt8):
        self.inner = to_split
        self.split_on = split_on
        self.current = 0
        self.len = 1
        self.next_split = None
        self._find_next_split()

    fn __iter__(self) -> Self:
        return self

    @always_inline
    fn __len__(read self) -> Int:
        return self.len

    @always_inline
    fn __has_next__(read self) -> Bool:
        return self.__len__() > 0

    fn __next__(mut self) -> Span[UInt8, origin]:
        var ret = self.next_split.value()
        self._find_next_split()
        return self.inner[ret.start : ret.end]

    fn _find_next_split(mut self):
        if self.current >= len(self.inner):
            self.next_split = None
            self.len = 0
            return

        var end = -1
        for i in range(self.current, len(self.inner)):
            if self.inner[i] == self.split_on:
                end = i
                break

        if end != -1:
            self.next_split = _StartEnd(self.current, end)
            self.current = end + 1
        else:
            self.next_split = _StartEnd(self.current, len(self.inner))
            self.current = len(self.inner) + 1
