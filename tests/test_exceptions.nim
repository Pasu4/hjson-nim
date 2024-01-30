import unittest

import hjson

test "invalid symbol in key":
  let input = """
{
  abc}def: 42
}"""
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

test "unexpected eof":
  let input = "{\nabc:"
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

test "unexpected end of object":
  let input = "{\nabc:\n}"
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

test "unmatched quote":
  let input = "{\nabc: \"hello}"
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

test "unmatched multiline quote":
  let input = "{\nabc: '''hello}"
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

test "'}' after unquoted string without newline":
  let input = """
{
  abc: {cde: hello}
}"""
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

test "consecutive commas in object":
  let input = """
{
  abc: 1,
  def: 2,
  ,
  ghi: 3
}"""
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

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
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

test "leading comma in object":
  let input = """
{
  ,
  abc: 1,
  def: 2,
  ghi: 3
}"""
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)

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
  doAssertRaises(HjsonParsingError):
    discard hjson2json(input)
