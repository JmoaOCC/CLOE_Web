# C.L.O.E. COACH · Setup completo

## Archivos del sistema

| Archivo | Quién lo usa | Para qué |
|---------|-------------|----------|
| `login.html` | Todos | Acceso con email + contraseña |
| `onboarding.html` | Usuario nuevo | Cuestionario inicial → guarda datos y genera prompt para la IA |
| `admin.html` | Solo tú | Gestionar usuarios, ver cuestionarios/reportes y pegar planes |
| `app.html` | Cada usuario | Ver su plan, checklist, generar reporte |

---

## Flujo completo paso a paso

### Para persona nueva (ej: María):

1. **Tú abres** `admin.html` → "+ Crear usuario"
2. Das de alta a María con nombre, email y contraseña inicial
3. María entra por primera vez en `login.html`
4. El sistema la lleva automáticamente a `onboarding.html`
5. María completa el cuestionario y lo guarda
6. Tú abres su perfil en `admin.html` y ves todos los datos introducidos
7. Copias el prompt/reporte del perfil y lo pegas en el chat del Proyecto C.L.O.E.
8. C.L.O.E. genera el plan completo de Quincena 1: 14 días, dos semanas de lunes a domingo
9. Pegas el plan en "Plan Quincena 1" dentro del perfil de María
10. María vuelve a hacer login y accede directamente a su plan personalizado

### Para actualizar el plan de María cada quincena:

1. María genera su reporte desde `app.html` → sección "Reporte quincenal"
2. El reporte queda guardado en su perfil y también puede copiarlo
3. Tú abres su perfil en `admin.html`, copias el último reporte y lo pegas en el chat del Proyecto C.L.O.E.
4. C.L.O.E. genera la quincena siguiente completa
5. Tú vas a `admin.html` → editas a María → pegas el nuevo plan
6. María abre la app y ve el plan actualizado

---

## Configuración Supabase

### 1. Crear cuenta en supabase.com (gratis)

### 2. Obtener credenciales
Settings → API:
- `Project URL` → sustituye `https://TU_PROYECTO.supabase.co`
- `anon public` → sustituye `TU_ANON_KEY`

Sustituir en los archivos que usan autenticación: `login.html`, `onboarding.html`, `admin.html`, `app.html`

> `onboarding.html` también se conecta a Supabase: guarda el cuestionario inicial del usuario y marca el onboarding como completado.

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
  quincena1_plan text,
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
