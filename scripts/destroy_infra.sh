#!/usr/bin/env bash
# scripts/destroy_infra.sh

set -euo pipefail

# Apunta al directorio que contiene tus .tf (la raíz del proyecto)
TERRAFORM_DIR="../"

echo "🔄 Navegando a $TERRAFORM_DIR..."
pushd "$TERRAFORM_DIR" >/dev/null    # Guarda cwd y cambia al directorio padre :contentReference[oaicite:0]{index=0}

echo "🚀 Inicializando Terraform..."
terraform init -input=false          # Descarga proveedores y configura backend :contentReference[oaicite:1]{index=1}

echo "💥 Destruyendo infraestructura en Azure..."
terraform destroy -auto-approve      # Destruye todos los recursos sin confirmación :contentReference[oaicite:2]{index=2}

popd >/dev/null                       # Vuelve al directorio original :contentReference[oaicite:3]{index=3}
echo "✅ Infraestructura eliminada."
