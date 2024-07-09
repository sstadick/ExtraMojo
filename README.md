# ExtraMojo

Extra functionality to extend the Mojo std lib.


## Usage

```
mojo package ./ExtraMojo
# Then, from wherever you want to use this package
mojo run -I <path to here>/ExtraMojo <your code>
```

## Testing

```
mojo package ./ExtraMojo && mojo run -I ./ExtraMojo test_file.mojo
mojo package ./ExtraMojo && mojo run -I ./ExtraMojo test_regex.mojo
```

## Attribution

- Much of the first draft of the File and Tensor code was taken from [here](https://github.com/MoSafi2/MojoFastTrim/tree/restructed)
