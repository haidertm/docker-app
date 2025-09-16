# Docker Compose Commands Reference

Quick reference guide for managing your Laravel Docker environment.

## 🚀 Container Management

### Starting & Stopping Containers

```bash
# Start all containers
docker-compose up -d

# Start specific service
docker-compose up -d webserver

# Stop all containers (keeps data)
docker-compose down

# Stop and remove volumes (CAREFUL: deletes database!)
docker-compose down -v

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart webserver
docker-compose restart nginx-web
docker-compose restart mysql
```

### Viewing Container Status

```bash
# List running containers
docker-compose ps

# View logs from all containers
docker-compose logs

# View logs from specific service
docker-compose logs webserver
docker-compose logs mysql
docker-compose logs nginx-web

# Follow logs in real-time
docker-compose logs -f webserver

# View last 100 lines
docker-compose logs --tail=100 webserver
```

## 🖥️ Accessing Containers

### Shell Access

```bash
# Access webserver container (Laravel/PHP)
docker-compose exec webserver bash
docker-compose exec webserver sh  # if bash not available

# Access MySQL container
docker-compose exec mysql bash

# Access Redis container
docker-compose exec redis redis-cli

# Access as root user (if permission issues)
docker-compose exec -u root webserver bash

# Login as www-data
docker-compose exec -u www-data webserver bash
```

## 🛠️ Laravel Artisan Commands

### Running Artisan Commands

```bash
# Run any artisan command
docker-compose exec webserver php artisan [command]

# Common artisan commands
docker-compose exec webserver php artisan migrate
docker-compose exec webserver php artisan migrate:fresh --seed
docker-compose exec webserver php artisan db:seed
docker-compose exec webserver php artisan cache:clear
docker-compose exec webserver php artisan config:clear
docker-compose exec webserver php artisan route:clear
docker-compose exec webserver php artisan view:clear
docker-compose exec webserver php artisan optimize
docker-compose exec webserver php artisan tinker

# Make commands
docker-compose exec webserver php artisan make:controller UserController
docker-compose exec webserver php artisan make:model User -m
docker-compose exec webserver php artisan make:migration create_users_table
docker-compose exec webserver php artisan make:seeder UserSeeder
docker-compose exec webserver php artisan make:livewire UserManager

# Queue management
docker-compose exec webserver php artisan queue:work
docker-compose exec webserver php artisan queue:listen
docker-compose exec webserver php artisan queue:restart
docker-compose exec webserver php artisan horizon  # if using Laravel Horizon

# Scheduling
docker-compose exec webserver php artisan schedule:work
docker-compose exec webserver php artisan schedule:run
```

## 📦 Composer Commands

```bash
# Install dependencies
docker-compose exec webserver composer install

# Update dependencies
docker-compose exec webserver composer update

# Install specific package
docker-compose exec webserver composer require laravel/breeze --dev
docker-compose exec webserver composer require livewire/livewire
docker-compose exec webserver composer require spatie/laravel-permission

# Remove package
docker-compose exec webserver composer remove package/name

# Clear composer cache
docker-compose exec webserver composer clear-cache

# Dump autoload
docker-compose exec webserver composer dump-autoload
```

## 🎨 NPM/Node Commands

```bash
# Install Node dependencies
docker-compose exec webserver npm install

# Build assets for development
docker-compose exec webserver npm run dev

# Build assets for production
docker-compose exec webserver npm run build

# Watch for changes (hot reload)
docker-compose exec webserver npm run watch

# Using Vite (Laravel 9+)
docker-compose exec webserver npm run dev -- --host
```

## 🗄️ Database Commands

### MySQL Access

```bash
# Access MySQL CLI
docker-compose exec mysql mysql -u root -ptiger

# Import database
docker-compose exec -T mysql mysql -u root -ptiger database_name < backup.sql

# Export database
docker-compose exec mysql mysqldump -u root -ptiger database_name > backup.sql

# Create new database
docker-compose exec mysql mysql -u root -ptiger -e "CREATE DATABASE prizebond_db"

# Show databases
docker-compose exec mysql mysql -u root -ptiger -e "SHOW DATABASES"
```

### Using PHPMyAdmin

```bash
# PHPMyAdmin is accessible at:
http://localhost:9090

# Credentials (from your docker-compose):
Server: mysql
Username: root
Password: tiger
```

## 🔄 TALL Stack Setup Commands

Complete sequence for setting up TALL stack:

```bash
# 1. Install Laravel Breeze
docker-compose exec webserver composer require laravel/breeze --dev

# 2. Install Breeze with Livewire
docker-compose exec webserver php artisan breeze:install livewire

# 3. Install NPM dependencies
docker-compose exec webserver npm install

# 4. Build assets
docker-compose exec webserver npm run build

# 5. Run migrations
docker-compose exec webserver php artisan migrate

# 6. Install additional TALL packages (optional)
docker-compose exec webserver composer require livewire/livewire
docker-compose exec webserver composer require usernotnull/tall-toasts
docker-compose exec webserver composer require wire-elements/modal
```

## 🔍 Debugging Commands

```bash
# Check PHP version
docker-compose exec webserver php -v

# Check Laravel version
docker-compose exec webserver php artisan --version

# Check installed PHP extensions
docker-compose exec webserver php -m

# Check Composer packages
docker-compose exec webserver composer show

# Check NPM packages
docker-compose exec webserver npm list

# Test database connection
docker-compose exec webserver php artisan db:show

# Clear all caches
docker-compose exec webserver php artisan optimize:clear
```

## 📝 File Permissions

```bash
# Fix storage permissions
docker-compose exec webserver chmod -R 775 storage
docker-compose exec webserver chmod -R 775 bootstrap/cache

# Change ownership (run as root)
docker-compose exec -u root webserver chown -R www-data:www-data storage
docker-compose exec -u root webserver chown -R www-data:www-data bootstrap/cache
```

## 🔧 Redis Commands

```bash
# Access Redis CLI
docker-compose exec redis redis-cli

# Clear Redis cache
docker-compose exec redis redis-cli FLUSHALL

# Monitor Redis commands
docker-compose exec redis redis-cli MONITOR

# Check Redis info
docker-compose exec redis redis-cli INFO
```

## 🔎 Elasticsearch Commands

```bash
# Check Elasticsearch health
curl http://localhost:9200/_cluster/health?pretty

# List all indices
curl http://localhost:9200/_cat/indices?v

# Delete an index
curl -X DELETE http://localhost:9200/your_index_name
```

## 📧 Mailhog (Email Testing)

```bash
# Mailhog UI is accessible at:
http://localhost:8025

# SMTP configuration for Laravel .env:
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

## 🚨 Troubleshooting

### Container Won't Start

```bash
# Check logs for errors
docker-compose logs webserver

# Rebuild containers
docker-compose build --no-cache
docker-compose up -d

# Remove and recreate
docker-compose down
docker-compose up -d --force-recreate
```

### Permission Issues

```bash
# Run as root to fix permissions
docker-compose exec -u root webserver bash

# Inside container as root:
chown -R www-data:www-data /var/www/http
chmod -R 755 /var/www/http
chmod -R 775 /var/www/http/storage
chmod -R 775 /var/www/http/bootstrap/cache
```

### Port Conflicts

```bash
# Check what's using a port (e.g., 9000)
lsof -i :9000  # On Mac/Linux
netstat -ano | findstr :9000  # On Windows

# Kill process using port
kill -9 [PID]  # On Mac/Linux
```

## 💡 Useful Aliases

Add these to your `~/.bashrc` or `~/.zshrc` for quick access:

```bash
# Docker Compose shortcuts
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dclog='docker-compose logs -f'
alias dcexec='docker-compose exec'

# Laravel specific
alias dart='docker-compose exec webserver php artisan'
alias dcomp='docker-compose exec webserver composer'
alias dnpm='docker-compose exec webserver npm'

# Quick access to containers
alias dweb='docker-compose exec webserver bash'
alias dmysql='docker-compose exec mysql mysql -u root -ptiger'
alias dredis='docker-compose exec redis redis-cli'

# Usage examples:
# dart migrate
# dcomp require laravel/sanctum
# dnpm run build
```

## 🎯 Prize Bond Project Specific Commands

```bash
# Initial setup for Prize Bond Tracker
docker-compose exec webserver composer create-project laravel/laravel prizebond-tracker
docker-compose exec webserver composer require laravel/breeze --dev
docker-compose exec webserver php artisan breeze:install livewire

# Create Prize Bond specific components
docker-compose exec webserver php artisan make:model PrizeBond -mfc
docker-compose exec webserver php artisan make:model Draw -mfc
docker-compose exec webserver php artisan make:model WinningBond -mfc
docker-compose exec webserver php artisan make:livewire BondManager
docker-compose exec webserver php artisan make:livewire SearchBonds
docker-compose exec webserver php artisan make:notification BondWonNotification
docker-compose exec webserver php artisan make:job CheckWinningBonds

# Run scheduled tasks manually
docker-compose exec webserver php artisan schedule:run
docker-compose exec webserver php artisan queue:work
```

## 📚 Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Laravel Documentation](https://laravel.com/docs)
- [Livewire Documentation](https://livewire.laravel.com)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

---

**Pro Tip**: Keep this file in your project root for quick reference. Update it as you add new services or discover useful commands for your workflow!