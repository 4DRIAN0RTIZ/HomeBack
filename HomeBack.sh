#!/bin/bash

# Script para hacer backup de la carpeta Home y subirla a Google Drive
# Autor: Adrián Ortiz

# Trap para controlar la señal de interrupción

trap ctrl_c INT
function ctrl_c() {
	echo ""
	echo "Saliendo..."
	echo ""
	exit 1
}

# Comprobar distro

function obtener_distro() {
	distro= $(grep -m1 "^ID=" /etc/os-release | awk -F'=' '{ print $2 }' | tr -d '"')

	case "$distro" in
	"ubuntu" | "debian" | "linuxmint" | "kali")
		echo "apt-get"
		;;
	"fedora" | "centos" | "rhel")
		echo "dnf"
		;;
	"arch")
		echo "pacman"
		;;
	*)
		echo "No se pudo detectar la distro"
		exit 1
		;;
	esac
}

manejador_paquetes=$(obtener_distro)

# Verificación de dependencias
declare -A dependencias=(
	["wget"]="sudo $manejador_paquetes install wget -y"
	["tar"]="sudo $manejador_paquetes install tar -y"
	["python3"]="sudo $manejador_paquetes install python-is-python3 -y"
)

for dependencia in "${!dependencias[@]}"; do
	if ! command -v "$dependencia" &>/dev/null; then
		echo "El comando '$dependencia' no está instalado"
		echo "Instalando '$dependencia'..."
		eval "${dependencias[$dependencia]}"
		if [ $? -ne 0 ]; then
			echo "Error al instalar '$dependencia'"
			exit 1
		fi
	fi
done

# Verificación de archivos en el directorio actual
declare -A archivos_a_descargar=(
	["settings.yaml"]="https://gist.githubusercontent.com/4DRIAN0RTIZ/45c6273ebe20efeaf02c53ec156fd417/raw/63209dc6b5ac5cb2f870bfddcc0d6412bccded21/settings.yaml"
	["gdrive.py"]="https://gist.githubusercontent.com/4DRIAN0RTIZ/5da96f80dd35f81d596b0f95517ed838/raw/bb106e6e7efa3a5733245bbcb9a033783147f7ca/gdrive.py"
	["HomeBack.py"]="https://gist.githubusercontent.com/4DRIAN0RTIZ/e880ec9ac49b73531514d5861a302be9/raw/d440b9175f5a9ac24023d8eee8c39817279b3f36/HomeBack.py"
)

for archivo in "${!archivos_a_descargar[@]}"; do
	if [ ! -f "$archivo" ]; then
		echo "Archivo $archivo no encontrado"
		echo "Descargando $archivo..."
		wget "${archivos_a_descargar[$archivo]}"
		if [ $? -ne 0 ]; then
			echo "Error al descargar $archivo"
			exit 1
		fi
	fi
done

# Ruta de  del archivo de backup
backup_dir="$HOME/.backup"

# Carpetas a excluir en la copia de seguridad

declare -A carpetas_excluidas=(
	[".cache"]="$HOME/.cache"
	[".bin"]="$HOME/.bin"
	["snap"]="$HOME/snap"
	[".mozilla"]="$HOME/.mozilla"
	[".local"]="$HOME/.local"
	["Downloads"]="$HOME/Downloads"
	["4DRIAN0RTIZ-D0CS"]="$HOME/4DRIAN0RTIZ-D0CS"
	["BKBOT"]="$HOME/BKBOT"
	["University"]="$HOME/University"
	["HomeBack"]="$HOME/HomeBack"
	[".backup"]="$HOME/.backup"
)

# Convertir rutas a rutas absolutas
for i in "${!carpetas_excluidas[@]}"; do
	carpetas_excluidas[$i]=$(realpath "${carpetas_excluidas[$i]}")
done

# Crear directorio de backup si no existe
if [ ! -d "$backup_dir" ]; then
	mkdir -p "$backup_dir"
fi

# Eliminar archivos de backup antiguos
#find "$backup_dir" -type f -mtime +7 -delete
find "$backup_dir" -type f -delete

# Nombre del archivo de backup
backup_archivo="backup_home_$(date +%Y%m%d_%H%M%S).tar.gz"

# Construir el comando tar con las carpetas a excluir
tar_cmd=("tar")
for carpeta in "${carpetas_excluidas[@]}"; do
	tar_cmd+=("--exclude=$carpeta")
done

tar_cmd+=("-czf" "$backup_dir/$backup_archivo" "$HOME")

echo "Creando backup..."
"${tar_cmd[@]}"

echo "Backup completado: $backup_dir/$backup_archivo"
sleep 2

echo "Abriendo Script de Python"
sleep 2
python3 HomeBack.py $backup_archivo
