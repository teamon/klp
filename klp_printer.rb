module KLPPrinter

  class KLP
    def initialize(url)
      match = url.match(%r[http://(.+).klp.pl/a-(\d+).html])
      raise InvalidURL unless match

      @name = match[1]
      @id = match[2]
      @content = []

      @http = Net::HTTP.new('klp.pl')
    end


    def fetch_page(page)
      resp, body = @http.get "/doda.php?akcja=druk&ida=#{@id}&strona=#{page}"
      Iconv.iconv('utf-8', 'iso-8859-2', body).first
    end

    def parse_content(body)
      body = body[%r[</h1>(.+)strona: &nbsp;&nbsp;]um, 1] || body[%r[</h1>(.+)<a(.+)drukuj]um, 1]
      body.gsub(/\[b\](.+?)\[\/b\]/m, '<strong>\1</strong>').gsub(/\[c\](.+?)\[\/c\]/m, '<blockquote>\1</blockquote>')
    end

    def join
      page = fetch_page(1)
      @title = page[%r[<h1>(.+?)</h1>], 1]
      pages_count = page.scan(%r[<a href=\?akcja=druk&ida=\d+&strona=(\d+)>]u).flatten.map {|e| e.to_i}.max || 1
      @content << parse_content(page)
      if pages_count > 1
        (2..pages_count).each do |p|
          @content << parse_content(fetch_page(p))
        end
      end

      @title + "<br/><br/><p>" + @content.join("</p><p>") + "</p>"
    end
  end

  class OstatniDzwonek
    def initialize(url)            
      match = url.match(%r[http://(.+).ostatnidzwonek.pl/a-(\d+).html])
      raise InvalidURL unless match

      @name = match[1]
      @id = match[2]
      @content = []

      @http = Net::HTTP.new("#{@name}.ostatnidzwonek.pl")
    end


    def fetch_page(page)
      resp, body = @http.get "/a-#{@id}#{page == 1 ? "" : "-#{page}"}.html"
      Iconv.iconv('utf-8', 'iso-8859-2', body).first
    end

    def parse_content(body)
      # puts body
      body = body[%r[</script>.+?</td></tr></table>(.+)strona: &nbsp;&nbsp;]um, 1]
      body.gsub!(%r|<script[^>]*>.*?</script>|um, "")
      body.gsub!(%r|<br>\n(&nbsp;)+<a[^>]*>.+?Reklamy OnetKontekst.+?</a>|um, "")
      body.gsub!(%r|<b>Jeste.*</font>|um, "")
      body.gsub!(%r|<table.width.*\n<tr><td>|um, "")
      body.gsub!(%r|\n.<br><br>|um, "")
      body
    end

    def join
      page = fetch_page(1)
      @title = page[%r[<h1>(.+?)</h1>], 1]
      pages_count = page.scan(%r[<a href=a-\d+-(\d+).html>]u).flatten.map {|e| e.to_i}.max || 1
      @content << parse_content(page)
      if pages_count > 1
        (2..pages_count).each do |p|
          @content << parse_content(fetch_page(p))
        end
      end

      @title + "<br/><br/><p>" + @content.join("</p><p>") + "</p>"
    end
  end

  class << self
    def parse(url)

      parser = case url
      when /klp.pl/ then KLP
      when /ostatnidzwonek.pl/ then OstatniDzwonek
      end

      if parser
        parser.new(url).join
      else
        raise InvalidURL
      end
    end
  end
end
