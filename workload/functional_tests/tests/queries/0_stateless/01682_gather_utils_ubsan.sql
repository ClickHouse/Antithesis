SELECT arrayResize([1, 2, 3], -9223372036854775808); -- { serverError TOO_LARGE_ARRAY_SIZE }