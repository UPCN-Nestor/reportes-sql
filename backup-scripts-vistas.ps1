# Definir variables de conexión
$servidor = "192.168.0.230"
$baseDeDatos = "UPCN_REPORTES"
$usuario = "consultas"
$password = "Csua2018"
$directorioSalida = "C:\Repos\reportes-sql\SQL_Exports"  # Ruta hacia tu repositorio local de Git
$archivoLog = "C:\Repos\reportes-sql\log.txt"            # Ruta hacia el archivo de log

# Función para registrar mensajes en el log
function Registrar-Mensaje {
    param (
        [string]$mensaje
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entradaLog = "$timestamp - $mensaje"
    Add-Content -Path $archivoLog -Value $entradaLog
    Write-Host $entradaLog  # También lo mostramos en la consola
}

# Iniciar la grabación del log
Start-Transcript -Path $archivoLog -Append
Registrar-Mensaje "Iniciando proceso de exportación..."

# Cargar el módulo de SQL Server
Import-Module SqlServer

# Crear conexión con el servidor SQL
try {
    $cadenaConexion = "Server=$servidor;Database=$baseDeDatos;User Id=$usuario;Password=$password;"
    $conexion = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
    $conexion.ConnectionString = $cadenaConexion
    $instanciaServidor = New-Object Microsoft.SqlServer.Management.Smo.Server $conexion
    $instanciaBaseDatos = $instanciaServidor.Databases[$baseDeDatos]

    Registrar-Mensaje "Conectado al servidor SQL $servidor y a la base de datos $baseDeDatos correctamente."
}
catch {
    Registrar-Mensaje "Error al conectar con el servidor SQL: $_"
    Stop-Transcript
    exit 1  # Salir si no se puede conectar
}

# Asegurar que existen los directorios de salida para Vistas y Funciones
$directorioVistas = Join-Path $directorioSalida "Vistas"
$directorioFunciones = Join-Path $directorioSalida "Funciones"
if (-not (Test-Path $directorioVistas)) {
    New-Item -ItemType Directory -Force -Path $directorioVistas
}
if (-not (Test-Path $directorioFunciones)) {
    New-Item -ItemType Directory -Force -Path $directorioFunciones
}

# Exportar Vistas
try {
    $instanciaBaseDatos.Views | Where-Object { $_.IsSystemObject -eq $false } | ForEach-Object {
        $script = $_.Script()
        $script | Out-File "$directorioVistas\$($_.Name).sql"
        Registrar-Mensaje "Vista exportada: $($_.Name)"
    }
}
catch {
    Registrar-Mensaje "Error al exportar vistas: $_"
}

# Exportar Funciones con valor de tabla
try {
    $instanciaBaseDatos.UserDefinedFunctions | Where-Object { $_.FunctionType -eq "Table" } | ForEach-Object {
        $script = $_.Script()
        $script | Out-File "$directorioFunciones\$($_.Name).sql"
        Registrar-Mensaje "Función exportada: $($_.Name)"
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
