# Roku Browser

A sideloadable Roku channel that lets you browse the web on your Roku device. It fetches web pages via HTTP and renders them with basic HTML styling using dynamically-created SceneGraph nodes — headings, bold, italic, links, lists, blockquotes, code blocks, and horizontal rules are all visually rendered.

## Features

- **URL navigation** — Enter any URL using the on-screen keyboard
- **Web search** — Type a search term and it searches via Google
- **Link extraction** — Clickable links are listed at the bottom of each page
- **Page history** — Navigate back through previously visited pages
- **Bookmarks** — Quick access to popular text-friendly sites
- **Basic HTML rendering** — Renders HTML structure with visual styling:
  - `<h1>`–`<h6>` headings with distinct sizes and weights
  - `<b>`/`<strong>` bold text
  - `<i>`/`<em>` italic text (rendered with distinct color)
  - `<a>` links shown in blue
  - `<ul>`/`<ol>`/`<li>` bulleted lists
  - `<blockquote>` indented blocks with blue left border
  - `<pre>`/`<code>` code blocks with green text and dark background
  - `<hr>` horizontal rule dividers
  - `<table>` basic table layout with separators
  - `<p>`/`<div>`/`<br>` proper spacing and line breaks
- **HTTPS support** — Full SSL/TLS support for secure sites

## Controls

| Button | Action |
|--------|--------|
| **OK** | Open URL/search input keyboard |
| **Up/Down** | Scroll page content |
| **Left** | Go back in history |
| **Rewind (<<)** | Go back in history |
| **Fast Forward (>>)** | Show bookmarks |
| **Play** | Reload current page |
| **Options (\*)** | Show help screen |

### On the Keyboard

| Button | Action |
|--------|--------|
| **D-pad** | Navigate between keys |
| **OK** | Press the selected key |
| **Rewind (<<)** | Backspace / delete |
| **Play** | Submit / Go |
| **Back** | Cancel and close keyboard |

## How to Sideload

### Prerequisites

1. A Roku device on the same Wi-Fi network as your computer
2. Developer mode enabled on your Roku

### Enable Developer Mode on Roku

1. Using your Roku remote, press the following sequence:
   - **Home** 3 times
   - **Up** 2 times
   - **Right** 1 time
   - **Left** 1 time
   - **Right** 1 time
   - **Left** 1 time
   - **Right** 1 time
2. Accept the developer agreement
3. Set a developer password (remember this!)
4. Note your Roku's IP address shown on screen

### Sideload the App

1. Download the `roku-browser.zip` file from this repository
2. Open a web browser on your computer
3. Navigate to `http://<YOUR_ROKU_IP>` (e.g., `http://192.168.1.100`)
4. Log in with:
   - Username: `rokudev`
   - Password: your developer password from step above
5. Click **Upload** and select `roku-browser.zip`
6. Click **Install**
7. The Roku Browser channel will launch automatically!

## Tips

- **Text-only sites work best.** Roku can't render images, CSS, or JavaScript — this browser shows the text content of web pages.
- Try these text-friendly sites:
  - `text.npr.org` — NPR News (text-only)
  - `lite.duckduckgo.com` — DuckDuckGo Lite
  - `en.wikipedia.org` — Wikipedia
  - `news.ycombinator.com` — Hacker News
- Use the **Search** button on the keyboard to quickly search Google
- Type `.com` on the keyboard to quickly append `.com` to a domain

## Limitations

- No image rendering (images are skipped — Roku SceneGraph can't render arbitrary images from URLs)
- No JavaScript execution
- No CSS styling (basic styling is inferred from HTML structure instead)
- No video/audio playback from web pages
- Some websites may block non-browser User-Agent strings
- Complex pages may take longer to process
- Content is displayed as plain text only

## Project Structure

```
roku-browser/
├── manifest              # App metadata and configuration
├── source/
│   └── main.brs          # App entry point
├── components/
│   ├── BrowserScene.xml   # Main UI layout
│   ├── BrowserScene.brs   # Core browser logic (URL handling, HTTP, HTML parsing)
│   ├── HtmlRenderer.xml   # HTML-to-SceneGraph renderer component
│   ├── HtmlRenderer.brs   # HTML tokenizer, parser, and styled node builder
│   ├── KeyboardDialog.xml # On-screen keyboard layout
│   ├── KeyboardDialog.brs # Keyboard input logic
│   ├── ScrollableContent.xml  # Scrollable content host (HTML + plain text modes)
│   └── ScrollableContent.brs  # Content rendering mode switching
└── images/
    ├── icon_focus_hd.png  # Channel icon (focused, HD)
    ├── icon_side_hd.png   # Channel icon (side, HD)
    ├── icon_focus_sd.png  # Channel icon (focused, SD)
    ├── icon_side_sd.png   # Channel icon (side, SD)
    ├── splash_hd.png      # Splash screen (HD)
    └── splash_sd.png      # Splash screen (SD)
```

## Building from Source

To create the sideloadable ZIP from the source files:

```bash
cd roku-browser
zip -r ../roku-browser.zip . -x ".*"
```

Or simply download the pre-built `roku-browser.zip` from the repository.
