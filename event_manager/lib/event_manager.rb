require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end


def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
    nil
    if phone.length >= 10
        ph_no = phone.strip.tr('()-. ', '')
         if ph_no.length == 11 &&
            ph_no.start_with?('1')
                ph_no = ph_no.strip.tr('()-. ', '').slice(1..)
         end
         ph_no
    end
end

def calc_hour_stat(hour_stat, date)
    hour_stat[ ((date.split(' ')[1]).split(':')[0]).to_i ] += 1
end

def calc_wday_stat(wday_stat, date)
    wday_stat[Date.strptime( date.split(' ')[0], "%m/%d/%y").wday ] += 1
end

def display_wday_stat(wday_stat)
    DAYS.zip(wday_stat).each do |day, stat|
        puts "#{day}: #{stat}"
    end
end

def display_hour_stat(hour_stat)
    hour_stat.each_with_index do |stat, idx|
        puts "#{idx}-#{(idx+1)%24}: #{stat}"
    end
end

puts "Event Manager Intialized!"

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
)

hour_stat = Array.new(24, 0)
wday_stat = Array.new(7, 0)
DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
    id = row[0]
    name = row[:first_name]

    date = row[:regdate]

    calc_hour_stat(hour_stat, date)
    calc_wday_stat(wday_stat, date)

    phone = clean_phone(row[:homephone])
    unless phone.nil?
      puts "Phone number  #{phone} belongs to #{name}"
    end

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)  

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)

end

display_wday_stat(wday_stat)
display_hour_stat(hour_stat)
