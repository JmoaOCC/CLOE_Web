# C.L.O.E. COACH · Setup completo

## Archivos del sistema

| Archivo | Quién lo usa | Para qué |
|---------|-------------|----------|
| `login.html` | Todos | Acceso con email + contraseña |
| `onboarding.html` | Tú (admin) | Cuestionario → genera prompt para la IA |
| `admin.html` | Solo tú | Gestionar usuarios, ver y pegar planes |
| `app.html` | Cada usuario | Ver su plan, checklist, generar reporte |

---

## Flujo completo paso a paso

### Para persona nueva (ej: María):

1. **Tú abres** `onboarding.html`
2. Rellenas el cuestionario con los datos de María (5 pasos)
3. El formulario **genera automáticamente el prompt** con sus macros calculados
4. **Copias el prompt** → lo pegas en el chat del Proyecto CLOE
5. CLOE analiza el perfil y **genera el plan completo de Semana 1**
6. Copias el plan que devuelve CLOE
7. **Abres** `admin.html` → "+ Crear usuario"
8. Rellenas: nombre, email, contraseña, datos físicos
9. **Pegas el plan** de CLOE en el campo "Plan Semana 1"
10. Pulsas "Crear usuario"
11. Le mandas a María: URL de `login.html` + su email + contraseña
12. María entra y ve **su plan personalizado**

### Para actualizar el plan de María cada semana:

1. María genera su reporte desde `app.html` → sección "Reporte semanal"
2. Lo copia y te lo manda con sus fotos + CSV Intervals
3. **Tú lo pegas** en el chat del Proyecto CLOE
4. CLOE genera la Semana siguiente completa
5. Tú vas a `admin.html` → editas a María → pegas el nuevo plan
6. María abre la app y ve el plan actualizado

---

## Configuración Supabase

### 1. Crear cuenta en supabase.com (gratis)

### 2. Obtener credenciales
Settings → API:
- `Project URL` → sustituye `https://TU_PROYECTO.supabase.co`
- `anon public` → sustituye `TU_ANON_KEY`

Sustituir en los archivos que usan autenticación: `login.html`, `admin.html`, `app.html`

> `onboarding.html` no se conecta a Supabase: genera el prompt localmente.

### 3. Crear tabla `profiles`

También tienes el mismo bloque preparado en [supabase-setup.sql](./supabase-setup.sql).

```sql
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  email text,
  role text default 'user',
  status text default 'pending',
  week integer default 1,
  age integer,
  sex text,
  weight_kg numeric,
  height_cm integer,
  goal text,
  notes text,
  week1_plan text,
  current_plan text,
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create or replace function is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Cada usuario solo ve su propio perfil
create policy "own profile"
  on profiles for all
  using (auth.uid() = id);

-- Admin ve y edita todos
create policy "admin all"
  on profiles for all
  using (is_admin())
  with check (is_admin());

-- Trigger: crear perfil automáticamente al registrar
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', new.email));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
```

### 4. Crear tu cuenta admin

En Supabase → Authentication → Users → "Add user" (o "Invite"):
- Pon tu email y contraseña

Luego en SQL Editor:
```sql
update profiles set role = 'admin' where email = 'TU_EMAIL@aqui.com';
```

---

## Publicar en GitHub Pages

1. Crea repositorio en github.com (puede ser privado)
2. Sube los 4 archivos `.html`
3. Settings → Pages → Deploy from branch → main → / (root)
4. URL: `https://TU_USUARIO.github.io/TU_REPO/login.html`

---

## Resumen de URLs

- Login: `.../login.html`
- Cuestionario nuevo: `.../onboarding.html`
- Panel admin: `.../admin.html`
- App usuario: `.../app.html` (redirige automáticamente desde login)
