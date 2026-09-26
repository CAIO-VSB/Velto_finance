$appImage = "caiodev2002/velto-finance:1.6.1"
$migrateImage = "caiodev2002/velto-finance-migrate:1.6.1"

Write-Host "Gerando imagem da aplicação..."
docker build --target runner -t $appImage .

Write-Host "Gerando imagem de migrations..."
docker build --target migrator -t $migrateImage .

Write-Host "Enviando imagens para o Docker Hub..."
docker push $appImage
docker push $migrateImage

Write-Host "Pronto. Execute update.sh no servidor."