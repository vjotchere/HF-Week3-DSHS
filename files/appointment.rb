class Appointment
  attr_reader :timeblock, :service, :client_name, :serviceProvider
  def initialize(timeblock, service, client_name, serviceProvider) (
    @timeblock = timeblock
    @service = service
    @client_name = client_name
    @serviceProvider = serviceProvider
  )
  end
end