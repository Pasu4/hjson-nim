import std/[strformat, json]

const
  CharIgnore = {' ', '\t', '\v', '\r', '\f'}
  CharNotKey = {',', '[', ']', '{', '}', ' ', '\t', '\v', '\r', '\n', '\f'}
  CharSpecial = {',', ':', '[', ']', '{', '}'}

type TokType = enum
  eof, invalid, openCB, closeCB, openSB, closeSB, colon, jsonString, quotelessString, multilineString, key, comment, number, literal, newline, comma

type Token = object
  tokType: TokType
  value: string

var
  inData: string
  dataLen: int
  index = 0
  nextToken: Token
  outData: string

template digits =
  while inData[index] in '0'..'9':
    index += 1

proc getNextToken(expect: varargs[TokType]) =
  while index < dataLen and inData[index] in CharIgnore:
    index += 1
  
  # If end of file, return
  if index >= dataLen:
    nextToken.tokType = eof
    return

  case inData[index-1]
  of '{':
    nextToken.tokType = openCB
    index += 1

  of '}':
    nextToken.tokType = closeCB
    index += 1

  of ']':
    nextToken.tokType = openSB
    index += 1

  of '[':
    nextToken.tokType = closeSB
    index += 1
  
  of '\n':
    nextToken.tokType = newline
    index += 1
  
  of ',':
    nextToken.tokType = comma
    index += 1

  of '\'', '"':
    if inData[index..(index+2)] == "'''":
      # Multiline
      nextToken.tokType = multilineString
      index += 3
      while inData[index..(index+2)] != "'''":
        index += 1
      index += 3
    else:
      nextToken.tokType = jsonString
      let startQuote = inData[index]
      index += 1
      let startIndex = index

      while inData[index] != startQuote and not (inData[index-1] == '\\'):
        index += 1
      
      nextToken.value = "\"" & inData[startIndex..<index] & "\""
      index += 1
  
  of '#':
    nextToken.tokType = comment
    while inData[index] != '\n':
      index += 1
    index += 1

  else:
    if inData[index..(index+3)] == "true": # true literal
      nextToken.tokType = literal
      nextToken.value = "true"
      index += 4
    elif inData[index..(index+4)] == "false": # false literal
      nextToken.tokType = literal
      nextToken.value = "false"
      index += 5
    elif inData[index..(index+3)] == "null": # null literal
      nextToken.tokType = literal
      nextToken.value = "null"
      index += 4
    elif inData[index..(index+1)] == "//": # line comment
      nextToken.tokType = comment
      while inData[index] != '\n':
        index += 1
    elif inData[index..(index+1)] == "/*": # multiline comment
      nextToken.tokType = comment
      index += 2
      while not (inData[index] == '*' and inData[index+1] == '/'):
        index += 1
      index += 2
    elif key in expect: # hjson key
      nextToken.tokType = key
      let startIndex = index
      while inData[index] != ':':
        doAssert(inData[index] notin CharNotKey)
        index += 1
      nextToken.value = "\"" & inData[startIndex..index] & "\""
    else: # quoteless string or number
      # nextToken.tokType = quotelessString
      doAssert(inData[index] notin CharNotKey, &"Unquoted string started with invalid symbol: '{inData[index]}'.") # First char must be valid

      let startIndex = index

      # Check if it is a number
      var isNumber = true
      # negative sign
      if inData[index] == '-':
        index += 1
      # first digits (if first is zero then none can follow)
      if inData[index] == '0':
        index += 1
      elif inData[index] in '1'..'9':
        index += 1
        digits()
      else: # there must be digits
        isNumber = false
      # decimal point
      if inData[index] == '.':
        index += 1
        # decimal digits
        if inData[index] in '0'..'9':
          index += 1
          digits()
        else: # decimal point must be followed by digits
          isNumber = false
      # exponent
      if inData[index] in ['e', 'E']:
        index += 1
        # optional exponent sign
        if inData[index] in ['+', '-']:
          index += 1
        # exponent digits
        if inData[index] in '0'..'9':
          index += 1
          digits()
        else: # exponent must be followed by digits
          isNumber = false

      if isNumber:
        nextToken.tokType = number
        nextToken.value = inData[startIndex..<index]
      else:
        nextToken.tokType = quotelessString
        index = startIndex + 1
        while inData[index] != '\n':
          index += 1
        nextToken.value = inData[startIndex..<index]

      nextToken.value = escapeJson(inData[startIndex..index])
      index += 1
  
  doAssert(expect.len == 0 or nextToken.tokType in expect, &"Expected one of '{expect}' but got '{nextToken.tokType}'.")
  
proc parseMember() =
  outData &= nextToken.value
  getNextToken(colon)
  outData &= ":"
  getNextToken(openCB, openSB, jsonString, quotelessString, multilineString, number)
  

proc parseObject() =
  outData &= "{"

  getNextToken(jsonString, key, closeCB, comment)

  # Members
  while true:
    if nextToken.tokType != closeCB:
      parseMember()
    else: break
  
  # End of object
  outData &= "}"


proc hjson2json*(data: string): string =
  # set globals
  inData = data
  dataLen = inData.len
  index = 0
  outData = ""

  getNextToken(openCB)
  parseObject()
  getNextToken(eof)


