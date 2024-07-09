from python import Python
from testing import *
from pathlib.path import Path

from ExtraMojo.fs.file import FileReader


fn create_file(path: String, lines: List[String]) raises:
    with open(path, "w") as fh:
        for i in range(len(lines)):
            fh.write(lines[i])
            fh.write(StringRef("\n"))


fn strings_for_writing(size: Int) -> List[String]:
    var result = List[String]()
    for i in range(size):
        result.append("Line: " + str(i) + "X")
    return result


fn test_read_lines(file: Path, expected_lines: List[String]) raises:
    var fh = open(file, "r")
    print("Testing file: ", file)
    var reader = FileReader(fh^, buffer_size=1024)
    var buffer = List[UInt8]()
    var counter = 0
    var expected_buffer = List[UInt8]()
    while reader.read_until(buffer) != 0:
        expected_buffer.clear()

        # Have to convert expected to a vector of bytes because converting to a string truncates by 1 for some reason
        # https://github.com/modularml/mojo/issues/1753
        for i in range(len(expected_lines[counter])):
            expected_buffer.append(ord(expected_lines[counter][i]))

        assert_equal(len(expected_buffer), len(buffer))
        for i in range(len(expected_buffer)):
            assert_equal(expected_buffer[i], buffer[i])
        counter += 1
    assert_equal(counter, len(expected_lines))


# https://github.com/modularml/mojo/issues/1753
# fn test_stringify() raises:
#     var example = List[Int8]()
#     example.append(ord("e"))
#     example.append(ord("x"))

#     var container = List[Int8]()
#     for i in range(len(example)):
#         container.append(example[i])
#     var stringifed = String(container)
#     assert_equal("ex", stringifed)
#    # Unhandled exception caught during execution: AssertionError: ex is not equal to e


fn main() raises:
    # TODO: use python to create a tempdir
    var tempfile = Python.import_module("tempfile")
    var tempdir = tempfile.TemporaryDirectory()
    var file = Path(tempdir.name) / "lines.txt"
    var strings = strings_for_writing(10000)
    print("Creating Files")
    create_file(str(file), strings)
    print("Testing Read Lines")

    # Tests
    test_read_lines(str(file), strings)

    print("SUCCESS")

    _ = tempdir.cleanup()
