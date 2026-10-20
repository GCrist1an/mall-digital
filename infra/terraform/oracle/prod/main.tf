# =============================================================================
# Jira MD-15: Crear bases Oracle Autonomous DB (dev y prod) y aplicar esquema inicial
# Entorno: PRODUCCIÓN (prod)
# Archivo: main.tf - Configuración de base de datos Oracle Autonomous DB para producción
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 6.0"
    }
  }
  
  backend "local" {
    path = "c:/Users/LENOVO/Desktop/Mall digital/infra/terraform/oracle/prod/terraform.tfstate"
  }
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
  description = "Huella dactilar de la clave pública API de OCI"
  type        = string
}

variable "private_key_path" {
  description = "Ruta a la llave privada de la API de OCI"
  type        = string
}

variable "region" {
  description = "Región de OCI"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID del compartimento donde se creará la base de datos"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos (máximo 14 caracteres alfanuméricos)"
  type        = string
  default     = "mall_prod"
}

variable "db_display_name" {
  description = "Nombre para mostrar de la base de datos"
  type        = string
  default     = "Mall Digital - Produccion"
}

variable "db_password" {
  description = "Contraseña de administrador de la base de datos"
  type        = string
  sensitive   = true
}

variable "cpu_core_count" {
  description = "Número de núcleos de CPU OCPU"
  type        = number
  default     = 4
}

variable "storage_tb" {
  description = "Almacenamiento en TB"
  type        = number
  default     = 2
}

# Subred para la base de datos Autónoma
data "oci_core_vcn" "vcn_prod" {
  compartment_id = var.compartment_ocid
  display_name   = "mall-prod-vcn"
}

data "oci_core_subnet" "subnet_prod" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcn.vcn_prod.id
  display_name   = "mall-prod-subnet"
}

# Base de datos Oracle Autonomous - Producción
resource "oci_database_autonomous_database" "mall_prod_adb" {
  compartment_id        = var.compartment_ocid
  display_name          = var.db_display_name
  db_name               = var.db_name
  admin_password        = var.db_password
  cpu_core_count        = var.cpu_core_count
  data_storage_size_tb  = var.storage_tb
  is_free_tier          = false
  license_model         = "BRING_YOUR_OWN_LICENSE"
  workload_type         = "OLTP"
  db_version            = "23ai"
  db_workload           = "OLTP"
  is_dedicated          = false
  subnet_id             = data.oci_core_subnet.subnet_prod.id
  nsg_ids               = []
  
  # Configuración de backup automático - retención extendida en producción
  backup_config {
    automatic_backup_enabled         = true
    backup_retention_period_in_days  = 30
    recovery_window_period_in_days   = 7
    is_recovery_window_abovew_days   = false
  }
  
  # Configuración de mantenimiento
  maintenance_window_details {
    day_of_week  = "SUNDAY"
    time        = "06:00"
    auto_tune    = false
    is_replica  = false
  }
  
  # Tags para identificación del entorno
  freeform_tags = {
    Environment = "production"
    Project     = "MallDigital"
    ManagedBy   = "Terraform"
    JiraTicket  = "MD-15"
    Criticality = "High"
  }
  
  defined_tags = {
    Operations = {
      CostCenter = "IT-Prod"
    }
  }
  
  lifecycle_state = "AVAILABLE"
}

# Outputs
output "autonomous_database_id" {
  description = "OCID de la base de datos Autónoma de producción"
  value       = oci_database_autonomous_database.mall_prod_adb.id
}

output "autonomous_database_display_name" {
  description = "Nombre para mostrar de la base de datos de producción"
  value       = oci_database_autonomous_database.mall_prod_adb.display_name
}

output "autonomous_database_connection_string" {
  description = "Cadena de conexión para la base de datos de producción"
  value       = oci_database_autonomous_database.mall_prod_adb.connection_strings.all_connection_strings["HIGH"]
  sensitive   = true
}

output "autonomous_database_private_endpoint" {
  description = "Endpoint privado de la base de datos de producción"
  value       = oci_database_autonomous_database.mall_prod_adb.private_endpoint
  sensitive   = true
}

output "autonomous_database_db_name" {
  description = "Nombre de la base de datos de producción"
  value       = oci_database_autonomous_database.mall_prod_adb.db_name
}