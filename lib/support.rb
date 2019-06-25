# Module for methods we're not using right now but did use for Illinois
# TODO incorporate and use whatever is valuable/relevant here
module Support
  def collect_address_data(address_key:, address_hash:, input:)
    key = address_hash["field"]
    address_row = {}
    address = input[address_key]
    postal_code = address.split(//).last(5).join
    postal_code = postal_code.match(/\d{5}/)
    if (postal_code != "")
      address_row["postal_code"] = postal_code
      address = address[0..-7]
    end

    state = address.split(//).last(2).join.upcase
    if STATE_ABBREVIATIONS.include?(state)
      address_row["state_province"] = state
      address = address[0..-5]
    end
    address_row[key] = address

    foreign_key = address_hash["foreign_key_name"]
    foreign_key_value = address_hash["foreign_key_value"]
    address_row[foreign_key] = input[foreign_key_value]
    address_data << address_row
  end

  def process_regular_schedule_text(schedule_key:, schedule_hash:, input:)
    if input["Hours of operation"]
      regex_list = input["Hours of operation"].scan(/\S*day: \S*/)
      for regex in regex_list do
        day = regex.split(': ')[0]
        hours = regex.split(': ')[1]
        if hours == "Closed"
          opens_at = nil
          closes_at = nil
        else
          opens_at = hours.split('-')[0]
          closes_at = hours.split('-')[1]
        end
        collect_schedule_data(schedule_key: schedule_key,
                              schedule_hash: schedule_hash, input: input,
                              day: day, opens_at: opens_at, closes_at: closes_at)
      end
    end
  end

  def collect_schedule_data(schedule_key:, schedule_hash:, input:,
                            day:, opens_at:, closes_at:)
    schedule_row = {}
    schedule_row["weekday"] = day
    schedule_row["opens_at"] = opens_at
    schedule_row["closes_at"] = closes_at

    foreign_key = schedule_hash["foreign_key_name"]
    foreign_key_value = schedule_hash["foreign_key_value"]
    schedule_row[foreign_key] = input[foreign_key_value]
    schedule_data << schedule_row
  end

  def collect_sal_data(sal_key:, sal_hash:, input:)
    key = sal_hash["field"]
    sal_row = {}
    sal_row[key] = input[sal_key]

    foreign_key = sal_hash["foreign_key_name"]
    foreign_key_value = sal_hash["foreign_key_value"]
    sal_row[foreign_key] = input[foreign_key_value]
    sal_data << sal_row
  end

  def validate(filename, type)
    filename = "#{filename}"
    file = File.new(filename, 'rb')
    RestClient.post('http://localhost:1400/validate/csv',
                    {"file" => file,
                     "type" => type})
    return true
  rescue RestClient::BadRequest
    @valid = false
    return false
  end

  def validate_output
    unless validate(output_organizations_path, "organization")
      puts "Organization data not valid"
    end
    unless validate(output_locations_path, "location")
      puts "Location data not valid"
    end
    unless validate(output_services_path, "service")
      puts "Service data not valid"
    end
    unless validate(output_phones_path, "phone")
      puts "Phone data not valid"
    end
  rescue Errno::ECONNREFUSED
    puts "Can't connect to validation service."
  end
end