import std/[strformat, json, strutils]

type HjsonParsingError* = object of ValueError

const
  CharIgnore = {' ', '\t', '\v', '\r', '\f'}
  CharNotKey = {',', '[', ']', '{', '}', ' ', '\t', '\v', '\r', '\n', '\f'}

template dowhile(cond: typed, body: untyped) =
  while true:
    body
    if not cond: break

template doAssertParsingError(cond: untyped, msg = "") =
  if not cond:
    raise newException(HjsonParsingError, msg)

# Check if the current character and at least <margin> more characters are left
template checkIndex(margin = 0) =
  doAssertParsingError(index + margin < dataLen, "Unexpected end of file.")

# Check index when parsing number
template checkIndexNumber =
  if index >= dataLen:
    isNumber = false
    break checkIsNumber

type TokType = enum
  none, eof, invalid, openCB, closeCB, openSB, closeSB, colon, jsonStr, quotelessString, multilineString, key, comment, number, literal, newline, comma

type Token = object
  tokType: TokType
  value: string

# prototypes
proc parseObject()
proc parseMember()
proc parseArray()

var
  inData: string
  dataLen: int
  index = 0
  nextToken: Token
  outData: string

template digits =
  while inData[index] in '0'..'9':
    index += 1
    checkIndexNumber()

# ---------------
# Lexer
# ---------------

proc getNextToken(expect: varargs[TokType]) =
  while index < dataLen and inData[index] in CharIgnore:
    index += 1
  
  # If end of file, return
  if index >= dataLen:
    nextToken.tokType = eof
  else:
    case inData[index]
    of '{':
      nextToken.tokType = openCB
      index += 1

    of '}':
      nextToken.tokType = closeCB
      index += 1

    of '[':
      nextToken.tokType = openSB
      index += 1

    of ']':
      nextToken.tokType = closeSB
      index += 1
    
    of ':':
      nextToken.tokType = colon
      index += 1
    
    of '\n':
      nextToken.tokType = newline
      index += 1
    
    of ',':
      nextToken.tokType = comma
      index += 1

    of '\'', '"':
      if index+2 < dataLen and inData[index..(index+2)] == "'''":

        # Multiline
        nextToken.tokType = multilineString
        index += 3
        checkIndex(2)
        let startIndex = index
        while inData[index..(index+2)] != "'''":
          index += 1
          checkIndex(2)
        var val = inData[startIndex..<index]

        # Remove up to 1 newline
        if val.len != 0 and val[0] == '\n':
          val = val[1..^1]
        if val.len != 0 and val[^1] == '\n':
          val = val[0..^2]

        nextToken.value = escapeJson(val)
        index += 3

      else:
        nextToken.tokType = jsonStr
        let startQuote = inData[index]
        index += 1
        checkIndex()
        let startIndex = index

        while not (inData[index] == startQuote and inData[index-1] != '\\'):
          index += 1
          checkIndex()
        
        nextToken.value = "\"" & inData[startIndex..<index] & "\""
        index += 1
    
    of '#':
      nextToken.tokType = comment
      while inData[index] != '\n':
        index += 1
        # checkIndex()
        if index >= dataLen: break
      # index += 1

    else:
      if index+3 < dataLen and inData[index..(index+3)] == "true": # true literal
        nextToken.tokType = literal
        nextToken.value = "true"
        index += 4
      elif index+4 < dataLen and inData[index..(index+4)] == "false": # false literal
        nextToken.tokType = literal
        nextToken.value = "false"
        index += 5
      elif index+3 < dataLen and inData[index..(index+3)] == "null": # null literal
        nextToken.tokType = literal
        nextToken.value = "null"
        index += 4
      elif inData[index..(index+1)] == "//": # line comment
        nextToken.tokType = comment
        while inData[index] != '\n':
          index += 1
          # checkIndex()
          if index >= dataLen: break
      elif inData[index..(index+1)] == "/*": # multiline comment
        nextToken.tokType = comment
        index += 2
        while not (inData[index] == '*' and inData[index+1] == '/'):
          index += 1
          checkIndex(1)
        index += 2
      elif key in expect: # hjson key
        nextToken.tokType = key
        let startIndex = index
        while inData[index] != ':':
          doAssertParsingError(inData[index] notin CharNotKey, &"Hjson key contained invalid symbol '{escapeJsonUnquoted($inData[index])}'.")
          index += 1
          checkIndex()
        nextToken.value = escapeJson(inData[startIndex..<index])
      else: # quoteless string or number
        # nextToken.tokType = quotelessString
        doAssertParsingError(inData[index] notin CharNotKey, &"Unquoted string started with invalid symbol '{inData[index]}'.") # First char must be valid

        let startIndex = index

        # Check if it is a number
        var isNumber = true
        block checkIsNumber:
          # negative sign
          if inData[index] == '-':
            index += 1
            checkIndexNumber()
          # first digits (if first is zero then none can follow)
          if inData[index] == '0':
            index += 1
            checkIndexNumber()
          elif inData[index] in '1'..'9':
            index += 1
            checkIndexNumber()
            digits()
          else: # there must be digits
            isNumber = false
            break checkIsNumber
          # decimal point
          if inData[index] == '.':
            index += 1
            checkIndexNumber()
            # decimal digits
            if inData[index] in '0'..'9':
              index += 1
              checkIndexNumber()
              digits()
            else: # decimal point must be followed by digits
              isNumber = false
              break checkIsNumber
          # exponent
          if inData[index] in ['e', 'E']:
            index += 1
            checkIndexNumber()
            # optional exponent sign
            if inData[index] in ['+', '-']:
              index += 1
              checkIndexNumber()
            # exponent digits
            if inData[index] in '0'..'9':
              index += 1
              checkIndexNumber()
              digits()
            else: # exponent must be followed by digits
              isNumber = false
              break checkIsNumber
          # trailing whitespace
          while inData[index] in CharIgnore:
            index += 1
            checkIndexNumber()
          if inData[index] notin ['\n', ',', ']', '}']: # only these can follow a number
            isNumber = false

        if isNumber:
          nextToken.tokType = number
          nextToken.value = inData[startIndex..<index]
        else:
          nextToken.tokType = quotelessString
          index = startIndex + 1
          while inData[index] != '\n':
            index += 1
            checkIndex()
          nextToken.value = escapeJson(inData[startIndex..<index])
  
  doAssertParsingError(expect.len == 0 or nextToken.tokType in expect, &"Expected one of '{expect}' but got '{nextToken.tokType}'.")

# ----------------
# Parser
# ----------------

proc parseObject() =
  outData &= "{"

  # Members
  var first = true
  while true:
    var seenComma = false
    dowhile nextToken.tokType in [comment, newline, comma]:
      getNextToken(jsonStr, key, closeCB, comment, newline, comma)
      if nextToken.tokType == comma:
        doAssertParsingError(not seenComma, "Multiple consecutive commas in object.")
        doAssertParsingError(not first, "Comma at start of object.")
        seenComma = true

    # if nextToken.tokType in [comment, newline]:
    #   continue

    if nextToken.tokType == closeCB:
      break
    
    if first:
      first = false
    else:
      outData &= ","

    parseMember()
  
  # End of object
  outData &= "}"

proc parseMember() =
  outData &= nextToken.value
  getNextToken(colon)
  outData &= ":"

  dowhile nextToken.tokType in [comment, newline]:
    getNextToken(openCB, openSB, jsonStr, quotelessString, multilineString, number, literal, comment, newline)

  # Value
  case nextToken.tokType
  of openCB: # object
    parseObject()
  of openSB: # array
    parseArray()
  of jsonStr, quotelessString, multilineString, number, literal:
    outData &= nextToken.value
  else:
    doAssert(false, "Error: This code is supposed to be unreachable. " & $nextToken.tokType)

proc parseArray() =
  outData &= "["

  var first = true
  while true:
    var seenComma = false
    dowhile nextToken.tokType in [comment, newline, comma]:
      getNextToken(openCB, openSb, jsonStr, quotelessString, multilineString, number, literal, comment, newline, comma, closeSB)
      if nextToken.tokType == comma:
        doAssertParsingError(not seenComma, "Multiple consecutive commas in object.")
        doAssertParsingError(not first, "Comma at start of object.")
        seenComma = true

    if nextToken.tokType == closeSB:
      break

    if first:
      first = false
    else:
      outData &= ","

    case nextToken.tokType
    of openCB: # object
      parseObject()
    of openSB: # array
      parseArray()
    of jsonStr, quotelessString, multilineString, number, literal:
      outData &= nextToken.value
    else:
      doAssert(false, "Error: This code is supposed to be unreachable.")

  outData &= "]"


proc hjson2json*(data: string): string =
  # set globals
  inData = data.replace("\r", "") # remove carriage return
  dataLen = inData.len
  index = 0
  outData = ""

  dowhile nextToken.tokType != openCB:
    getNextToken(openCB, newline, comment)

  parseObject()

  dowhile nextToken.tokType != eof:
    getNextToken(eof, newline, comment)


  return outData
