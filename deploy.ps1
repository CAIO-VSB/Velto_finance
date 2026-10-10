$ErrorActionPreference = "Stop"

$appImage = "caiodev2002/velto-finance:1.7.11"
$migrateImage = "caiodev2002/velto-finance-migrate:1.7.11"

function Invoke-Docker {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$DockerArgs)

  & docker @DockerArgs

  if ($LASTEXITCODE -ne 0) {
    throw "Falha: docker $($DockerArgs -join ' ')"
  }
}

Write-Host "Gerando imagem da aplicação..."
Invoke-Docker build --target runner -t $appImage .

Write-Host "Gerando imagem de migrations..."
Invoke-Docker build --target migrator -t $migrateImage .

Write-Host "Enviando aplicação..."
Invoke-Docker push $appImage

Write-Host "Enviando migrations..."
Invoke-Docker push $migrateImage

Write-Host "Tudo publicado. Agora rode update.sh no servidor."