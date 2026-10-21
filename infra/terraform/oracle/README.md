# Infraestructura Oracle Cloud (OCI) · MD-15

Dos bases **Oracle Autonomous Database Always Free**: `dev/` y `prod/`.
Costo esperado: **$0 USD**. Ambas son `is_free_tier = true` (1 OCPU, 20 GB, sin escalar).

## Reglas de costos (no negociables)
- No agregues `cpu_core_count`, `compute_count`, `data_storage_size_*`, `license_model` ni `subnet_id`.
- No cambies `is_free_tier` a `false` ni lo conviertas en variable.
- Always Free permite **2 bases por tenancy** (dev + prod ocupan las 2) y solo en la **región home**.
- Antes de cualquier `apply`, revisa que el `plan` muestre `is_free_tier = true`.

## Uso (ejemplo con dev)
```powershell
cd infra/terraform/oracle/dev
Copy-Item terraform.tfvars.example terraform.tfvars   # completa OCIDs, llave y región
$env:TF_VAR_db_password = "TuClaveSegura123"          # 12-30 caracteres, mayús., minús. y número
terraform init
terraform validate
terraform plan
terraform apply
```
- `terraform.tfvars`, `*.tfstate` y `.terraform/` están en `.gitignore`: **nunca** se suben.
- El nombre de la base (`malldev`, `mallprod`) es solo alfanumérico (sin guion bajo).
- Para conectar la API necesitas el **wallet** (se descarga desde la consola de OCI) y un usuario de aplicación distinto de `ADMIN`.
- Versión de BD fija en `19c` en ambos entornos (el valor `23ai` deja de ser válido en dic-2026).
