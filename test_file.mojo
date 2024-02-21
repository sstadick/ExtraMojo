from python import Python
from testing import *

from ExtraMojo.fs.file import FileReader


fn create_file(path: String, lines: DynamicVector[String]) raises:
    with open(path, "w") as fh:
        for i in range(len(lines)):
            fh.write(lines[i])
            fh.write("\n")


fn strings_for_writing(size: Int) -> DynamicVector[String]:
    var result = DynamicVector[String]()
    for i in range(size):
        result.append("Line: " + str(i) + "X")
    return result


fn test_read_lines(file: Path, expected_lines: DynamicVector[String]) raises:
    let fh = open(file, "r")
    var reader = FileReader(fh ^, buffer_size=1024)
    var buffer = DynamicVector[Int8]()
    var counter = 0
    var expected_buffer = DynamicVector[Int8]()
    while reader.read_until(buffer) != 0:
        expected_buffer.clear()

        # Have to convert expected to a vector of bytes because converting to a string truncates by 1 for some reason
        # https://github.com/modularml/mojo/issues/1753
        for i in range(len(expected_lines[counter])):
            expected_buffer.append(ord(expected_lines[counter][i]))
        assert_equal(expected_buffer, buffer)
        counter += 1
    assert_equal(counter, len(expected_lines))


# https://github.com/modularml/mojo/issues/1753
# fn test_stringify() raises:
#     var example = DynamicVector[Int8]()
#     example.append(ord("e"))
#     example.append(ord("x"))

#     var container = DynamicVector[Int8]()
#     for i in range(len(example)):
#         container.append(example[i])
#     let stringifed = String(container)
#     assert_equal("ex", stringifed)
#    # Unhandled exception caught during execution: AssertionError: ex is not equal to e


fn main() raises:
    # TODO: use python to create a tempdir
    let tempfile = Python.import_module("tempfile")
    let tempdir = tempfile.TemporaryDirectory()
    let file = Path(tempdir.name) / "lines.txt"
    let strings = strings_for_writing(10000)
    create_file(file, strings)

    # Tests
    test_read_lines(str(file), strings)

    print("Success")

    _ = tempdir.cleanup()
