require 'mechanize'

unless ARGV.length >= 2
  puts "Wrong number of arguments. Recieved #{ARGV.length}, but expected 2 or 3: \n'http://meetup.com/{group-name}/members' and 'ouput-file.txt', optionally '--silent' to suppress console output"
  exit
end

base_url = ARGV[0].strip.match(/(.*\/members)/)[1]
filename = ARGV[1]
silent = (ARGV[2] == '--silent')
group_name = base_url.match(/.com\/(.+)\/members/)[1]

agent = Mechanize.new
agent.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1944.0 Safari/537.36'
agent.history_added = Proc.new {sleep 1}

puts "Started scraping #{group_name}"
html = agent.get base_url
last_offset = html.at('.nav-next').get_attribute('href').match(/offset=(\d+)&/)[1]
total_pages = last_offset.to_i/20 + 1
puts "Expecting #{total_pages} pages of users"

File.open(filename, 'w') do |f|
  (0..last_offset.to_i).step(20) do |offset|
    url = base_url + "/?offset=#{offset}"
    html = agent.get(url)
    mems = html.search('.memName').map { |e| e.get_attribute('href') }
    puts "Scraping page #{offset/20+1} of #{total_pages}" unless silent

    mems.each do |mem_url|
      print '.' unless silent
      html = agent.get mem_url
      twitter = agent.page.at('[href^="http://twitter.com"]')
      begin
        f.puts twitter.get_attribute('href').strip.match(/\.com\/(?:#!\/)?([^\/]+)\/?$/)[1] if twitter
      rescue
        puts 'k, we have an error'
      end
    end
    print "\n" unless silent
  end
end

puts "Done scraping #{group_name}"
