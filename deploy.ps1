$imagem = "caiodev2002/velto-finance:1.0.2"

Write-Host "Buildando imagem..."
docker build -t $imagem .

Write-Host "Enviando pro Docker Hub..."
docker push $imagem

Write-Host "Pronto! Agora roda o update.sh no servidor."