# Definir variables de conexión
$servidor = "192.168.0.230"
$instancia = "UPCN_REPORTES"  # Si tienes una instancia nombrada
$baseDeDatos = "UPCN_REPORTES"
$usuario = "consultas"
$password = "Csua2018"
$directorioSalida = "C:\Repos\reportes-sql\SQL_Exports"  # Ruta hacia tu repositorio local de Git
$archivoLog = "C:\Repos\reportes-sql\transcript_log.txt"  # Archivo de log del transcript

# Iniciar la grabación del log
Start-Transcript -Path $archivoLog -Append

# Función para registrar mensajes en la consola
function Registrar-Mensaje {
    param (
        [string]$mensaje
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entradaLog = "$timestamp - $mensaje"
    Write-Host $entradaLog
}

Registrar-Mensaje "Iniciando proceso de exportación..."

# Asegurar que existen los directorios de salida para Vistas y Funciones
$directorioVistas = Join-Path $directorioSalida "Vistas"
$directorioFunciones = Join-Path $directorioSalida "Funciones"
if (-not (Test-Path $directorioVistas)) {
    New-Item -ItemType Directory -Force -Path $directorioVistas | Out-Null
}
if (-not (Test-Path $directorioFunciones)) {
    New-Item -ItemType Directory -Force -Path $directorioFunciones | Out-Null
}

# Definir los parámetros de conexión para Invoke-Sqlcmd
$parametrosConexion = @{
    ServerInstance = "$servidor\$instancia"
    Database       = $baseDeDatos
    Username       = $usuario
    Password       = $password
}

# Obtener la lista de vistas
try {
    $consultaVistas = @"
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA NOT IN ('INFORMATION_SCHEMA', 'sys')
"@

    $vistas = Invoke-Sqlcmd @parametrosConexion -Query $consultaVistas

    Registrar-Mensaje "Número de vistas encontradas: $($vistas.Count)"

    foreach ($vista in $vistas) {
        $schema = $vista.TABLE_SCHEMA
        $nombre = $vista.TABLE_NAME
        $nombreArchivo = "${schema}_${nombre}.sql"
        $rutaArchivo = Join-Path $directorioVistas $nombreArchivo

        # Obtener el script de creación de la vista
        $consultaScriptVista = "EXEC sp_helptext '${schema}.${nombre}'"
        $scriptVista = Invoke-Sqlcmd @parametrosConexion -Query $consultaScriptVista | Select-Object -ExpandProperty Text

        # Guardar el script en un archivo
        $scriptVista | Out-File -FilePath $rutaArchivo -Encoding UTF8

        Registrar-Mensaje "Vista exportada: $schema.$nombre"
    }
}
catch {
    Registrar-Mensaje "Error al exportar vistas: $_"
}

# Obtener la lista de funciones con valor de tabla
try {
    $consultaFunciones = @"
SELECT ROUTINE_SCHEMA, ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION' AND DATA_TYPE = 'TABLE' AND ROUTINE_SCHEMA NOT IN ('INFORMATION_SCHEMA', 'sys')
"@

    $funciones = Invoke-Sqlcmd @parametrosConexion -Query $consultaFunciones

    Registrar-Mensaje "Número de funciones encontradas: $($funciones.Count)"

    foreach ($funcion in $funciones) {
        $schema = $funcion.ROUTINE_SCHEMA
        $nombre = $funcion.ROUTINE_NAME
        $nombreArchivo = "${schema}_${nombre}.sql"
        $rutaArchivo = Join-Path $directorioFunciones $nombreArchivo

        # Obtener el script de creación de la función
        $consultaScriptFuncion = "EXEC sp_helptext '${schema}.${nombre}'"
        $scriptFuncion = Invoke-Sqlcmd @parametrosConexion -Query $consultaScriptFuncion | Select-Object -ExpandProperty Text

        # Guardar el script en un archivo
        $scriptFuncion | Out-File -FilePath $rutaArchivo -Encoding UTF8

        Registrar-Mensaje "Función exportada: $schema.$nombre"
    }
}
catch {
    Registrar-Mensaje "Error al exportar funciones: $_"
}

# Navegar al repositorio de Git
Set-Location "C:\Repos\reportes-sql"

# Agregar cambios al área de preparación de Git
try {
    git add .
    Registrar-Mensaje "Cambios preparados para Git."
}
catch {
    Registrar-Mensaje "Error al preparar cambios: $_"
}

# Hacer commit de los cambios con un mensaje con timestamp
try {
    $mensajeCommit = "Actualización de vistas y funciones - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git commit -m $mensajeCommit
    Registrar-Mensaje "Commit realizado con el mensaje: '$mensajeCommit'"
}
catch {
    Registrar-Mensaje "Error al hacer commit: $_"
}

# Hacer push de los cambios al repositorio remoto
try {
    git push origin main  # Cambiar 'main' si tu rama principal tiene otro nombre
    Registrar-Mensaje "Cambios subidos al repositorio remoto."
}
catch {
    Registrar-Mensaje "Error al hacer push a Git: $_"
}

Registrar-Mensaje "Proceso de exportación y Git finalizado."

# Terminar la grabación del log
Stop-Transcript
