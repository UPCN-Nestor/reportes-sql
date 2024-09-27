# Definir variables de conexión
$servidor = "192.168.0.230"
$baseDeDatos = "UPCN_REPORTES"
$usuario = "consultas"
$password = "Csua2018"
$directorioSalida = "C:\Repos\reportes-sql\SQL_Exports"  # Ruta a tu repositorio local de Git
$archivoLog = "C:\Repos\reportes-sql\transcript_log.txt"  # Archivo de log del transcript

# Iniciar la grabación del log
Start-Transcript -Path $archivoLog -Force

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

# Cargar el módulo de SQL Server
Import-Module SqlServer

# Crear conexión con el servidor SQL
try {
    $conexion = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
    $conexion.ServerInstance = $servidor
    $conexion.DatabaseName = $baseDeDatos
    $conexion.LoginSecure = $false  # Usar autenticación SQL Server
    $conexion.Login = $usuario
    $conexion.Password = $password

    $servidorSmo = New-Object Microsoft.SqlServer.Management.Smo.Server($conexion)
    $baseDeDatosSmo = $servidorSmo.Databases[$baseDeDatos]

    if ($baseDeDatosSmo -eq $null) {
        Registrar-Mensaje "No se pudo acceder a la base de datos $baseDeDatos."
        Stop-Transcript
        exit 1
    }

    Registrar-Mensaje "Conectado al servidor SQL $servidor y a la base de datos $baseDeDatos correctamente."
}
catch {
    Registrar-Mensaje "Error al conectar con el servidor SQL: $_"
    Stop-Transcript
    exit 1
}

# Asegurar que existen los directorios de salida para Vistas y Funciones
$directorioVistas = Join-Path $directorioSalida "Vistas"
$directorioFunciones = Join-Path $directorioSalida "Funciones"
if (-not (Test-Path $directorioVistas)) {
    New-Item -ItemType Directory -Force -Path $directorioVistas | Out-Null
}
if (-not (Test-Path $directorioFunciones)) {
    New-Item -ItemType Directory -Force -Path $directorioFunciones | Out-Null
}

# Exportar Vistas
try {
    $vistas = $baseDeDatosSmo.Views | Where-Object { $_.IsSystemObject -eq $false }
    Registrar-Mensaje "Número de vistas encontradas: $($vistas.Count)"

    foreach ($vista in $vistas) {
        $schema = $vista.Schema
        $nombre = $vista.Name
        $nombreArchivo = "${schema}_${nombre}.sql"
        $rutaArchivo = Join-Path $directorioVistas $nombreArchivo

        # Generar el script de la vista
        $scriptOptions = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions
        $scriptOptions.SchemaQualify = $true
        $scriptOptions.IncludeHeaders = $true
        $scriptOptions.FileName = $rutaArchivo

        $vista.Script($scriptOptions) | Out-Null
        Registrar-Mensaje "Vista exportada: $schema.$nombre"
    }
}
catch {
    Registrar-Mensaje "Error al exportar vistas: $_"
}

# Exportar Funciones
try {
	Registrar-Mensaje "Iniciando exportación de funciones..."
    $funciones = $baseDeDatosSmo.UserDefinedFunctions | Where-Object { $_.IsSystemObject -eq $false }
    Registrar-Mensaje "Número de funciones encontradas: $($funciones.Count)"

    foreach ($funcion in $funciones) {
        $schema = $funcion.Schema
        $nombre = $funcion.Name
        $nombreArchivo = "${schema}_${nombre}.sql"
        $rutaArchivo = Join-Path $directorioFunciones $nombreArchivo

        # Generar el script de la función
        $scriptOptions = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions
        $scriptOptions.SchemaQualify = $true
        $scriptOptions.IncludeHeaders = $true
        $scriptOptions.FileName = $rutaArchivo

        $funcion.Script($scriptOptions) | Out-Null
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
    $mensajeCommit = "Actualizacion de vistas y funciones - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
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
