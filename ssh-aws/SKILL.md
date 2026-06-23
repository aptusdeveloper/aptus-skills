# ssh-aws — Acesso ao Servidor AWS EC2

## Conectar ao servidor
```bash
ssh aws
```
Abre terminal SSH no EC2 Ubuntu (`172.31.28.80`). Autenticação via chave configurada em `~/.ssh/config` — sem senha.

## Estrutura do servidor
```
/home/ubuntu/
├── aws-backend/          Código NestJS em produção
│   ├── dist/             Build compilado (o que PM2 executa)
│   ├── src/              Código-fonte TypeScript
│   ├── .env              Variáveis de ambiente de produção
│   └── deploy.sh         Script manual de deploy
└── site-institucional/
    └── dist/             Site estático servido pelo Nginx
```

## Comandos PM2
```bash
pm2 list                           # listar processos e status
pm2 logs aws-backend               # logs em tempo real (Ctrl+C para sair)
pm2 logs aws-backend --lines 100   # últimas 100 linhas
pm2 restart aws-backend            # reiniciar processo
pm2 status                         # status resumido
```

## Deploy manual
```bash
cd /home/ubuntu/aws-backend
./deploy.sh
# git pull → npm install → npm run build → pm2 restart
```

## Nginx
```bash
sudo nginx -t                                    # testar config
sudo systemctl reload nginx                      # recarregar sem downtime
sudo cat /etc/nginx/sites-enabled/default        # ver config atual
```

## Quando usar
- Verificar logs de produção após deploy ou incidente
- Executar deploy manual via `deploy.sh`
- Checar status do PM2
- Inspecionar `.env` de produção (somente leitura)
- Verificar configuração do Nginx
