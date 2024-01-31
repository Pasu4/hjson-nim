import unittest

import hjson

template checkErrorPosition(ln, col: int) =
  try:
    discard hjson2json(input)
    raise newException(AssertionDefect, "Function should have raised an exception.")
  except HjsonParsingError as e:
    check e.errorPosition[0] == ln
    check e.errorPosition[1] == col

test "invalid symbol in key":
  let input = """
{
  abc}def: 42
}"""
  checkErrorPosition(2, 3)

test "unexpected eof":
  let input = "{\nabc:"
  checkErrorPosition(2, 4)

test "unexpected end of object":
  let input = "{\nabc:\n}"
  checkErrorPosition(3, 1)

test "unmatched quote":
  let input = "{\nabc: \"hello}"
  checkErrorPosition(2, 6)

test "unmatched multiline quote":
  let input = "{\nabc: '''hello}"
  checkErrorPosition(2, 6)

test "'}' after unquoted string without newline":
  let input = """
{
  abc: {cde: hello}
}"""
  checkErrorPosition(3, 1)

test "consecutive commas in object":
  let input = """
{
  abc: 1,
  def: 2,
  ,
  ghi: 3
}"""
  checkErrorPosition(4, 3)

test "consecutive commas in array":
  let input = """
{
  ary: [
    "abc",
    "def",
    ,
    "ghi"
  ]
}"""
  checkErrorPosition(5, 5)

test "leading comma in object":
  let input = """
{
  ,
  abc: 1,
  def: 2,
  ghi: 3
}"""
  checkErrorPosition(2, 3)

test "leading comma in array":
  let input = """
{
  ary: [
    ,
    "abc",
    "def",
    "ghi"
  ]
}"""
  checkErrorPosition(3, 5)

test "error position":
  let input = """
{
  ary: [
    ,
    "abc",
    "def",
    "ghi"
  ]
}"""
  checkErrorPosition(3, 5)

test "multiple root objects":
  let input = """
{
  abc: 10
}
{
  def: 20
}"""
  checkErrorPosition(4, 1)
