import std/[strformat, json]

const
  CharIgnore = [' ', '\t', '\v', '\r', '\f']
  CharNotKey = [',', '[', ']', '{', '}', ' ', '\t', '\v', '\r', '\n', '\f']
  CharSpecial = [',', ':', '[', ']', '{', '}']

type TokType = enum
  eof, invalid, openCB, closeCB, openSB, closeSB, colon, jsonString, quotelessString, multilineString, key, comment, number, tTrue, tFalse, tNull

type Token = object
  tokType: TokType
  value: string

var
  inData: string
  dataLen: int
  index = 0
  nextToken: Token
  outData: string

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
      nextToken.tokType = tTrue
      index += 4
    elif inData[index..(index+4)] == "false": # false literal
      nextToken.tokType = tFalse
      index += 5
    elif inData[index..(index+3)] == "null": # null literal
      nextToken.tokType = tNull
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
    elif key in expect: # json key
      nextToken.tokType = key
      let startIndex = index
      while inData[index] != ':':
        doAssert(inData[index] notin CharNotKey)
        index += 1
      nextToken.value = "\"" & inData[startIndex..index] & "\""
    else: # quoteless string
      nextToken.tokType = quotelessString
      doAssert(inData[index] notin CharNotKey, "Unquoted string started with invalid symbol.") # First char must be valid
      index += 1
      let startIndex = index
      while inData[index] != '\n':
        index += 1
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


