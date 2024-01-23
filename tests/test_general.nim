# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import hjson

test "empty root":
  let
    input = "{}"
    output = hjson2json(input)
  check output == """{}"""

test "quoteless string member":
  let
    input = """
{
  test: abcd
}"""
    output = hjson2json(input)
  check output == """{"test":"abcd"}"""

test "quoted string member":
  let
    input = "{test: \"abcd\"}"
    output = hjson2json(input)
  check output == """{"test":"abcd"}"""

test "quoted key":
  let
    input = "{\"test\": abcd\n}"
    output = hjson2json(input)
  check output == """{"test":"abcd"}"""

test "single quoted string":
  let
    input = "{test: 'abcd'}"
    output = hjson2json(input)
  check output == """{"test":"abcd"}"""

test "multiline string":
  let
    input = "{test: '''\nabcd\n'''}"
    output = hjson2json(input)
  check output == """{"test":"abcd"}"""

test "quotes in multiline string":
  let
    input = "{test: '''\"abcd\"\n''\n'efgh'\n\\'''}"
    output = hjson2json(input)
  check output == """{"test":"\"abcd\"\n''\n'efgh'\n\\"}"""

test "multiple strings":
  let
    input = """
{
  test1: abcd
  test2: "efgh"
  test3: 'ijkl'
  "test4": mnop
  'test5': qrst
  test6:
'''
uvw
xyz
'''
}"""
    output = hjson2json(input)
  check output == """{"test1":"abcd","test2":"efgh","test3":"ijkl","test4":"mnop","test5":"qrst","test6":"uvw\nxyz"}"""

test "numbers":
  let
    input = """
{
  num1: 123
  num2: 0
  num3: 1.1
  num4: 1e10
  num5: 2e+2
  num6: 3e-12
  num7: 4.5e2
  num8: 0.1e-0
  num9: -20
  num10: -0
  num11: -1e11
  num12: -2.9e-3
}"""
    output = hjson2json(input)
  check output == """{"num1":123,"num2":0,"num3":1.1,"num4":1e10,"num5":2e+2,"num6":3e-12,"num7":4.5e2,"num8":0.1e-0,"num9":-20,"num10":-0,"num11":-1e11,"num12":-2.9e-3}"""

test "empty object":
  let
    input = """
{
  obj1: {}
  obj2: { }
  obj3: {

  }
}"""
    output = hjson2json(input)
  check output == """{"obj1":{},"obj2":{},"obj3":{}}"""

test "nested object":
  let
    input = """
{
  obj: {
    key1: value
    obj: {
      key: value
    }
    key2: value2
  }
}"""
    output = hjson2json(input)
  check output == """{"obj":{"key1":"value","obj":{"key":"value"},"key2":"value2"}}"""

test "empty array":
  let
    input = """
{
  ary1: []
  ary2: [ ]
  ary3: [

  ]
}"""
    output = hjson2json(input)
  check output == """{"ary1":[],"ary2":[],"ary3":[]}"""

test "array elements":
  let
    input = """
{
  ary1: [{}, [], "abc", 'def', 1, -1, true, false, null]
  ary2: [
    {}
    []
    "abc"
    'def'
    ghi
'''
jkl
mno
'''
    1
    -1
    true
    false
    null
  ]
}"""
    output = hjson2json(input)
  check output == """{"ary1":[{},[],"abc","def",1,-1,true,false,null],"ary2":[{},[],"abc","def","ghi","jkl\nmno",1,-1,true,false,null]}"""

test "nested array":
  let
    input = """
{
  ary: [[[[], [[]]], []]]
}"""
    output = hjson2json(input)
  check output == """{"ary":[[[[],[[]]],[]]]}"""

test "literals":
  let
    input = """
{
  t: true
  f: false
  n: null
}"""
    output = hjson2json(input)
  check output == """{"t":true,"f":false,"n":null}"""

test "line comments (#)":
  let
    input = """
# comment 1
{ #comment 2
  # comment 3
  key1: val1
  # comment 4
  key2: # comment 5
    val2
  # comment 6
} # comment 7
# comment 8
"""
    output = hjson2json(input)
  check output == """{"key1":"val1","key2":"val2"}"""

test "line comments (//)":
  let
    input = """
// comment 1
{ //comment 2
  // comment 3
  key1: val1
  // comment 4
  key2: // comment 5
    val2
  // comment 6
} // comment 7
// comment 8
"""
    output = hjson2json(input)
  check output == """{"key1":"val1","key2":"val2"}"""

test "block comments":
  let
    input = """
/* comment 1 */
{ /*comment 2*/
  /* comment: 3
  */
  key1: val1
  /* comment 4
  */key2:/* comment 5
  */val2
/* comment 6
*/}/* comment 7 */
/**/
"""
    output = hjson2json(input)
  check output == """{"key1":"val1","key2":"val2"}"""

test "commas":
  let
    input = """
{
  ary: [1, 2, 3,],
  key1: 1,
  key2: 2,
}"""
    output = hjson2json(input)
  check output == """{"ary":[1,2,3],"key1":1,"key2":2}"""

test "newlines":
  let
    input = """

{

  key1:

    abc
  key2: 2


  ,key3: 3

,}

"""
    output = hjson2json(input)
  check output == """{"key1":"abc","key2":2,"key3":3}"""

test "not a number":
  let
    input = """
{
  notNumbers: [
    -abc-
    12345a
    -12e+2a
    1+1
    1-1
    1e2e3
    1.2.3
  ]
}"""
    output = hjson2json(input)
  check output == """{"notNumbers":["-abc-","12345a","-12e+2a","1+1","1-1","1e2e3","1.2.3"]}"""
