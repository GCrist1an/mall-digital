# Infraestructura Oracle Cloud (OCI) · MD-15

> ⚠️ **Las bases ya existen.** `deaquidev` (dev) y `deaquiprod` (prod) se crearon desde la consola de OCI
> en la región **Bogotá (`sa-bogota-1`)**. **No ejecutes `terraform apply`** sin antes importarlas con
> `terraform import`: Terraform no las conoce y crearía **bases duplicadas** (y Always Free solo admite 2
> por tenancy). Ver [Importar las bases existentes](#importar-las-bases-existentes).

Dos bases **Oracle Autonomous Database Always Free**: `dev/` y `prod/`.
Costo esperado: **$0 USD**. Ambas son `is_free_tier = true` (1 OCPU, 20 GB, sin escalar).

## Reglas de costos (no negociables)
- No agregues `cpu_core_count`, `compute_count`, `data_storage_size_*`, `license_model` ni `subnet_id`.
- No cambies `is_free_tier` a `false` ni lo conviertas en variable.
- Always Free permite **2 bases por tenancy** (dev + prod ocupan las 2) y solo en la **región home**.
- Antes de cualquier `apply`, revisa que el `plan` muestre `is_free_tier = true`.

## Importar las bases existentes
Una sola vez por entorno, antes de cualquier `plan`/`apply` (ejemplo con dev):
```powershell
cd infra/terraform/oracle/dev
Copy-Item terraform.tfvars.example terraform.tfvars   # completa OCIDs y llave
$env:TF_VAR_db_password = "..."                       # contraseña de ADMIN de la base
terraform init
terraform import oci_database_autonomous_database.mall_dev_adb <OCID de deaquidev>
terraform plan                                        # no debe proponer crear ni reemplazar nada
```
En prod el recurso es `oci_database_autonomous_database.mall_prod_adb` y el OCID el de `deaquiprod`
(lo ves en la consola: Autonomous Database → la base → OCID).

Si el `plan` muestra diferencias (por ejemplo `db_version`, mTLS o lista de IPs), ajusta el `.tf` a lo que
tiene la base real hasta que el `plan` quede limpio. **Nunca apliques un plan que diga `must be replaced`.**

## Notas
- `terraform.tfvars`, `*.tfstate` y `.terraform/` están en `.gitignore`: **nunca** se suben.
- El nombre de la base (`deaquidev`, `deaquiprod`) es solo alfanumérico (sin guion bajo); el nombre para
  mostrar en la consola es `deaqui-dev` / `deaqui-prod`.
- Para conectar la API necesitas el **wallet** (se descarga desde la consola de OCI) y un usuario de aplicación distinto de `ADMIN`.
- Versión de BD fija en `19c` en ambos entornos (el valor `23ai` deja de ser válido en dic-2026).
