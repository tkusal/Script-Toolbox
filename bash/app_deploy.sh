REPO_DIR="/var/www/myapp"
SERVICE_NAME="myapp"

cd $REPO_DIR || { echo "Diretório do repositório não encontrado!"; exit 1; }
git pull origin main
npm install
npm run build

systemctl restart $SERVICE_NAME
echo "Aplicação atualizada e serviço reiniciado."