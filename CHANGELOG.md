# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [No Publicado]

### Agregado
- Configuración inicial del proyecto con autenticación JWT
- Integración con PostgreSQL para almacenamiento de usuarios
- Integración con Redis para manejo de sesiones y tokens revocados
- Sistema de recuperación de contraseña
- Sistema de verificación de correo electrónico
- Documentación completa de la API
- Pruebas automatizadas con RSpec
- Integración continua con GitHub Actions
- Configuración de CodeClimate para análisis de código
- Scripts de automatización para desarrollo
- Configuración de Docker para desarrollo y pruebas

### Cambiado
- Mejorado el manejo de errores en los controladores
- Optimizadas las consultas a la base de datos
- Actualizadas las dependencias a sus versiones más recientes

### Corregido
- Corregido un problema con la validación de tokens JWT
- Solucionado un error en el proceso de recuperación de contraseña
- Corregidos problemas de concurrencia en las pruebas

## [1.0.0] - 2025-01-01

### Agregado
- Versión inicial del proyecto

## Convención de Versionado

Este proyecto usa [Versionado Semántico 2.0.0](https://semver.org/). Para ver las versiones disponibles, revisa los [tags en este repositorio](https://github.com/tu-usuario/tu-repositorio/tags).

## Formato del Changelog

### Tipos de Cambios

- **Agregado**: Para nuevas características.
- **Cambiado**: Para cambios en la funcionalidad existente.
- **Obsoleto**: Para características que serán eliminadas en versiones futuras.
- **Eliminado**: Para características eliminadas en esta versión.
- **Corregido**: Para corrección de errores.
- **Seguridad**: En caso de vulnerabilidades.
