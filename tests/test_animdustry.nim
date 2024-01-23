import unittest

import hjson

test "mod.hjson":
  let
    input = """
{
    name: Template
    namespace: template
    author: Pasu4
    description: Template for a mod for animdustry
}"""
    output = hjson2json(input)
  check output == """{"name":"Template","namespace":"template","author":"Pasu4","description":"Template for a mod for animdustry"}"""