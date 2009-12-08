require 'net/http'
require 'iconv'

class InvalidURL < ArgumentError; end

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

run lambda {|env|
  req = Rack::Request.new(env)
  body = if req.params["url"] != "" and !req.params["url"].nil?
    begin
  <<-EOS
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>klp.heroku.com</title>
      </head>
      <body>
        #{KLPPrinter.parse(req.params["url"])}
        
        <div>&copy; by <a href="http://teamon.eu">teamon</a></div>
      </body>
    </html>
  EOS
    rescue ArgumentError
      'Niepoprawny adres. <a href="/">Powrót</a>'
    end
  else
  <<-EOS
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">

    <head profile="http://gmpg.org/xfn/11">
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
      <link rel="shortcut icon" href="http://teamon.eu/files/favicon.png" type="image/png" />
      <title>klp.heroku.com</title>
      <style type="text/css">
      /* @group reset */
      html, body, div, span, applet, object, iframe,
      h1, h2, h3, h4, h5, h6, p, blockquote, pre,
      a, abbr, acronym, address, big, cite, code,
      del, dfn, em, font, img, ins, kbd, q, s, samp,
      small, strike, strong, sub, sup, tt, var,
      b, u, i, center,
      dl, dt, dd, ol, ul, li,
      fieldset, form, label, legend,
      table, caption, tbody, tfoot, thead, tr, th, td {
      	margin: 0;
      	padding: 0;
      	border: 0;
      	outline: 0;
      	font-size: 100%;
      	vertical-align: baseline;
      	background: transparent;
      }
      table {
        border-collapse: collapse;
      }
      td, th {border: 1px solid #ddd; padding: 3px 7px}
      th{ background-color:#eee}
      body {
        background: #454545;
        font-size: 12pt;
        font-family: "Lucida Grande", "Trebuchet MS",Trebuchet,Tahoma,sans-serif;
        color: #4E4E4E;
        padding-top: 50px;
      }

      #main {
        margin: auto;
        width:  700px;
      }

      #entry {
        background: #fff;
        padding: 40px 50px 40px 50px;
        padding-bottom: 20px;
      }
      h2 {
        margin-bottom: 20px;
        height: 30px;color: #E24628;
        font-size: 20px;
        font-weight: normal;
      }
      input.text {
        border: 1px solid #aaa;
        height: 20px;
        font-size: 20px;
        padding: 3px;
        width: 500px;
      }
      p {text-align:center; padding-top: 10px}
      a {color: #E24628}
      #foot {font-size: 10pt;}
      ul {padding-left: 20px;}
      </style>
    </head>

    <body>
      <div id="main">
        <div id="entry">
          <h2>Podaj link do artykułu z klp.pl lub ostatnidzwonek.pl</h2>
          <form method="get" action="">
            <input class="text" type="text" name="url" />
            <input type="submit" value="Połącz" />
          </form>
          <p id="foot">
            &copy; <a href="http://teamon.eu">teamon</a> 2008-#{Time.now.year}
          </p>
        </div>
      </div>
      
      <script type="text/javascript">
      var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
      document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
      </script>
      <script type="text/javascript">
      try {
      var pageTracker = _gat._getTracker("UA-9997784-3");
      pageTracker._trackPageview();
      } catch(err) {}</script>
      
      
    </body>
  </html>
  EOS
  end
  
  
  [200, {'Content-Type'=>'text/html'}, StringIO.new(body)]
}

