SELECT arrayDifference([toDecimal32(0.0,4), toDecimal32(1.0,4)]) x, toTypeName(x);
SELECT arrayDifference([toDecimal64(0.0,8), toDecimal64(1.0,8)]) x, toTypeName(x);
SELECT arrayDifference([toDecimal128(0.0,8), toDecimal128(1.0,8)]) x, toTypeName(x);
SELECT '-';
SELECT arraySum([toDecimal32(0.0,4), toDecimal32(1.0,4)]) x, toTypeName(x);
SELECT arraySum([toDecimal64(0.0,8), toDecimal64(1.0,8)]) x, toTypeName(x);
SELECT arraySum([toDecimal128(0.0,8), toDecimal128(1.0,8)]) x, toTypeName(x);
SELECT '-';
SELECT arrayCumSum([toDecimal32(1.0,4), toDecimal32(1.0,4)]) x, toTypeName(x);
SELECT arrayCumSum([toDecimal64(1.0,8), toDecimal64(1.0,8)]) x, toTypeName(x);
SELECT arrayCumSum([toDecimal128(1.0,8), toDecimal128(1.0,8)]) x, toTypeName(x);
SELECT '-';
SELECT arrayCumSumNonNegative([toDecimal32(1.0,4), toDecimal32(1.0,4)]) x, toTypeName(x);
SELECT arrayCumSumNonNegative([toDecimal64(1.0,8), toDecimal64(1.0,8)]) x, toTypeName(x);
SELECT arrayCumSumNonNegative([toDecimal128(1.0,8), toDecimal128(1.0,8)]) x, toTypeName(x);
SELECT '-';
SELECT arrayCompact([toDecimal32(1.0,4), toDecimal32(1.0,4)]) x, toTypeName(x);
SELECT arrayCompact([toDecimal64(1.0,8), toDecimal64(1.0,8)]) x, toTypeName(x);
SELECT arrayCompact([toDecimal128(1.0,8), toDecimal128(1.0,8)]) x, toTypeName(x);
SELECT '-';
