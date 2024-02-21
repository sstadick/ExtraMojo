from algorithm import vectorize


@always_inline
fn slice_tensor[
    T: DType, USE_SIMD: Bool = True
](in_tensor: Tensor[T], start: Int, end: Int) -> Tensor[T]:
    """
    Generic Function that returns a python-style tensor slice from start till end (not inclusive).
    """
    if start >= end:
        return Tensor[T](0)

    @parameter
    if USE_SIMD:
        return slice_tensor_simd(in_tensor, start, end)
    else:
        return slice_tensor_iter(in_tensor, start, end)


@always_inline
fn slice_tensor_simd[T: DType](in_tensor: Tensor[T], start: Int, end: Int) -> Tensor[T]:
    """
    Generic Function that returns a python-style tensor slice from start till end (not inclusive).
    """

    var out_tensor: Tensor[T] = Tensor[T](end - start)

    @parameter
    fn inner[simd_width: Int](size: Int):
        let transfer = in_tensor.simd_load[simd_width](start + size)
        out_tensor.simd_store[simd_width](size, transfer)

    vectorize[simdwidthof[T](), inner](out_tensor.num_elements())

    return out_tensor


@always_inline
fn slice_tensor_iter[T: DType](in_tensor: Tensor[T], start: Int, end: Int) -> Tensor[T]:
    var out_tensor = Tensor[T](end - start)
    for i in range(start, end):
        out_tensor[i - start] = in_tensor[i]
    return out_tensor
