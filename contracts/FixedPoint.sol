// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

type FixedPoint is uint256;

using {add as +} for FixedPoint global;
using {sub as -} for FixedPoint global;
using {mul as *} for FixedPoint global;
using {div as /} for FixedPoint global;

uint256 constant DECIMALS = 1e18;

function add(FixedPoint a, FixedPoint b) pure returns (FixedPoint) {
    return FixedPoint.wrap(FixedPoint.unwrap(a) + FixedPoint.unwrap(b));
}

function sub(FixedPoint a, FixedPoint b) pure returns (FixedPoint) {
    return FixedPoint.wrap(FixedPoint.unwrap(a) - FixedPoint.unwrap(b));
}

function mul(FixedPoint a, FixedPoint b) pure returns (FixedPoint) {
    return FixedPoint.wrap(FixedPoint.unwrap(a) * FixedPoint.unwrap(b) / DECIMALS);
}

function div(FixedPoint a, FixedPoint b) pure returns (FixedPoint) {
    return FixedPoint.wrap(FixedPoint.unwrap(a) * DECIMALS / FixedPoint.unwrap(b));
}

function fromFraction(uint256 numerator, uint256 denominator) pure returns (FixedPoint) {
    return FixedPoint.wrap(numerator * DECIMALS / denominator);
}

function mulFixedPoint(uint256 a, FixedPoint b) pure returns (uint256) {
    return a * FixedPoint.unwrap(b) / DECIMALS;
}

function divFixedPoint(uint256 a, FixedPoint b) pure returns (uint256) {
    return a * DECIMALS / FixedPoint.unwrap(b);
}