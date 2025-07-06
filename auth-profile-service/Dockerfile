FROM ruby:3.2.2-alpine3.18

# Instalar dependencias del sistema
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    git \
    nodejs \
    yarn \
    bash \
    curl \
    less \
    libpq \
    ruby-bundler

# Configurar el directorio de trabajo
WORKDIR /app

# Copiar Gemfile
COPY Gemfile ./

# Instalar dependencias de Ruby
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copiar el código de la aplicación
COPY . .

# Exponer el puerto
EXPOSE 3000

# Comando por defecto
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "3000"]
