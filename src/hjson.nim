const Ignore = [' ', '\t', '\v', '\r', '\f']

type TokType = enum
  eof, invalid, openCB, closeCB, openSB, closeSB, 

type Token = object
  tokType: TokType
  value: string

var
  inData: string
  dataLen: int
  index = 0
  nextToken: Token
  outData: string

proc getNextToken() =
  while index < dataLen and inData[index] in Ignore:
    index += 1
  
  # If end of file, return
  if index >= dataLen:
    nextToken.tokType = eof
    return

  case inData[index]
  of '{':
    nextToken.tokType = openCB
  of '}':
    nextToken.tokType = closeCB
  of ']':
    nextToken.tokType = openSB
  of '[':
    nextToken.tokType = closeSB
  else:
    nextToken.tokType = invalid

proc parseObject() =
  discard

proc hjson2json*(data: string): string =
  # set globals
  inData = data
  dataLen = inData.len
  index = 0
  outData = ""

  


