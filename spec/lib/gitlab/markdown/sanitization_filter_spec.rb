require 'spec_helper'

module Gitlab::Markdown
  describe SanitizationFilter do
    def filter(html, options = {})
      described_class.call(html, options)
    end

    describe 'default whitelist' do
      it 'sanitizes tags that are not whitelisted' do
        act = %q{<textarea>no inputs</textarea> and <blink>no blinks</blink>}
        exp = 'no inputs and no blinks'
        expect(filter(act).to_html).to eq exp
      end

      it 'sanitizes tag attributes' do
        act = %q{<a href="http://example.com/bar.html" onclick="bar">Text</a>}
        exp = %q{<a href="http://example.com/bar.html">Text</a>}
        expect(filter(act).to_html).to eq exp
      end

      it 'sanitizes javascript in attributes' do
        act = %q(<a href="javascript:alert('foo')">Text</a>)
        exp = '<a>Text</a>'
        expect(filter(act).to_html).to eq exp
      end

      it 'allows whitelisted HTML tags from the user' do
        exp = act = "<dl>\n<dt>Term</dt>\n<dd>Definition</dd>\n</dl>"
        expect(filter(act).to_html).to eq exp
      end
    end

    describe 'custom whitelist' do
      it 'allows `class` attribute on any element' do
        exp = act = %q{<strong class="foo">Strong</strong>}
        expect(filter(act).to_html).to eq exp
      end

      it 'allows `id` attribute on any element' do
        exp = act = %q{<em id="foo">Emphasis</em>}
        expect(filter(act).to_html).to eq exp
      end

      it 'allows `style` attribute on table elements' do
        html = <<-HTML.strip_heredoc
        <table>
          <tr><th style="text-align: center">Head</th></tr>
          <tr><td style="text-align: right">Body</th></tr>
        </table>
        HTML

        doc = filter(html)

        expect(doc.at_css('th')['style']).to eq 'text-align: center'
        expect(doc.at_css('td')['style']).to eq 'text-align: right'
      end

      it 'allows `span` elements' do
        exp = act = %q{<span>Hello</span>}
        expect(filter(act).to_html).to eq exp
      end

      it 'removes `rel` attribute from `a` elements' do
        doc = filter(%q{<a href="#" rel="nofollow">Link</a>})

        expect(doc.css('a').size).to eq 1
        expect(doc.at_css('a')['href']).to eq '#'
        expect(doc.at_css('a')['rel']).to be_nil
      end

      it 'removes script-like `href` attribute from `a` elements' do
        html = %q{<a href="javascript:alert('Hi')">Hi</a>}
        doc = filter(html)

        expect(doc.css('a').size).to eq 1
        expect(doc.at_css('a')['href']).to be_nil
      end
    end
  end
end
