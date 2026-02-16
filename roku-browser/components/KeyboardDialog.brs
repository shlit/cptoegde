sub init()
    m.inputDisplay = m.top.findNode("inputDisplay")
    m.cursorLabel = m.top.findNode("cursor")

    ' Keyboard layout
    m.rows = []
    m.rows.push(["1","2","3","4","5","6","7","8","9","0","-",".","/"])
    m.rows.push(["q","w","e","r","t","y","u","i","o","p"])
    m.rows.push(["a","s","d","f","g","h","j","k","l","@"])
    m.rows.push(["z","x","c","v","b","n","m","_",":","#"])
    m.rows.push(["SPACE", "CLEAR", ".com", "https://", "SEARCH", "GO"])

    m.currentRow = 0
    m.currentCol = 0
    m.inputBuffer = ""
    m.shiftMode = false

    buildKeyboard()
    updateDisplay()
    highlightKey()
end sub

sub buildKeyboard()
    rowNodes = [
        m.top.findNode("row1"),
        m.top.findNode("row2"),
        m.top.findNode("row3"),
        m.top.findNode("row4"),
        m.top.findNode("row5")
    ]

    for r = 0 to m.rows.count() - 1
        row = m.rows[r]
        rowNode = rowNodes[r]
        for c = 0 to row.count() - 1
            keyLabel = row[c]
            keyWidth = 85
            if keyLabel = "SPACE" then keyWidth = 240
            if keyLabel = "CLEAR" then keyWidth = 130
            if keyLabel = ".com" then keyWidth = 130
            if keyLabel = "https://" then keyWidth = 180
            if keyLabel = "SEARCH" then keyWidth = 160
            if keyLabel = "GO" then keyWidth = 130

            ' Key background
            keyBg = CreateObject("roSGNode", "Rectangle")
            keyBg.id = "key_" + str(r).trim() + "_" + str(c).trim()
            keyBg.width = keyWidth
            keyBg.height = 65
            keyBg.color = "#444444"

            ' Key label
            keyText = CreateObject("roSGNode", "Label")
            keyText.id = "keytext_" + str(r).trim() + "_" + str(c).trim()
            if keyLabel = "SPACE"
                keyText.text = "Space"
            else if keyLabel = "CLEAR"
                keyText.text = "Clear"
            else if keyLabel = "SEARCH"
                keyText.text = "Search"
            else if keyLabel = "GO"
                keyText.text = "Go >"
            else
                keyText.text = keyLabel
            end if
            keyText.font = "font:SmallSystemFont"
            keyText.color = "#FFFFFF"
            keyText.horizAlign = "center"
            keyText.vertAlign = "center"
            keyText.width = keyWidth
            keyText.height = 65
            keyText.translation = [0, 0]

            keyBg.appendChild(keyText)
            rowNode.appendChild(keyBg)
        end for
    end for
end sub

sub updateDisplay()
    m.inputDisplay.text = m.inputBuffer
    m.top.inputText = m.inputBuffer
end sub

sub highlightKey()
    ' Reset all key colors
    for r = 0 to m.rows.count() - 1
        for c = 0 to m.rows[r].count() - 1
            keyNode = m.top.findNode("key_" + str(r).trim() + "_" + str(c).trim())
            if keyNode <> invalid
                if r = m.currentRow and c = m.currentCol
                    keyNode.color = "#4A90D9"
                else
                    keyNode.color = "#444444"
                end if
            end if
        end for
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK"
        pressKey()
        return true
    else if key = "up"
        m.currentRow = m.currentRow - 1
        if m.currentRow < 0 then m.currentRow = m.rows.count() - 1
        if m.currentCol >= m.rows[m.currentRow].count()
            m.currentCol = m.rows[m.currentRow].count() - 1
        end if
        highlightKey()
        return true
    else if key = "down"
        m.currentRow = m.currentRow + 1
        if m.currentRow >= m.rows.count() then m.currentRow = 0
        if m.currentCol >= m.rows[m.currentRow].count()
            m.currentCol = m.rows[m.currentRow].count() - 1
        end if
        highlightKey()
        return true
    else if key = "left"
        m.currentCol = m.currentCol - 1
        if m.currentCol < 0 then m.currentCol = m.rows[m.currentRow].count() - 1
        highlightKey()
        return true
    else if key = "right"
        m.currentCol = m.currentCol + 1
        if m.currentCol >= m.rows[m.currentRow].count() then m.currentCol = 0
        highlightKey()
        return true
    else if key = "rewind"
        ' Backspace
        if len(m.inputBuffer) > 0
            m.inputBuffer = left(m.inputBuffer, len(m.inputBuffer) - 1)
            updateDisplay()
        end if
        return true
    else if key = "play"
        ' Submit
        m.top.submitted = m.top.submitted + 1
        return true
    else if key = "back"
        ' Cancel
        m.top.cancelled = m.top.cancelled + 1
        return true
    end if

    return false
end function

sub pressKey()
    if m.currentRow >= m.rows.count() then return
    if m.currentCol >= m.rows[m.currentRow].count() then return

    keyLabel = m.rows[m.currentRow][m.currentCol]

    if keyLabel = "SPACE"
        m.inputBuffer = m.inputBuffer + " "
    else if keyLabel = "CLEAR"
        m.inputBuffer = ""
    else if keyLabel = ".com"
        m.inputBuffer = m.inputBuffer + ".com"
    else if keyLabel = "https://"
        m.inputBuffer = "https://" + m.inputBuffer
    else if keyLabel = "SEARCH"
        ' Wrap current input as a Google search
        m.inputBuffer = "https://www.google.com/search?q=" + m.inputBuffer
        m.top.submitted = m.top.submitted + 1
        return
    else if keyLabel = "GO"
        m.top.submitted = m.top.submitted + 1
        return
    else
        m.inputBuffer = m.inputBuffer + keyLabel
    end if

    updateDisplay()
end sub
