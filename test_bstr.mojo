from ExtraMojo.bstr.bstr import SplitIterator, find
from memory import Span
from testing import *


fn main() raises:
    test_iterator()
    test_find()


fn s(bytes: Span[UInt8]) -> String:
    """Convert bytes to a String."""
    var buffer = String()
    buffer.write_bytes(bytes)
    return buffer


fn test_find() raises:
    var haystack = "ABCDEFGhijklmnop".as_bytes()
    var expected = 4
    var answer = find(haystack, "EFG".as_bytes()).value()
    assert_equal(answer, expected)


fn test_iterator() raises:
    var input = "ABCD\tEFGH\tIJKL\nMNOP".as_bytes()
    var expected = List(
        "ABCD".as_bytes(), "EFGH".as_bytes(), "IJKL\nMNOP".as_bytes()
    )
    var output = List[Span[UInt8, StaticConstantOrigin]]()
    for value in SplitIterator(input, ord("\t")):
        output.append(value)
    for i in range(len(expected)):
        assert_equal(s(output[i]), s(expected[i]), "Not equal")
