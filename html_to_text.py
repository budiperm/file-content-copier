#!/usr/bin/env python3
"""
HTML to Plain Text Converter for file-content-copier.

Converts HTML content into clean, readable text.
- Replaces <br>, <br/>, <br /> with newlines (\n) instead of printing tags.
- Preserves paragraph structure for <p>, <div>, and heading tags (<h1> - <h6>).
- Formats lists (<ul>, <ol>, <li>) with bullet points and numbers.
- Retains table formatting (<tr>, <td>, <th>) with tabs.
- Keeps preformatted text (<pre>, <code>) indentation intact.
- Strips <script>, <style>, <head>, <template>, and <svg> blocks completely.
- Decodes HTML entities (&amp;, &lt;, &gt;, &quot;, &#39;, &nbsp;, etc.).
"""

import sys
import os
import re
import html
from html.parser import HTMLParser

class HTMLToGoodText(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.output = []
        self.ignore_stack = []
        self.list_stack = []
        self.pre_count = 0
        self.in_table_cell = False

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        attrs_dict = dict(attrs)

        if tag in {'script', 'style', 'head', 'noscript', 'template', 'svg'}:
            self.ignore_stack.append(tag)
            return

        if self.ignore_stack:
            return

        if tag == 'pre':
            self.pre_count += 1
            self.add_break()
        elif tag == 'br':
            self.output.append('\n')
        elif tag in {'p', 'div', 'blockquote', 'article', 'section', 'header', 'footer', 'nav', 'aside', 'main'}:
            self.add_paragraph_break()
        elif tag in {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}:
            self.add_paragraph_break()
        elif tag == 'hr':
            self.add_paragraph_break()
            self.output.append('---')
            self.add_paragraph_break()
        elif tag in {'ul', 'ol'}:
            start = 1
            if tag == 'ol' and 'start' in attrs_dict:
                try:
                    start = int(attrs_dict['start'])
                except ValueError:
                    start = 1
            self.list_stack.append((tag, start))
            self.add_break()
        elif tag == 'li':
            self.add_break()
            indent = '  ' * max(0, len(self.list_stack) - 1)
            if self.list_stack:
                list_type, count = self.list_stack[-1]
                if list_type == 'ol':
                    self.output.append(f'{indent}{count}. ')
                    self.list_stack[-1] = (list_type, count + 1)
                else:
                    self.output.append(f'{indent}• ')
            else:
                self.output.append('• ')
        elif tag == 'tr':
            self.add_break()
            self.in_table_cell = False
        elif tag in {'td', 'th'}:
            if self.in_table_cell:
                self.output.append('\t')
            self.in_table_cell = True

    def handle_endtag(self, tag):
        tag = tag.lower()
        if self.ignore_stack:
            if self.ignore_stack[-1] == tag:
                self.ignore_stack.pop()
            return

        if tag == 'pre':
            self.pre_count = max(0, self.pre_count - 1)
            self.add_break()
        elif tag in {'p', 'div', 'blockquote', 'article', 'section', 'header', 'footer', 'nav', 'aside', 'main'}:
            self.add_paragraph_break()
        elif tag in {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}:
            self.add_paragraph_break()
        elif tag in {'ul', 'ol'}:
            if self.list_stack:
                self.list_stack.pop()
            self.add_break()
        elif tag == 'tr':
            self.in_table_cell = False
            self.add_break()

    def handle_data(self, data):
        if self.ignore_stack:
            return

        if self.pre_count > 0:
            self.output.append(data)
        else:
            cleaned = data.replace('\xa0', ' ')
            collapsed = re.sub(r'[ \t\r\n]+', ' ', cleaned)
            if collapsed.strip():
                if data[0].isspace() and self.output and not self.output[-1].endswith((' ', '\n', '\t', '• ')):
                    self.output.append(' ')
                self.output.append(collapsed.strip())
                if data[-1].isspace():
                    self.output.append(' ')
            elif data and data.isspace():
                if self.output and not self.output[-1].endswith((' ', '\n', '\t')):
                    self.output.append(' ')

    def add_break(self):
        if self.output and not self.output[-1].endswith('\n'):
            self.output.append('\n')

    def add_paragraph_break(self):
        if not self.output:
            return
        joined = ''.join(self.output[-2:]) if len(self.output) >= 2 else self.output[-1]
        if joined.endswith('\n\n'):
            return
        elif joined.endswith('\n'):
            self.output.append('\n')
        else:
            self.output.append('\n\n')

def convert_html_to_text(html_text: str) -> str:
    """Convert HTML string into clean plain text."""
    parser = HTMLToGoodText()
    parser.feed(html_text)
    parser.close()
    raw = ''.join(parser.output)
    # Ensure any remaining HTML entities are unescaped
    raw = html.unescape(raw)

    lines = [line.rstrip() for line in raw.split('\n')]
    result = []
    blank_count = 0
    for line in lines:
        if not line.strip():
            blank_count += 1
            if blank_count <= 1:
                result.append('')
        else:
            blank_count = 0
            result.append(line)

    return '\n'.join(result).strip()

def has_html_tags(text: str) -> bool:
    """Check if the text contains recognizable HTML tags or entities."""
    pattern = re.compile(r'''(?ix)
        <!DOCTYPE\s+html|
        <br\s*\/?>|<br\b[^>]*>|
        <hr\s*\/?>|<hr\b[^>]*>|
        <\/?(?:html|head|body|title|script|style|p|div|span|h[1-6]|ul|ol|li|table|thead|tbody|tfoot|tr|td|th|blockquote|pre|code|article|section|header|footer|nav|aside|button|input|form|select|option|label)\b|
        <\/(?:b|i|u|s|strong|em|a|strike|font|mark|small|sub|sup)>|
        <(?:b|i|u|s|strong|em|a)\s+[^>]*>|
        &[a-zA-Z]{2,8};|&#\d{1,6};|&#x[0-9a-fA-F]{1,6};
    ''')
    return bool(pattern.search(text))

def is_html_extension(filepath: str) -> bool:
    """Check if file extension indicates HTML."""
    _, ext = os.path.splitext(filepath)
    return ext.lower() in {'.html', '.htm', '.xhtml'}

def is_source_code_extension(filepath: str) -> bool:
    """Check if file extension indicates source code where raw text should be preserved."""
    _, ext = os.path.splitext(filepath)
    return ext.lower() in {
        '.py', '.sh', '.bash', '.zsh', '.lua', '.c', '.cpp', '.cc', '.h', '.hpp',
        '.rs', '.go', '.java', '.kt', '.swift', '.ts', '.js', '.json', '.yaml',
        '.yml', '.toml', '.sql', '.css', '.scss', '.sass', '.less', '.ini', '.conf'
    }

def process_file_or_text(filepath: str = None, raw_mode: bool = False, force_html: bool = False) -> tuple[str, bool]:
    """
    Process file or stdin and return (content, was_converted_from_html).
    """
    if filepath and filepath != '-':
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    else:
        content = sys.stdin.read()

    if raw_mode:
        return content, False

    should_convert = False
    if force_html:
        should_convert = True
    elif filepath and is_html_extension(filepath):
        should_convert = True
    elif filepath and is_source_code_extension(filepath):
        should_convert = False
    else:
        # Check if content has HTML tags
        should_convert = has_html_tags(content)

    if should_convert:
        return convert_html_to_text(content), True
    return content, False

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Convert HTML content into clean readable plain text.')
    parser.add_argument('file', nargs='?', default='-', help='Input file path (default: stdin)')
    parser.add_argument('-r', '--raw', action='store_true', help='Force raw output (no HTML parsing)')
    parser.add_argument('-t', '--html', action='store_true', help='Force HTML conversion')
    parser.add_argument('--check-html', action='store_true', help='Exit 0 if content has HTML tags, 1 otherwise')

    args = parser.parse_args()

    if args.check_html:
        filepath = None if args.file == '-' else args.file
        if filepath:
            with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            is_html = is_html_extension(filepath) or has_html_tags(content)
        else:
            content = sys.stdin.read()
            is_html = has_html_tags(content)
        sys.exit(0 if is_html else 1)

    filepath = None if args.file == '-' else args.file
    result, _ = process_file_or_text(filepath, raw_mode=args.raw, force_html=args.html)
    print(result)

if __name__ == '__main__':
    main()
