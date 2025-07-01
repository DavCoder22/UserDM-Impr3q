FROM ruby:3.2.2-slim

# Instala dependencias del sistema
RUN apt-get update && \
    apt-get install -y build-essential libpq-dev libsqlite3-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Copia solo el Gemfile
COPY Gemfile .

# Instala dependencias de Ruby sin bloquear versiones
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copia la aplicación
COPY . .

# Puerto expuesto (debe coincidir con el puerto en app.rb)
EXPOSE 4002

# Variables de entorno por defecto
ENV RACK_ENV=production
ENV PORT=4002

# Comando para ejecutar la aplicación con rackup
CMD ["rackup", "--host", "0.0.0.0", "--port", "4002"]
