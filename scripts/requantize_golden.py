#!/usr/bin/env python3
"""Independent requantize_relu reference model and deterministic vector generator.

Rounding contract: round-to-nearest, ties away from zero; optional ReLU is
applied after shifting and before signed INT4/INT8 saturation.
"""
from __future__ import annotations

import argparse
import random
from pathlib import Path

INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1


def requantize(accumulator: int, shift_amount: int, relu_enable: int, int8_mode: int) -> int:
    """Return the signed quantized output defined by the RTL's intended contract."""
    if not INT32_MIN <= accumulator <= INT32_MAX:
        raise ValueError("accumulator must fit signed INT32")
    if not 0 <= shift_amount <= 31:
        raise ValueError("shift_amount must be in [0, 31]")

    if shift_amount:
        magnitude = abs(accumulator)
        rounded_magnitude = (magnitude + (1 << (shift_amount - 1))) >> shift_amount
        shifted = -rounded_magnitude if accumulator < 0 else rounded_magnitude
    else:
        shifted = accumulator

    if relu_enable and shifted < 0:
        shifted = 0

    low, high = (-128, 127) if int8_mode else (-8, 7)
    return min(high, max(low, shifted))


def directed_cases():
    values = [
        INT32_MIN, INT32_MIN + 1, -100000, -1000, -257, -129, -128,
        -17, -10, -9, -8, -7, -6, -5, -3, -2, -1, 0, 1, 2, 3, 5, 6,
        7, 8, 9, 10, 17, 127, 128, 129, 257, 1000, 100000, INT32_MAX - 1,
        INT32_MAX,
    ]
    for acc in values:
        for shift in (0, 1, 2, 3, 7, 15, 30, 31):
            for relu in (0, 1):
                for int8_mode in (0, 1):
                    yield acc, shift, relu, int8_mode


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--vectors", required=True, help="output text vector path")
    parser.add_argument("--count", type=int, default=2048, help="number of random vectors")
    parser.add_argument("--seed", type=int, default=20261024, help="deterministic PRNG seed")
    args = parser.parse_args()

    if args.count < 0:
        parser.error("--count must be non-negative")

    out = Path(args.vectors)
    out.parent.mkdir(parents=True, exist_ok=True)
    rng = random.Random(args.seed)
    cases = list(directed_cases())
    for _ in range(args.count):
        accumulator = rng.randint(INT32_MIN, INT32_MAX)
        shift = rng.randint(0, 31)
        relu = rng.randint(0, 1)
        int8_mode = rng.randint(0, 1)
        cases.append((accumulator, shift, relu, int8_mode))

    # Small self-checks make the intended signed rounding convention explicit.
    assert requantize(10, 2, 0, 1) == 3
    assert requantize(-10, 2, 0, 1) == -3
    assert requantize(9, 2, 0, 1) == 2
    assert requantize(-9, 2, 0, 1) == -2
    assert requantize(INT32_MIN, 31, 0, 1) == -1

    with out.open("w", encoding="ascii") as f:
        for acc, shift, relu, int8_mode in cases:
            expected = requantize(acc, shift, relu, int8_mode)
            f.write(f"{acc} {shift} {relu} {int8_mode} {expected}\n")

    print(
        f"PYTHON GOLDEN MODEL PASSED: {len(cases)} vectors "
        f"(directed={len(cases) - args.count}, random={args.count}, seed={args.seed})"
    )


if __name__ == "__main__":
    main()
