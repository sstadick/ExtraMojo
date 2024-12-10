# ExtraMojo

Extra functionality to extend the Mojo std lib.

*Supports mojo 24.5.0 (e8aacb9)*

## Install / Usage

See docs for [numojo](https://github.com/Mojo-Numerics-and-Algorithms-group/NuMojo/tree/v0.3?tab=readme-ov-file#how-to-install) and just do that for this package until Mojo has true package / library support.

tl;dr;

In your project `mojo run -I "../ExtraMojo" my_example_file.mojo`.
Not the bit about how to add this project to your LSP so things resolve in VSCode.


## Tasks

```
magic run test
magic run format
magic run build
```

## Examples

Reading a file line by line.
```mojo
from ExtraMojo.fs.file import FileReader

var fh = open(file, "r")
var reader = FileReader(fh^, buffer_size=1024)
var buffer = List[UInt8]()
var counter = 0
while reader.read_until(buffer) != 0: # Note read until defaults to b'\n', but you can pass in any other delim.
    assert_equal(expected_lines[counter].as_bytes(), buffer)
    counter += 1
assert_equal(counter, len(expected_lines))
```

Simple Regex
```mojo
fn test_start_anchor() raises:
    var re = "^cat"
    assert_true(is_match(re, "cats of a feather"))
    assert_false(is_match(re, "bird cats of a cat"))


fn test_end_anchor() raises:
    var re = "what$"
    assert_true(is_match(re, "It is what"))
    assert_false(is_match(re, "what is in the box"))


fn test_dot() raises:
    var re = "w.t"
    assert_true(is_match(re, "Is that a witty remark?"))
    assert_false(is_match(re, "wt is that what thing there"))


fn test_star() raises:
    var re = "wha*"
    assert_true(is_match(re, "whaaaaaaat am I doing here"))
    assert_false(is_match(re, "wt am I doing here"))


fn test_literal() raises:
    var re = "ACTG"
    assert_true(is_match(re, "CTGGGACGCCCACTG"))
    assert_false(is_match(re, "CTGGGACGCCCACG"))


fn test_dot_star() raises:
    var re = "STAR.*"
    assert_true(is_match(re, "I'M A STAR!!!!!"))
    assert_false(is_match(re, "I'm not a STArsss"))


fn test_all() raises:
    assert_true(is_match("^cat.*$", "catsssssss"))
    assert_false(is_match("^cat.*$", "many catsssssss"))
```



## Attribution

- Much of the first draft of the File and Tensor code was taken from [here](https://github.com/MoSafi2/MojoFastTrim/tree/restructed), which has now moved [here](https://github.com/MoSafi2/BlazeSeq).