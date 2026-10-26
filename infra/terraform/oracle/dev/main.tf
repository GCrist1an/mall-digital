# =============================================================================
# Jira MD-15: Bases Oracle Autonomous Database (dev y prod) para «De Aquí»
# Entorno: DESARROLLO (dev)
# -----------------------------------------------------------------------------
# COSTO $0: la base se crea SIEMPRE en Always Free (1 OCPU, 20 GB, sin escalar).
# `is_free_tier = true` es fijo a propósito (no es una variable): quitarlo la
# convertiría en un recurso de pago. No se declaran cpu_core_count, compute_count,
# data_storage_size_*, license_model ni subnet_id (endpoint privado): ninguno
# existe en Always Free y varios generan cobros.
# Límite de la cuenta: 2 bases Always Free por tenancy (dev + prod = las 2) y
# deben crearse en la región HOME del tenancy.
# Antes de aplicar: terraform plan, y confirma que muestre is_free_tier = true.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0.0"
    }
  }

  # Estado local relativo a esta carpeta (terraform.tfstate está en .gitignore).
  # Contiene la contraseña de admin: nunca se sube al repositorio.
  backend "local" {}
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

variable "tenancy_ocid" {
  description = "OCID del tenancy de Oracle Cloud"
  type        = string
}

variable "user_ocid" {
  description = "OCID del usuario de OCI"
  type        = string
}

variable "fingerprint" {
  description = "Huella de la clave pública de API de OCI"
  type        = string
}

variable "private_key_path" {
  description = "Ruta a la llave privada de API de OCI (fuera del repositorio)"
  type        = string
}

variable "region" {
  description = "Región HOME del tenancy (Always Free solo se crea allí)"
  type        = string
  default     = "sa-bogota-1"
}

variable "compartment_ocid" {
  description = "OCID del compartimento donde se crea la base de datos"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base: empieza con letra, solo alfanumérico, máx. 30 caracteres"
  type        = string
  default     = "deaquidev"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,29}$", var.db_name))
    error_message = "db_name debe empezar con letra y ser solo alfanumérico (sin guion bajo), máx. 30."
  }
}

variable "db_display_name" {
  description = "Nombre para mostrar de la base de datos"
  type        = string
  default     = "deaqui-dev"
}

variable "db_password" {
  description = "Contraseña de ADMIN: 12-30 caracteres, con mayúscula, minúscula y número, sin comillas dobles"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.db_password) >= 12 && length(var.db_password) <= 30 &&
      can(regex("[A-Z]", var.db_password)) &&
      can(regex("[a-z]", var.db_password)) &&
      can(regex("[0-9]", var.db_password)) &&
      !can(regex("\"", var.db_password))
    )
    error_message = "La contraseña debe tener 12-30 caracteres, mayúscula, minúscula, número y sin comillas dobles."
  }
}

variable "db_version" {
  description = "Versión de la base. Misma en dev y prod (23ai deja de ser válida en dic-2026)."
  type        = string
  default     = "19c"
}

variable "allowed_ips" {
  description = "IPs/CIDR con acceso a la base (ACL). Vacío = acceso público protegido solo por mTLS/wallet."
  type        = list(string)
  default     = []
}

# Base de datos Oracle Autonomous - DESARROLLO (Always Free)
resource "oci_database_autonomous_database" "mall_dev_adb" {
  compartment_id = var.compartment_ocid
  display_name   = var.db_display_name
  db_name        = var.db_name
  admin_password = var.db_password

  # Always Free: 1 OCPU y 20 GB fijos. Fijo en true: ver nota de costos arriba.
  is_free_tier = true

  db_version   = var.db_version
  db_workload  = "OLTP"
  is_dedicated = false

  # Sin autoescalado (en Always Free no aplica; se deja explícito).
  is_auto_scaling_enabled             = false
  is_auto_scaling_for_storage_enabled = false

  # Acceso por wallet (mTLS) y, opcionalmente, lista de IPs permitidas.
  is_mtls_connection_required = true
  whitelisted_ips             = length(var.allowed_ips) > 0 ? var.allowed_ips : null

  freeform_tags = {
    Environment = "development"
    Project     = "MallDigital"
    ManagedBy   = "Terraform"
    JiraTicket  = "MD-15"
  }
}

# Outputs
output "autonomous_database_id" {
  description = "OCID de la base de datos"
  value       = oci_database_autonomous_database.mall_dev_adb.id
}

output "autonomous_database_display_name" {
  description = "Nombre para mostrar de la base de datos"
  value       = oci_database_autonomous_database.mall_dev_adb.display_name
}

output "autonomous_database_db_name" {
  description = "Nombre de la base de datos"
  value       = oci_database_autonomous_database.mall_dev_adb.db_name
}

output "autonomous_database_connection_string" {
  description = "Cadena de conexión (servicio HIGH). Requiere el wallet de la base."
  value       = oci_database_autonomous_database.mall_dev_adb.connection_strings[0].all_connection_strings["HIGH"]
  sensitive   = true
}
