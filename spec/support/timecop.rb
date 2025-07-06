require 'timecop'

RSpec.configure do |config|
  # Congelar el tiempo para todas las pruebas
  config.around(:each) do |example|
    # Usar un tiempo fijo para las pruebas
    Timecop.freeze(Time.utc(2023, 1, 1, 12, 0, 0)) do
      example.run
    end
  end
  
  # Método de ayuda para viajar en el tiempo
  def travel_to(time, &block)
    Timecop.travel(time, &block)
  end
  
  # Método de ayuda para congelar el tiempo
  def freeze_time(&block)
    Timecop.freeze(Time.current, &block)
  end
  
  # Método de ayuda para viajar en el tiempo y volver
  def travel(duration, &block)
    Timecop.travel(duration, &block)
  end
end
