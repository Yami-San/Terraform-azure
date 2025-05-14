cat > scripts/init_vm.sh <<'EOF'
#!/bin/bash
# Este es un ejemplo sencillo de startup script
echo "Arrancando configuración…" >> /var/log/startup-script.log
# Aquí puedes instalar paquetes, configurar servicios, etc.
# apt-get update && apt-get install -y nginx
EOF

chmod +x scripts/init_vm.sh