"""
Helper functions for working with files
"""
import math
from algorithm import vectorize
from collections import Optional
from memory import Span, UnsafePointer
from sys.info import simdwidthof
from tensor import Tensor


from ExtraMojo.bstr.bstr import (
    find_chr_all_occurrences,
    find_chr_next_occurrence,
)


alias NEW_LINE = 10
alias SIMD_U8_WIDTH: Int = simdwidthof[DType.uint8]()
alias BUF_SIZE: Int = 1024 * 64


fn read_lines(
    path: String, buf_size: Int = BUF_SIZE
) raises -> List[List[UInt8]]:
    """
    Read all the lines in the file and return them as a [`DynamicVector`] of [`Tensor[DType.int8]`].
    """
    # TODO: make this an iterator
    var fh = open(path, "r")
    var result = List[List[UInt8]]()
    var file_pos = 0

    while True:
        _ = fh.seek(file_pos)
        var buffer = fh.read_bytes(buf_size)
        var newlines = find_chr_all_occurrences(buffer, NEW_LINE)
        var start = 0
        for i in range(0, len(newlines)):
            var newline = newlines[i]
            result.append(buffer[start:newline])
            # result.append(slice_tensor(buffer, start, newline))
            start = newline + 1

        if len(buffer) < BUF_SIZE:
            break
        file_pos += start
    return result


fn for_each_line[
    func: fn (Span[UInt8], Int, Int) capturing -> None
](path: String, buf_size: Int = BUF_SIZE) raises:
    """
    Call the provided callback on each line.

    The callback will be given a buffer, and the [start, end) of where the line is in that buffer.
    """
    var fh = open(path, "r")
    # var result = List[Tensor[DType.int8]]()
    var file_pos = 0

    while True:
        _ = fh.seek(file_pos)
        var buffer = fh.read_bytes(buf_size)
        var buffer_index = 0

        while True:
            var newline = find_chr_next_occurrence(
                buffer, NEW_LINE, buffer_index
            )
            if newline == -1:
                break

            func(buffer, buffer_index, newline)
            buffer_index = newline + 1

        file_pos += buffer_index
        if len(buffer) < BUF_SIZE:
            break


@always_inline
fn get_next_line[
    is_mutable: Bool, //, origin: Origin[is_mutable]
](buffer: Span[UInt8, origin], start: Int) -> Span[UInt8, origin]:
    """Function to get the next line using either SIMD instruction (default) or iteratively.
    """

    var in_start = start
    while buffer[in_start] == NEW_LINE:  # Skip leading \n
        in_start += 1
        if in_start >= len(buffer):
            return buffer[0:0]

    var next_line_pos = find_chr_next_occurrence(buffer, NEW_LINE, in_start)
    if next_line_pos == -1:
        next_line_pos = len(
            buffer
        )  # If no line separator found, return the reminder of the string, behavior subject to change
    return buffer[in_start:next_line_pos]


struct FileReader:
    """
    WIP FileReader for readying lines and bytes from a file in a buffered way.
    """

    var fh: FileHandle
    var file_offset: Int
    var buffer_offset: Int
    var buffer: UnsafePointer[UInt8]
    var buffer_size: Int
    var buffer_len: Int

    fn __init__(
        out self, owned fh: FileHandle, buffer_size: Int = BUF_SIZE
    ) raises:
        self.fh = fh^
        self.file_offset = 0
        self.buffer_offset = 0
        self.buffer_size = buffer_size
        self.buffer = UnsafePointer[UInt8].alloc(self.buffer_size)
        self.buffer_len = 0
        _ = self._fill_buffer()

    fn __del__(owned self):
        self.buffer.free()

    fn read_until(
        mut self, mut line_buffer: List[UInt8], char: UInt = NEW_LINE
    ) raises -> Int:
        """
        Fill the given `line_buffer` until the given `char` is hit.

        This does not include the `char`. The input vector is cleared before reading into it.
        """
        if self.buffer_len == 0:
            return 0

        # Find the next newline in the buffer
        var newline_index = find_chr_next_occurrence(
            Span[UInt8, __origin_of(self)](
                ptr=self.buffer, length=self.buffer_len
            ),
            NEW_LINE,
            self.buffer_offset,
        )

        # Try to refill the buffer
        if newline_index == -1:
            self.file_offset += self.buffer_offset
            var bytes_filled = self._fill_buffer()
            if bytes_filled == 0:
                # This seems dubious. If we haven't found a newline in the buffer, just return 0, which will also indicate EOF
                return 0
            newline_index = find_chr_next_occurrence(
                Span[UInt8, __origin_of(self)](
                    ptr=self.buffer, length=self.buffer_len
                ),
                char,
                self.buffer_offset,
            )
            if newline_index == -1:
                return 0

        # Copy the line into the provided buffer
        line_buffer.clear()
        for i in range(self.buffer_offset, newline_index):
            line_buffer.append(self.buffer[i])

        # Advance our position in our buffer
        self.buffer_offset = newline_index + 1

        return len(line_buffer)

    fn _fill_buffer(mut self) raises -> Int:
        # Copy the bytes at the end of the buffer to the front
        var kept = 0
        for i in range(self.buffer_offset, self.buffer_len):
            self.buffer[kept] = self.buffer[i]
            kept += 1

        # Now fill from there to end
        var tmp_ptr = self.buffer.offset(kept)
        var bytes_read = self.fh.read(tmp_ptr, self.buffer_size - kept)
        self.buffer_len = bytes_read.__int__() + kept
        self.buffer_offset = 0
        return self.buffer_len
