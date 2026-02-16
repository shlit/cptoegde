sub init()
    m.urlDisplay = m.top.findNode("urlDisplay")
    m.statusLabel = m.top.findNode("statusLabel")
    m.contentArea = m.top.findNode("contentArea")
    m.keyboardDialog = m.top.findNode("keyboardDialog")
    m.loadingOverlay = m.top.findNode("loadingOverlay")
    m.helpOverlay = m.top.findNode("helpOverlay")
    m.focusIndicator = m.top.findNode("focusIndicator")
    m.urlBarBg = m.top.findNode("urlBarBg")

    m.history = []
    m.historyIndex = -1
    m.currentUrl = ""
    m.scrollPosition = 0
    m.showingHelp = false
    m.showingKeyboard = false
    m.bookmarks = []
    m.currentLinks = []
    m.selectedLinkIndex = 0
    m.pendingLinkUrl = ""

    ' Default bookmarks
    m.bookmarks.push("https://www.google.com")
    m.bookmarks.push("https://en.wikipedia.org")
    m.bookmarks.push("https://news.ycombinator.com")
    m.bookmarks.push("https://lite.duckduckgo.com/lite/")
    m.bookmarks.push("https://text.npr.org")

    m.keyboardDialog.observeField("submitted", "onKeyboardSubmit")
    m.keyboardDialog.observeField("cancelled", "onKeyboardCancel")

    m.top.setFocus(true)
    setStatus("Ready - Press OK to enter a URL or search term")
end sub

sub setStatus(text as string)
    m.statusLabel.text = text
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' Help overlay dismissal
    if m.showingHelp
        m.helpOverlay.visible = false
        m.showingHelp = false
        return true
    end if

    ' Keyboard dialog is showing
    if m.showingKeyboard
        return false ' let keyboard handle it
    end if

    if key = "OK"
        if m.pendingLinkUrl <> ""
            url = m.pendingLinkUrl
            m.pendingLinkUrl = ""
            navigateTo(url)
        else
            showKeyboard()
        end if
        return true
    else if key = "up"
        scrollContent(-80)
        return true
    else if key = "down"
        scrollContent(80)
        return true
    else if key = "left"
        goBack()
        return true
    else if key = "right"
        followNextLink()
        return true
    else if key = "rewind"
        goBack()
        return true
    else if key = "fastforward"
        showBookmarks()
        return true
    else if key = "play"
        reloadPage()
        return true
    else if key = "options"
        showHelp()
        return true
    end if

    return false
end function

sub showKeyboard()
    m.showingKeyboard = true
    if m.currentUrl <> ""
        m.keyboardDialog.inputText = m.currentUrl
    else
        m.keyboardDialog.inputText = ""
    end if
    m.keyboardDialog.visible = true
    m.keyboardDialog.setFocus(true)
end sub

sub onKeyboardSubmit()
    input = m.keyboardDialog.inputText
    m.keyboardDialog.visible = false
    m.showingKeyboard = false
    m.top.setFocus(true)

    if input <> ""
        navigateTo(input)
    end if
end sub

sub onKeyboardCancel()
    m.keyboardDialog.visible = false
    m.showingKeyboard = false
    m.top.setFocus(true)
end sub

sub navigateTo(input as string)
    url = normalizeUrl(input)
    m.currentUrl = url
    m.urlDisplay.text = url
    m.urlDisplay.color = "#333333"

    ' Add to history
    if m.historyIndex < m.history.count() - 1
        ' Trim forward history
        newHistory = []
        for i = 0 to m.historyIndex
            newHistory.push(m.history[i])
        end for
        m.history = newHistory
    end if
    m.history.push(url)
    m.historyIndex = m.history.count() - 1

    fetchPage(url)
end sub

function normalizeUrl(input as string) as string
    trimmed = input.trim()

    ' If it looks like a URL
    if instr(1, trimmed, ".") > 0 and instr(1, trimmed, " ") = 0
        if left(trimmed, 7) <> "http://" and left(trimmed, 8) <> "https://"
            return "https://" + trimmed
        end if
        return trimmed
    end if

    ' Otherwise treat as a search query
    searchQuery = trimmed
    ' URL encode spaces
    searchQuery = replaceAll(searchQuery, " ", "+")
    return "https://www.google.com/search?q=" + searchQuery
end function

sub fetchPage(url as string)
    setStatus("Loading: " + url)
    m.loadingOverlay.visible = true
    m.scrollPosition = 0

    ' Create URL transfer object for HTTP request
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("User-Agent", "Mozilla/5.0 (Roku; BrightScript) RokuBrowser/1.0")
    request.InitClientCertificates()
    request.SetUrl(url)
    request.EnableFreshConnection(true)

    ' Use async transfer with port
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)

    if request.AsyncGetToString()
        msg = wait(30000, port)
        if msg <> invalid
            responseCode = msg.GetResponseCode()
            if responseCode = 200
                body = msg.GetString()
                processHtml(body, url)
                setStatus("Loaded: " + url)
            else if responseCode >= 300 and responseCode < 400
                ' Handle redirects
                headers = msg.GetResponseHeaders()
                if headers <> invalid and headers.DoesExist("location")
                    redirectUrl = headers["location"]
                    if left(redirectUrl, 1) = "/"
                        ' Relative redirect
                        baseUrl = getBaseUrl(url)
                        redirectUrl = baseUrl + redirectUrl
                    end if
                    setStatus("Redirecting to: " + redirectUrl)
                    fetchPage(redirectUrl)
                    return
                else
                    showError("Redirect with no location (HTTP " + str(responseCode) + ")")
                end if
            else
                showError("HTTP Error: " + str(responseCode))
            end if
        else
            showError("Request timed out")
        end if
    else
        showError("Failed to send request")
    end if

    m.loadingOverlay.visible = false
end sub

function getBaseUrl(url as string) as string
    ' Extract protocol + domain from URL
    if left(url, 8) = "https://"
        rest = mid(url, 9)
        slashPos = instr(1, rest, "/")
        if slashPos > 0
            return "https://" + left(rest, slashPos - 1)
        end if
        return url
    else if left(url, 7) = "http://"
        rest = mid(url, 8)
        slashPos = instr(1, rest, "/")
        if slashPos > 0
            return "http://" + left(rest, slashPos - 1)
        end if
        return url
    end if
    return url
end function

sub processHtml(html as string, baseUrl as string)
    ' Extract title
    titleStart = instr(1, lcase(html), "<title")
    if titleStart > 0
        titleTagEnd = instr(titleStart, html, ">")
        titleEnd = instr(titleStart, lcase(html), "</title>")
        if titleTagEnd > 0 and titleEnd > 0
            pageTitle = mid(html, titleTagEnd + 1, titleEnd - titleTagEnd - 1)
            pageTitle = pageTitle.trim()
            setStatus(pageTitle + " - " + m.currentUrl)
        end if
    end if

    ' Resolve relative URLs in the HTML before rendering
    resolvedHtml = resolveRelativeUrls(html, baseUrl)

    ' Extract links from the page (for link-following feature)
    links = extractLinks(html, baseUrl)
    m.currentLinks = links
    m.selectedLinkIndex = 0

    ' Send raw HTML to the styled renderer
    m.contentArea.htmlContent = resolvedHtml
    m.contentArea.translation = [0, 115]

    ' Also collect links from the renderer
    if m.contentArea.links <> invalid
        renderedLinks = m.contentArea.links
        ' Merge any renderer-discovered links into our link list
        if type(renderedLinks) = "roArray"
            for each rLink in renderedLinks
                if rLink.url <> "" and rLink.text <> ""
                    found = false
                    for each eLink in m.currentLinks
                        if eLink.url = rLink.url
                            found = true
                            exit for
                        end if
                    end for
                    if not found
                        m.currentLinks.push(rLink)
                    end if
                end if
            end for
        end if
    end if
end sub

function resolveRelativeUrls(html as string, baseUrl as string) as string
    ' Resolve relative href URLs to absolute
    result = html
    base = getBaseUrl(baseUrl)

    ' Replace href="/ with href="base/
    result = replaceAll(result, "href=" + chr(34) + "/", "href=" + chr(34) + base + "/")
    result = replaceAll(result, "href='/", "href='" + base + "/")

    return result
end function

function stripHtml(html as string) as string
    ' Remove script and style blocks first
    result = removeTagBlock(html, "script")
    result = removeTagBlock(result, "style")
    result = removeTagBlock(result, "noscript")
    result = removeTagBlock(result, "head")

    ' Replace common block-level tags with newlines
    blockTags = ["</p>", "</div>", "</li>", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "<br>", "<br/>", "<br />", "</tr>", "</td>", "</th>"]
    for each tag in blockTags
        result = replaceAll(lcase(result), tag, chr(10))
    end for

    ' Replace list items with bullet points
    result = replaceAll(lcase(result), "<li", chr(10) + chr(8226) + " <li")

    ' Strip remaining HTML tags
    output = ""
    inTag = false
    for i = 0 to len(result) - 1
        ch = mid(result, i + 1, 1)
        if ch = "<"
            inTag = true
        else if ch = ">"
            inTag = false
        else if not inTag
            output = output + ch
        end if
    end for

    ' Decode common HTML entities
    output = replaceAll(output, "&amp;", "&")
    output = replaceAll(output, "&lt;", "<")
    output = replaceAll(output, "&gt;", ">")
    output = replaceAll(output, "&quot;", chr(34))
    output = replaceAll(output, "&apos;", "'")
    output = replaceAll(output, "&nbsp;", " ")
    output = replaceAll(output, "&#39;", "'")
    output = replaceAll(output, "&#x27;", "'")
    output = replaceAll(output, "&#x2F;", "/")

    ' Clean up excessive whitespace
    while instr(1, output, chr(10) + chr(10) + chr(10)) > 0
        output = replaceAll(output, chr(10) + chr(10) + chr(10), chr(10) + chr(10))
    end while

    output = output.trim()
    return output
end function

function removeTagBlock(html as string, tagName as string) as string
    result = html
    lowerResult = lcase(result)
    startTag = "<" + tagName
    endTag = "</" + tagName + ">"

    while true
        startPos = instr(1, lcase(result), startTag)
        if startPos = 0 then exit while

        endPos = instr(startPos, lcase(result), endTag)
        if endPos = 0
            ' No closing tag found, remove to end
            result = left(result, startPos - 1)
            exit while
        end if

        endPos = endPos + len(endTag)
        result = left(result, startPos - 1) + mid(result, endPos)
    end while

    return result
end function

function extractLinks(html as string, baseUrl as string) as object
    links = []
    lowerHtml = lcase(html)
    searchPos = 1

    while true
        aPos = instr(searchPos, lowerHtml, "<a ")
        if aPos = 0 then aPos = instr(searchPos, lowerHtml, "<a" + chr(10))
        if aPos = 0 then exit while

        linkParsed = parseSingleLink(html, lowerHtml, aPos, baseUrl)
        if linkParsed <> invalid
            links.push(linkParsed.link)
            searchPos = linkParsed.nextPos
        else
            searchPos = aPos + 3
        end if
    end while

    return links
end function

function parseSingleLink(html as string, lowerHtml as string, aPos as integer, baseUrl as string) as object
    ' Find href attribute
    hrefPos = instr(aPos, lowerHtml, "href=" + chr(34))
    if hrefPos = 0 then hrefPos = instr(aPos, lowerHtml, "href='")
    if hrefPos = 0 then return invalid

    ' Make sure this href belongs to this <a> tag
    nextTagClose = instr(aPos, html, ">")
    if hrefPos > nextTagClose then return invalid

    ' Extract URL
    quoteChar = mid(html, hrefPos + 5, 1)
    urlStart = hrefPos + 6
    urlEnd = instr(urlStart, html, quoteChar)
    if urlEnd = 0 then return invalid

    linkUrl = mid(html, urlStart, urlEnd - urlStart)

    ' Get link text
    tagClose = instr(aPos, html, ">")
    aEndPos = instr(tagClose, lowerHtml, "</a>")
    if aEndPos = 0
        linkText = linkUrl
    else
        linkText = mid(html, tagClose + 1, aEndPos - tagClose - 1)
        ' Strip any inner HTML tags from link text
        cleanText = ""
        inInnerTag = false
        for ci = 0 to len(linkText) - 1
            c = mid(linkText, ci + 1, 1)
            if c = "<"
                inInnerTag = true
            else if c = ">"
                inInnerTag = false
            else if not inInnerTag
                cleanText = cleanText + c
            end if
        end for
        linkText = cleanText.trim()
    end if

    ' Resolve relative URLs
    if left(linkUrl, 1) = "/"
        linkUrl = getBaseUrl(baseUrl) + linkUrl
    else if left(linkUrl, 1) = "#" or left(linkUrl, 11) = "javascript:"
        return invalid
    else if left(linkUrl, 4) <> "http"
        linkUrl = getBaseUrl(baseUrl) + "/" + linkUrl
    end if

    if linkText = "" or len(linkText) >= 200 then return invalid

    result = {}
    link = {}
    link.url = linkUrl
    link.text = linkText
    result.link = link
    result.nextPos = urlEnd + 1
    return result
end function

function replaceAll(source as string, search as string, replacement as string) as string
    result = source
    pos = instr(1, result, search)
    while pos > 0
        result = left(result, pos - 1) + replacement + mid(result, pos + len(search))
        pos = instr(pos + len(replacement), result, search)
    end while
    return result
end function

sub scrollContent(amount as integer)
    m.scrollPosition = m.scrollPosition + amount
    if m.scrollPosition < 0 then m.scrollPosition = 0
    m.contentArea.translation = [0, 115 - m.scrollPosition]
end sub

sub goBack()
    if m.historyIndex > 0
        m.historyIndex = m.historyIndex - 1
        m.currentUrl = m.history[m.historyIndex]
        m.urlDisplay.text = m.currentUrl
        m.urlDisplay.color = "#333333"
        fetchPage(m.currentUrl)
    else
        setStatus("No more history")
    end if
end sub

sub reloadPage()
    if m.currentUrl <> ""
        fetchPage(m.currentUrl)
    end if
end sub

sub showBookmarks()
    text = "=== BOOKMARKS ===" + chr(10) + chr(10)
    text = text + "Press OK to enter a URL or search term." + chr(10)
    text = text + "Press the Back button to return to browsing." + chr(10) + chr(10)
    text = text + "--- Saved Bookmarks ---" + chr(10) + chr(10)
    for i = 0 to m.bookmarks.count() - 1
        text = text + "[" + str(i + 1).trim() + "] " + m.bookmarks[i] + chr(10)
    end for
    text = text + chr(10)
    text = text + "--- Quick Links ---" + chr(10) + chr(10)
    text = text + chr(8226) + " google.com - Web search" + chr(10)
    text = text + chr(8226) + " wikipedia.org - Encyclopedia" + chr(10)
    text = text + chr(8226) + " news.ycombinator.com - Tech news" + chr(10)
    text = text + chr(8226) + " lite.duckduckgo.com - Private search" + chr(10)
    text = text + chr(8226) + " text.npr.org - News (text-only)" + chr(10)
    text = text + chr(10)
    text = text + "Tip: Text-only or 'lite' versions of websites" + chr(10)
    text = text + "work best with this browser." + chr(10)

    m.contentArea.contentText = text
    m.contentArea.translation = [0, 115]
    m.scrollPosition = 0
    setStatus("Bookmarks")
end sub

sub showHelp()
    m.helpOverlay.visible = true
    m.showingHelp = true
end sub

sub showError(message as string)
    errorText = "=== Error ===" + chr(10) + chr(10)
    errorText = errorText + message + chr(10) + chr(10)
    errorText = errorText + "Possible causes:" + chr(10)
    errorText = errorText + chr(8226) + " The website may not be accessible" + chr(10)
    errorText = errorText + chr(8226) + " Check your Roku's internet connection" + chr(10)
    errorText = errorText + chr(8226) + " The URL might be incorrect" + chr(10)
    errorText = errorText + chr(8226) + " The site may block non-browser requests" + chr(10) + chr(10)
    errorText = errorText + "Tips:" + chr(10)
    errorText = errorText + chr(8226) + " Try text-only versions of websites" + chr(10)
    errorText = errorText + chr(8226) + " Use lite.duckduckgo.com for searching" + chr(10)
    errorText = errorText + chr(8226) + " Press OK to enter a new URL" + chr(10)

    m.contentArea.contentText = errorText
    setStatus("Error - " + message)
end sub

sub followNextLink()
    if m.currentLinks = invalid or m.currentLinks.count() = 0
        setStatus("No links on this page")
        return
    end if

    ' Cycle through available links
    if m.selectedLinkIndex >= m.currentLinks.count()
        m.selectedLinkIndex = 0
    end if

    link = m.currentLinks[m.selectedLinkIndex]
    setStatus("Link [" + str(m.selectedLinkIndex + 1).trim() + "/" + str(m.currentLinks.count()).trim() + "]: " + link.text + " - Press OK to follow, Right for next")

    m.selectedLinkIndex = m.selectedLinkIndex + 1
    m.pendingLinkUrl = link.url
end sub
