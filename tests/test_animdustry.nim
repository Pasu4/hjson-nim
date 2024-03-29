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

test "map.hjson":
  let
    input = """
{
    songName: Anuke - Boss 1
    music: boss1
    bpm: 100.0
    beatOffset: 0.0
    maxHits: 10
    copperAmount: 8
    fadeColor: "fa874c"
    alwaysUnlocked: true
    drawPixel: [
        # Draw spore background
        {type: "MixColor", name: "c1", col1: "#7c4b80", col2: "#6b4474", factor: "sin(state_time) / 2 + 0.5"}
        {type: "MixColor", name: "c2", col1: "#7c4b80", col2: "#6b4474", factor: "cos(state_time) / 2 + 0.5"},
        {type: "DrawStripes", col1: "c1", col2: "c2"},
        {type: "DrawBeatSquare", "col": "#f25555"},
        
        # Draw space
        {type: "MixColor", name: "c3", col1: "#00000000", col2: "#0000007f", factor: "min(1, max(0, (state_turn - state_moveBeat - 24) / 8))"},
        {type: "MixColor", name: "c3", col1: "c3", col2: "#ff00007f", factor: "(state_turn >= 32) * state_moveBeat ^ 2"},
        {type: "DrawSpace", "col": "c3"},
        
        # Draw spore storm
        {type: "DrawFlame", col1: "#7457ce", col2: "#7457ce", "time": "state_time"}
    ],
    draw: [
        {type: "DrawTilesSquare", col2: "colorRed"}
    ],
    update: [
        {type: "Condition", condition: "state_newTurn", then: [
            {type: "Turns", "fromTurn": 4, toTurn: "4 + mapSize * 2", interval: 1, body: [
                {type: "EffectWarn", pos: "vec2(state_turn - 4 - mapSize, 0)", life: "beatSpacing"},
                {type: "MakeDelay", "callback": [
                    {type: "MakeBulletCircle", pos: "vec2(state_turn - 4 - mapSize, 0)"}
                ]}
            ]}
        ]}
    ]
}"""
    output = hjson2json(input)
  check output == """{"songName":"Anuke - Boss 1","music":"boss1","bpm":100.0,"beatOffset":0.0,"maxHits":10,"copperAmount":8,"fadeColor":"fa874c","alwaysUnlocked":true,"drawPixel":[{"type":"MixColor","name":"c1","col1":"#7c4b80","col2":"#6b4474","factor":"sin(state_time) / 2 + 0.5"},{"type":"MixColor","name":"c2","col1":"#7c4b80","col2":"#6b4474","factor":"cos(state_time) / 2 + 0.5"},{"type":"DrawStripes","col1":"c1","col2":"c2"},{"type":"DrawBeatSquare","col":"#f25555"},{"type":"MixColor","name":"c3","col1":"#00000000","col2":"#0000007f","factor":"min(1, max(0, (state_turn - state_moveBeat - 24) / 8))"},{"type":"MixColor","name":"c3","col1":"c3","col2":"#ff00007f","factor":"(state_turn >= 32) * state_moveBeat ^ 2"},{"type":"DrawSpace","col":"c3"},{"type":"DrawFlame","col1":"#7457ce","col2":"#7457ce","time":"state_time"}],"draw":[{"type":"DrawTilesSquare","col2":"colorRed"}],"update":[{"type":"Condition","condition":"state_newTurn","then":[{"type":"Turns","fromTurn":4,"toTurn":"4 + mapSize * 2","interval":1,"body":[{"type":"EffectWarn","pos":"vec2(state_turn - 4 - mapSize, 0)","life":"beatSpacing"},{"type":"MakeDelay","callback":[{"type":"MakeBulletCircle","pos":"vec2(state_turn - 4 - mapSize, 0)"}]}]}]}]}"""