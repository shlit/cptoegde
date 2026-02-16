sub init()
    m.pageContent = m.top.findNode("pageContent")
    m.linkHighlight = m.top.findNode("linkHighlight")
end sub

sub onContentChanged()
    m.pageContent.text = m.top.contentText
    m.top.selectedLinkIndex = -1
    if m.linkHighlight <> invalid
        m.linkHighlight.visible = false
    end if
end sub
