
require_relative './files/service'
require_relative './files/serviceProvider'
require_relative './files/appointment'
require_relative './files/timeblock'
require_relative './print'
require_relative './seeder/init'
require_relative './lib/colors'
require_relative './files/availability'
require 'tty-prompt'
$prompt = TTY::Prompt.new

def find_sp_by_service(serviceName)
  sp_with_service = []
  for sp in $all_sp do
    for s in sp.services do
      if s.name == serviceName
        sp_with_service.push(sp)
        break
      end
    end
  end
  return sp_with_service
end

def get_sp_by_name(name)
  sp = $all_sp.select do |sp| 
    sp.name == name
  end
  if sp.length == 1
    return sp.first
  else
    return false
  end
end

def select_sp
  sp_names = []
  $all_sp.each do |sp|
    sp_names << sp.name
  end
  get_sp_by_name($prompt.select("#{BgMagenta}Service Provider:#{Reset}", sp_names, cycle: true))
end

def serviceAdd
  service_name = $prompt.ask('Service Name:')
  service_price = $prompt.ask('Service Price:')
  service_length = $prompt.ask('Service Length (Mins):')
  loop do
    sp = select_sp()
    if sp
      sp.serviceAdd(Service.new(service_name, service_price, service_length))
      successPrint()
      break
    else
      serviceErrorMessage()
    end
  end
end

def serviceRemove
  puts "Choose Service to Remove"
  servicePrint($all_sp)
  sp = select_sp()
  service_hash = {}
  sp.services.each do |s|
    key = s.getDetails
    service_hash[key] = s
  end
  if sp.services.length == 0
    puts "No services found for service provider (#{Magenta}#{provider_name}#{Reset})."
  else
    loop do
      service_keys = service_hash.keys
      serv_to_be_deleted = $prompt.select("Choose Service to remove", service_keys, cycle: true)
      sp.services.delete(service_hash[serv_to_be_deleted])
      successPrint()
      break
    end
  end
end

def spAdd
  provider_name = $prompt.ask('Provider Name:')
  provider_phone = $prompt.ask('Provider Phone Number:')
  $all_sp.push(ServiceProvider.new(provider_name, provider_phone, [], {}, []))
  successPrint()
end

def spRemove
  puts 'Provider Name To Remove:'
  sp = select_sp()
  confirm = y_or_n()
  if confirm
    $all_sp.delete(sp)
    successPrint()
  else
    puts 'Did Not Delete'
  end
end

def y_or_n
  loop do
    yn = $prompt.ask('(y/n):')
    if yn == 'y'
      return true
    elsif yn == 'n'
      return false
    else
      puts "Enter y or n"
    end
  end
end

def appointmentAdd
  client_name = $prompt.ask('Client Name:')
  puts "Hello #{client_name}! Choose Provider & Service to Schedule"
  servicePrint($all_sp)
  puts 'Provider Name:'
  sp = select_sp()
  serv_names = []
  sp.services.each do |serv|
    serv_names << serv.name
  end
  service_name = $prompt.select("#{BgMagenta}Service Name:#{Reset}", serv_names, cycle: true)
  # check here for usability
  is_available = false
  while !is_available
    month = $prompt.ask('Date (MM):')
    day = $prompt.ask('Date (DD):')
    year = $prompt.ask('Date (YYYY):')
    start_time = $prompt.ask('Start Time (ex: 13:30):')
    temp = start_time.split(':')
    hour = temp[0].to_i
    minute = temp[1].to_i
    puts 'Will This Appointment Reoccur Weekly?'
    isWeekly = y_or_n()
    service = sp.containsService(service_name)

    start_datetime = DateTime.new(year.to_i, month.to_i, day.to_i, hour, minute)
    if sp.add_appointment(service, TimeBlock.new(start_datetime, isWeekly, service.length), client_name)
      is_available = true
    end
  end
end

def appointmentRemove
  spPrint($all_sp)
  puts 'Provider Name To Cancel Appt:'
  sp = select_sp()
  client_name = $prompt.ask('Your Name:')
  appointment_hash = {}
  i = 1;
  sp.appointments.each do |a|
    if a.client_name == client_name
      key = a.getDetails
      appointment_hash[key] = a
      i += 1
    end
  end
  if i == 1
    puts "No appointments found for client (#{Cyan}#{client_name}#{Reset}) under service provider (#{Magenta}#{sp.name}#{Reset})."
  else
    loop do
      appointment_keys = appointment_hash.keys
      a_to_be_deleted = $prompt.select("Choose Appointment to remove", appointment_keys, cycle: true)
      sp.appointments.delete(appointment_hash[a_to_be_deleted])
      successPrint()
      break
    end
  end
end

def availabilityAdd
  spPrint($all_sp)
  puts 'Provider Name:'
  sp = select_sp()
  month = $prompt.ask('Date (MM):')
  day = $prompt.ask('Date (DD):')
  year = $prompt.ask('Date (YYYY):')
  start_time = $prompt.ask('Start Time (ex: 13:30):')
  end_time = $prompt.ask('End Time (ex: 14:30):')
  puts 'Will This Availability Reoccur Weekly?'
  isWeekly = y_or_n()

  start_temp = start_time.split(':')
  start_hour = start_temp[0].to_i
  start_minute = start_temp[1].to_i

  end_temp = end_time.split(':')
  end_hour = end_temp[0].to_i
  end_minute = end_temp[1].to_i

  length = (end_hour * 60 +end_minute) - (start_hour * 60 + start_minute)

  start_datetime = DateTime.new(year.to_i, month.to_i, day.to_i, start_hour, start_minute)
  timeblock = TimeBlock.new(start_datetime, isWeekly, length)

  #sp.add_appointment(service, TimeBlock.new(month, day, year, start_datetime, isWeekly, service.length), client_name)
  sp.add_availability(timeblock)
  successPrint()
end

def availabilityRemove
  puts 'Provider Name To Remove Availability:'
  sp = select_sp()
  availability_hash = {}
  sp.availability.each do |av|
    key = av.getDetails
    availability_hash[key] = av
  end
  if sp.availability.length == 0
    puts "No availability found for service provider (#{Magenta}#{provider_name}#{Reset})."
  else
    loop do
      availability_keys = availability_hash.keys
      av_to_be_deleted = $prompt.select("Choose Availability to remove", availability_keys, cycle: true)
      sp.availability.delete(availability_hash[av_to_be_deleted])
      successPrint()
      break
    end
  end
end

def scheduleView(type)
  loop do
    puts "Choose a Service Provider to see their schedule:"
    sp = select_sp()
    if type == 'appt'
      sp.scheduleView()
      break
    elsif type == 'avail'
      sp.availabilityView()
      break
    end
  end
end

def list_commands
  puts "#{BgCyan}COMMAND LIST:#{Reset}"
  puts "--------------------------------"
  puts "#{Cyan}commands#{Reset} | View this list of commands"
  puts "#{Cyan}s:add#{Reset} | Add service"
  puts "#{Cyan}s:remove#{Reset} | Remove service"
  puts "#{Cyan}s:view#{Reset} | Display all services"
  puts "#{Cyan}sp:add#{Reset} | Add service provider"
  puts "#{Cyan}sp:remove#{Reset} | Remove service provider"
  puts "#{Cyan}sp:view#{Reset} | Display all service providers"
  puts "#{Cyan}appt:add#{Reset} | Add new appointment"
  puts "#{Cyan}appt:remove#{Reset} | Remove appointment"
  puts "#{Cyan}avail:add#{Reset} | Add new availability block"
  puts "#{Cyan}avail:remove#{Reset} | Remove availability block"
  puts "#{Cyan}schedule:view#{Reset} | View schedule"
  puts "--------------------------------"
end

commands = {
  'Add service' => Proc.new{serviceAdd},
  'Remove service' => Proc.new{serviceRemove},
  'View services' => Proc.new{servicePrint($all_sp)},
  'Add service provider' => Proc.new{spAdd},
  'Remove service provider' => Proc.new{spRemove},
  'View service providers' => Proc.new{spPrint($all_sp)},
  'Add appointments' => Proc.new{appointmentAdd},
  'Remove appointments' => Proc.new{appointmentRemove},
  'Add availability' => Proc.new{availabilityAdd},
  'Remove availability' => Proc.new{availabilityRemove},
  'View availability' => Proc.new{scheduleView('avail')},
  'View schedule' => Proc.new{scheduleView('appt')},
  'View Commands' => Proc.new{list_commands()},
  'Exit program' => 0
}

# INITIALIZE
$all_sp = initData

user_is_done = false
while !user_is_done
  user_task = $prompt.select("What would you like to do?", commands.keys, cycle: true)
  if user_task != 'Exit program'
    commands[user_task].call()
  else
    user_is_done = true
  end
end



