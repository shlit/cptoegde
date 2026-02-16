sub init()
    m.container = m.top.findNode("renderContainer")
    m.renderedLinks = []
    m.nodeCount = 0
    m.maxNodes = 400
    m.maxTokens = 2000

    m.selfClosingTags = {}
    m.selfClosingTags["br"] = true
    m.selfClosingTags["hr"] = true
    m.selfClosingTags["img"] = true
    m.selfClosingTags["input"] = true
    m.selfClosingTags["meta"] = true
    m.selfClosingTags["link"] = true
end sub

sub onHtmlChanged()
    renderHtml(m.top.htmlContent)
end sub

sub renderHtml(html as string)
    ' Clear previous content
    m.container.removeChildrenIndex(m.container.getChildCount(), 0)
    m.renderedLinks = []
    m.nodeCount = 0

    if html = "" then return

    ' Pre-process: remove script, style, head, noscript blocks
    cleaned = removeBlock(html, "script")
    cleaned = removeBlock(cleaned, "style")
    cleaned = removeBlock(cleaned, "noscript")
    cleaned = removeBlock(cleaned, "head")

    ' Parse and render the body content
    bodyStart = instr(1, lcase(cleaned), "<body")
    if bodyStart > 0
        bodyTagEnd = instr(bodyStart, cleaned, ">")
        if bodyTagEnd > 0
            bodyEnd = instr(bodyTagEnd, lcase(cleaned), "</body>")
            if bodyEnd > 0
                cleaned = mid(cleaned, bodyTagEnd + 1, bodyEnd - bodyTagEnd - 1)
            else
                cleaned = mid(cleaned, bodyTagEnd + 1)
            end if
        end if
    end if

    ' Tokenize the HTML into a list of elements
    tokens = tokenizeHtml(cleaned)

    ' Walk the token list building SceneGraph nodes
    renderTokens(tokens)

    ' Expose collected links
    m.top.renderedLinks = m.renderedLinks
end sub

' ============================================================
' Tokenizer: split HTML into text and tag tokens
' ============================================================
function tokenizeHtml(html as string) as object
    tokens = []
    pos = 1
    htmlLen = len(html)

    while pos <= htmlLen and tokens.count() < m.maxTokens
        ltPos = instr(pos, html, "<")
        if ltPos = 0
            ' Rest is plain text
            textChunk = mid(html, pos)
            if textChunk.trim() <> ""
                token = { kind: "text", value: textChunk }
                tokens.push(token)
            end if
            exit while
        end if

        ' Text before the tag
        if ltPos > pos
            textChunk = mid(html, pos, ltPos - pos)
            if textChunk.trim() <> ""
                token = { kind: "text", value: textChunk }
                tokens.push(token)
            end if
        end if

        ' Find end of tag
        gtPos = instr(ltPos, html, ">")
        if gtPos = 0
            ' Broken tag, treat rest as text
            textChunk = mid(html, ltPos)
            token = { kind: "text", value: textChunk }
            tokens.push(token)
            exit while
        end if

        tagStr = mid(html, ltPos + 1, gtPos - ltPos - 1)
        tagLower = lcase(tagStr).trim()

        ' Classify the tag
        if left(tagLower, 1) = "/"
            ' Closing tag
            tagName = mid(tagLower, 2).trim()
            spacePos = instr(1, tagName, " ")
            if spacePos > 0 then tagName = left(tagName, spacePos - 1)
            token = { kind: "close", tag: tagName, raw: tagStr }
            tokens.push(token)
        else
            ' Opening or self-closing tag
            tagName = tagLower
            spacePos = instr(1, tagName, " ")
            if spacePos > 0 then tagName = left(tagName, spacePos - 1)
            ' Remove trailing / for self-closing
            if right(tagName, 1) = "/" then tagName = left(tagName, len(tagName) - 1)

            isSelfClosing = (right(tagLower, 1) = "/") or (m.selfClosingTags.DoesExist(tagName))

            token = { kind: "open", tag: tagName, raw: tagStr, selfClosing: isSelfClosing }
            tokens.push(token)
        end if

        pos = gtPos + 1
    end while

    return tokens
end function

' ============================================================
' Renderer: walk tokens and create SceneGraph nodes
' ============================================================
sub renderTokens(tokens as object)
    ' State stack for nested styling
    styleStack = []
    currentStyle = getDefaultStyle()

    i = 0
    tokenCount = tokens.count()

    while i < tokenCount and m.nodeCount < m.maxNodes
        token = tokens[i]

        if token.kind = "text"
            renderTextNode(decodeEntities(token.value), currentStyle)
        else if token.kind = "open"
            tag = token.tag

            if tag = "h1" or tag = "h2" or tag = "h3" or tag = "h4" or tag = "h5" or tag = "h6"
                ' Add spacing before heading
                addSpacer(12)
                styleStack.push(currentStyle)
                currentStyle = copyStyle(currentStyle)
                if tag = "h1"
                    currentStyle.font = "font:LargeBoldSystemFont"
                    currentStyle.color = "#FFFFFF"
                else if tag = "h2"
                    currentStyle.font = "font:MediumBoldSystemFont"
                    currentStyle.color = "#FFFFFF"
                else if tag = "h3"
                    currentStyle.font = "font:MediumBoldSystemFont"
                    currentStyle.color = "#E0E0E0"
                else if tag = "h4"
                    currentStyle.font = "font:SmallBoldSystemFont"
                    currentStyle.color = "#E0E0E0"
                else
                    currentStyle.font = "font:SmallBoldSystemFont"
                    currentStyle.color = "#CCCCCC"
                end if

            else if tag = "b" or tag = "strong"
                styleStack.push(currentStyle)
                currentStyle = copyStyle(currentStyle)
                currentStyle.font = "font:SmallBoldSystemFont"

            else if tag = "i" or tag = "em"
                styleStack.push(currentStyle)
                currentStyle = copyStyle(currentStyle)
                ' Roku has no italic font, so use a distinct color
                currentStyle.color = "#B0C4DE"

            else if tag = "a"
                styleStack.push(currentStyle)
                currentStyle = copyStyle(currentStyle)
                currentStyle.color = "#6CB4EE"
                currentStyle.isLink = true
                currentStyle.linkUrl = extractHref(token.raw)
                ' Start tracking this link
                linkInfo = { url: currentStyle.linkUrl, text: "" }
                m.renderedLinks.push(linkInfo)

            else if tag = "p"
                addSpacer(8)

            else if tag = "br"
                addSpacer(4)

            else if tag = "hr"
                addHorizontalRule()

            else if tag = "li"
                addSpacer(2)
                renderTextNode("  •  ", currentStyle)

            else if tag = "ul" or tag = "ol"
                addSpacer(6)

            else if tag = "blockquote"
                styleStack.push(currentStyle)
                currentStyle = copyStyle(currentStyle)
                currentStyle.color = "#AAAAAA"
                currentStyle.indent = currentStyle.indent + 40
                addBlockquoteBorder()

            else if tag = "pre" or tag = "code"
                styleStack.push(currentStyle)
                currentStyle = copyStyle(currentStyle)
                currentStyle.color = "#90EE90"
                currentStyle.bgColor = "#1E1E1E"
                currentStyle.font = "font:SmallestSystemFont"

            else if tag = "div"
                addSpacer(4)

            else if tag = "table"
                addSpacer(6)
                addHorizontalRule()

            else if tag = "tr"
                addSpacer(2)

            else if tag = "td" or tag = "th"
                if tag = "th"
                    styleStack.push(currentStyle)
                    currentStyle = copyStyle(currentStyle)
                    currentStyle.font = "font:SmallBoldSystemFont"
                end if
            end if

        else if token.kind = "close"
            tag = token.tag

            if tag = "h1" or tag = "h2" or tag = "h3" or tag = "h4" or tag = "h5" or tag = "h6"
                addSpacer(8)
                if styleStack.count() > 0
                    currentStyle = styleStack.pop()
                end if

            else if tag = "b" or tag = "strong" or tag = "i" or tag = "em" or tag = "a"
                if styleStack.count() > 0
                    currentStyle = styleStack.pop()
                end if

            else if tag = "blockquote" or tag = "pre" or tag = "code"
                if styleStack.count() > 0
                    currentStyle = styleStack.pop()
                end if

            else if tag = "th"
                if styleStack.count() > 0
                    currentStyle = styleStack.pop()
                end if

            else if tag = "p"
                addSpacer(8)

            else if tag = "div"
                addSpacer(4)

            else if tag = "ul" or tag = "ol"
                addSpacer(6)

            else if tag = "table"
                addHorizontalRule()
                addSpacer(6)

            else if tag = "tr"
                addSpacer(2)

            else if tag = "td"
                ' Add tab-like spacing between cells
                renderTextNode("    ", currentStyle)
            end if
        end if

        i = i + 1
    end while

    if m.nodeCount >= m.maxNodes
        addSpacer(10)
        truncLabel = CreateObject("roSGNode", "Label")
        truncLabel.text = "[Content truncated - page too large for renderer]"
        truncLabel.font = "font:SmallestSystemFont"
        truncLabel.color = "#FF8888"
        truncLabel.width = m.top.renderWidth
        truncLabel.wrap = true
        m.container.appendChild(truncLabel)
    end if
end sub

' ============================================================
' Node creation helpers
' ============================================================
sub renderTextNode(text as string, style as object)
    if m.nodeCount >= m.maxNodes then return

    cleaned = text
    ' Collapse whitespace
    while instr(1, cleaned, "  ") > 0
        cleaned = cleaned.replace("  ", " ")
    end while
    cleaned = cleaned.replace(chr(10), " ")
    cleaned = cleaned.replace(chr(13), " ")
    cleaned = cleaned.trim()

    if cleaned = "" then return

    if style.bgColor <> ""
        ' Wrap in a Rectangle for background color
        wrapper = CreateObject("roSGNode", "Rectangle")
        wrapper.color = style.bgColor
        wrapper.width = m.top.renderWidth - style.indent
        wrapper.height = 30
        wrapper.translation = [style.indent, 0]

        label = CreateObject("roSGNode", "Label")
        label.text = cleaned
        label.font = style.font
        label.color = style.color
        label.width = m.top.renderWidth - style.indent - 20
        label.wrap = true
        label.maxLines = 0
        label.translation = [10, 5]

        wrapper.appendChild(label)
        m.container.appendChild(wrapper)
        m.nodeCount = m.nodeCount + 2
    else
        label = CreateObject("roSGNode", "Label")
        label.text = cleaned
        label.font = style.font
        label.color = style.color
        label.width = m.top.renderWidth - style.indent
        label.wrap = true
        label.maxLines = 0
        if style.indent > 0
            label.translation = [style.indent, 0]
        end if
        m.container.appendChild(label)
        m.nodeCount = m.nodeCount + 1
    end if

    ' Track link text for link collection
    if style.isLink and m.renderedLinks.count() > 0
        lastLink = m.renderedLinks[m.renderedLinks.count() - 1]
        if lastLink.text = ""
            lastLink.text = cleaned
        end if
    end if
end sub

sub addSpacer(height as integer)
    if m.nodeCount >= m.maxNodes then return
    spacer = CreateObject("roSGNode", "Rectangle")
    spacer.width = 1
    spacer.height = height
    spacer.color = "#00000000"
    m.container.appendChild(spacer)
    m.nodeCount = m.nodeCount + 1
end sub

sub addHorizontalRule()
    if m.nodeCount >= m.maxNodes then return
    addSpacer(4)
    rule = CreateObject("roSGNode", "Rectangle")
    rule.width = m.top.renderWidth - 80
    rule.height = 2
    rule.color = "#555555"
    rule.translation = [40, 0]
    m.container.appendChild(rule)
    m.nodeCount = m.nodeCount + 1
    addSpacer(4)
end sub

sub addBlockquoteBorder()
    if m.nodeCount >= m.maxNodes then return
    border = CreateObject("roSGNode", "Rectangle")
    border.width = 4
    border.height = 30
    border.color = "#4A90D9"
    border.translation = [30, 0]
    m.container.appendChild(border)
    m.nodeCount = m.nodeCount + 1
end sub

' ============================================================
' Style management
' ============================================================
function getDefaultStyle() as object
    style = {}
    style.font = "font:SmallSystemFont"
    style.color = "#E0E0E0"
    style.bgColor = ""
    style.indent = 0
    style.isLink = false
    style.linkUrl = ""
    return style
end function

function copyStyle(original as object) as object
    copy = {}
    copy.font = original.font
    copy.color = original.color
    copy.bgColor = original.bgColor
    copy.indent = original.indent
    copy.isLink = original.isLink
    copy.linkUrl = original.linkUrl
    return copy
end function

' ============================================================
' HTML attribute extraction
' ============================================================
function extractHref(tagContent as string) as string
    lowerTag = lcase(tagContent)
    hrefPos = instr(1, lowerTag, "href=")
    if hrefPos = 0 then return ""

    quoteChar = mid(tagContent, hrefPos + 5, 1)
    if quoteChar <> chr(34) and quoteChar <> "'"
        ' Unquoted href
        urlStart = hrefPos + 5
        urlEnd = instr(urlStart, tagContent, " ")
        if urlEnd = 0 then urlEnd = instr(urlStart, tagContent, ">")
        if urlEnd = 0 then urlEnd = len(tagContent) + 1
        return mid(tagContent, urlStart, urlEnd - urlStart)
    end if

    urlStart = hrefPos + 6
    urlEnd = instr(urlStart, tagContent, quoteChar)
    if urlEnd = 0 then return ""
    return mid(tagContent, urlStart, urlEnd - urlStart)
end function

' ============================================================
' HTML entity decoding
' ============================================================
function decodeEntities(text as string) as string
    result = text
    result = result.replace("&amp;", "&")
    result = result.replace("&lt;", "<")
    result = result.replace("&gt;", ">")
    result = result.replace("&quot;", chr(34))
    result = result.replace("&apos;", "'")
    result = result.replace("&nbsp;", " ")
    result = result.replace("&#39;", "'")
    result = result.replace("&#x27;", "'")
    result = result.replace("&#x2F;", "/")
    result = result.replace("&mdash;", "—")
    result = result.replace("&ndash;", "–")
    result = result.replace("&laquo;", "«")
    result = result.replace("&raquo;", "»")
    result = result.replace("&copy;", "©")
    result = result.replace("&reg;", "®")
    result = result.replace("&trade;", "™")
    result = result.replace("&hellip;", "…")
    result = result.replace("&bull;", "•")
    result = result.replace("&#8211;", "–")
    result = result.replace("&#8212;", "—")
    result = result.replace("&#8216;", "'")
    result = result.replace("&#8217;", "'")
    result = result.replace("&#8220;", chr(34))
    result = result.replace("&#8221;", chr(34))
    return result
end function

' ============================================================
' Block removal (script, style, etc.)
' ============================================================
function removeBlock(html as string, tagName as string) as string
    result = html
    startTag = "<" + tagName
    endTag = "</" + tagName + ">"

    while true
        startPos = instr(1, lcase(result), startTag)
        if startPos = 0 then exit while

        endPos = instr(startPos, lcase(result), endTag)
        if endPos = 0
            result = left(result, startPos - 1)
            exit while
        end if

        endPos = endPos + len(endTag)
        result = left(result, startPos - 1) + mid(result, endPos)
    end while

    return result
end function
