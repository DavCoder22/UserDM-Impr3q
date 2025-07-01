FROM ruby:3.2.2-slim

# Instala dependencias del sistema
RUN apt-get update && \
    apt-get install -y build-essential libsqlite3-dev libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Crea el directorio de la aplicación
WORKDIR /app

# Copia el Gemfile y el Gemfile.lock
COPY Gemfile .

# Instala las gemas
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copia el resto de la aplicación
COPY . .

# Expone el puerto 4001
EXPOSE 4001

# Variables de entorno por defecto
ENV RACK_ENV=production
ENV PORT=4001

# Comando para ejecutar la aplicación con rackup
CMD ["rackup", "--host", "0.0.0.0", "--port", "4001"]
