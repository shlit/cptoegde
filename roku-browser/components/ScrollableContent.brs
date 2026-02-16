sub init()
    m.pageContent = m.top.findNode("pageContent")
    m.contentLayout = m.top.findNode("contentLayout")
    m.htmlRenderer = m.top.findNode("htmlRenderer")
    m.linkHighlight = m.top.findNode("linkHighlight")
end sub

sub onContentChanged()
    ' Plain text mode - used as fallback
    m.pageContent.text = m.top.contentText
    m.contentLayout.visible = true
    m.htmlRenderer.visible = false
    m.top.selectedLinkIndex = -1
    if m.linkHighlight <> invalid
        m.linkHighlight.visible = false
    end if
end sub

sub onHtmlContentChanged()
    ' HTML rendering mode
    m.htmlRenderer.htmlContent = m.top.htmlContent
    m.htmlRenderer.visible = true
    m.contentLayout.visible = false
    m.top.selectedLinkIndex = -1
    if m.linkHighlight <> invalid
        m.linkHighlight.visible = false
    end if

    ' Collect rendered links
    if m.htmlRenderer <> invalid and m.htmlRenderer.renderedLinks <> invalid
        m.top.links = m.htmlRenderer.renderedLinks
    end if
end sub
