import { useState } from "react";
import {
  Activity, Archive, ArrowRight, Bell, CheckCircle2, Circle, Cloud,
  Database, Files, HardDrive, LayoutDashboard, LockKeyhole, Menu,
  Network, ScrollText, Server, Settings, ShieldCheck, Users, X,
  Folder, UserPlus, Gauge, TerminalSquare
} from "lucide-react";

const navigation = [
  { title: "INICIO", items: [{ label: "Resumen", icon: LayoutDashboard }] },
  { title: "GESTIÓN", items: [{ label: "Transferencias", icon: Files }, { label: "Carpetas", icon: Folder }, { label: "Usuarios", icon: Users }, { label: "Invitados", icon: UserPlus }] },
  { title: "POLÍTICAS", items: [{ label: "Cuotas y límites", icon: Gauge }, { label: "Seguridad", icon: ShieldCheck }] },
  { title: "INFRAESTRUCTURA", items: [{ label: "Almacenamiento", icon: HardDrive }, { label: "Dominio y HTTPS", icon: Network }, { label: "Copias de seguridad", icon: Archive }] },
  { title: "TRAZABILIDAD", items: [{ label: "Auditoría", icon: ScrollText }, { label: "Registros", icon: TerminalSquare }] },
  { title: "SISTEMA", items: [{ label: "Sistema", icon: Settings }] },
];

const setupSteps = [
  { title: "Crear el primer administrador", detail: "Asistente seguro de configuración inicial", status: "Pendiente" },
  { title: "Configurar el almacenamiento", detail: "Elegir una ruta local y comprobar permisos", status: "Pendiente" },
  { title: "Configurar dominio y HTTPS", detail: "Definir la URL pública y el proxy inverso", status: "Pendiente" },
  { title: "Definir cuotas y límites", detail: "Separar tamaño máximo por archivo y GB por usuario", status: "Pendiente" },
  { title: "Activar autenticación multifactor", detail: "Proteger las cuentas administrativas con TOTP", status: "Pendiente" },
  { title: "Configurar copias de seguridad", detail: "Respaldar base de datos, archivos y claves", status: "Pendiente" },
];

const modules: Record<string, { intro: string; tasks: string[] }> = {
  Transferencias: { intro: "Controla los envíos, enlaces externos, caducidad y descargas.", tasks: ["Crear y consultar transferencias", "Revocar enlaces de descarga", "Consultar caducidad y descargas restantes", "Filtrar por propietario, carpeta, estado y fecha"] },
  Carpetas: { intro: "Organiza archivos y transferencias en espacios personales o compartidos, con permisos separados.", tasks: ["Crear carpetas y subcarpetas lógicas", "Asignar propietario y permisos de lectura, subida, compartición y administración", "Compartir una carpeta con miembros o invitados concretos", "Consultar el uso y la cuota del espacio", "Impedir que una persona acceda a carpetas fuera de su ámbito"] },
  Usuarios: { intro: "Gestiona cuentas internas, roles, sesiones y límites individuales.", tasks: ["Crear, editar, desactivar y reactivar usuarios", "Asignar roles y permisos", "Definir cuota total de almacenamiento por usuario", "Definir tamaño máximo por archivo", "Consultar consumo, subidas pendientes y espacio disponible", "Revocar sesiones y configurar MFA"] },
  Invitados: { intro: "Invita a personas externas sin convertirlas en miembros de la organización.", tasks: ["Enviar invitaciones por correo con caducidad", "Limitar el acceso a una carpeta o transferencia concreta", "Elegir permisos de lectura y, si se autoriza, subida", "Revocar invitaciones y accesos", "Consultar aceptación, última actividad y expiración", "Mantener a los invitados fuera de la administración y del resto de carpetas"] },
  "Cuotas y límites": { intro: "Administra por separado el espacio total de cada usuario y el tamaño de cada subida.", tasks: ["Cuota total en GB por usuario", "Tamaño máximo en GB por archivo", "Valores predeterminados y excepciones individuales", "Cuotas opcionales para carpetas compartidas", "Reservar espacio durante subidas simultáneas y liberarlo si fallan", "Avisos al alcanzar umbrales de uso y bloqueos al superar límites"] },
  Seguridad: { intro: "Define las políticas que se aplicarán a todas las transferencias y cuentas.", tasks: ["Política de contraseñas y MFA obligatorio", "Caducidad y número máximo de descargas", "Límites de tamaño, cuotas y protección contra intentos abusivos", "Restricciones por IP y sesiones"] },
  Almacenamiento: { intro: "Elige dónde se guardarán los archivos. Cada transferencia quedará asociada a un destino.", tasks: ["Disco local del servidor (primera implementación)", "NAS montado en Linux", "Almacenamiento compatible con S3"] },
  "Dominio y HTTPS": { intro: "Configura cómo accederán los usuarios a OpenTransfer desde Internet o la red corporativa.", tasks: ["URL pública de la instancia", "Proxy inverso Caddy o Nginx", "Certificado TLS y comprobación HTTPS"] },
  "Copias de seguridad": { intro: "Una copia recuperable debe incluir datos, archivos, configuración y las claves necesarias.", tasks: ["Programar copias de PostgreSQL", "Respaldar los archivos almacenados", "Proteger y respaldar las claves de cifrado", "Probar la restauración"] },
  Auditoría: { intro: "Consulta el historial de acciones de usuarios, invitados y administradores.", tasks: ["Inicios de sesión, MFA, fallos y revocaciones de sesión", "Invitaciones, cambios de permisos y accesos a carpetas", "Subidas, descargas, rechazos y revocaciones", "Cambios de cuota, políticas, almacenamiento y configuración", "Filtros por actor, acción, recurso, resultado y fecha", "Exportación controlada y política de retención"] },
  Registros: { intro: "Diagnostica el funcionamiento de OpenTransfer. Los registros técnicos no sustituyen a la auditoría.", tasks: ["Logs estructurados de API y tareas en segundo plano", "Errores de base de datos, almacenamiento y correo", "Niveles de severidad y filtros temporales", "Correlación mediante request ID", "Acceso y exportación restringidos y auditados", "Ocultar siempre contraseñas, cookies, tokens completos y claves"] },
  Sistema: { intro: "Información operativa, estado y mantenimiento de la instancia.", tasks: ["Estado de API, base de datos y almacenamiento", "Versión instalada y notas de actualización", "Diagnóstico y tareas de mantenimiento", "Historial de actualizaciones y resultado de health checks"] },
};

function App() {
  const [active, setActive] = useState("Resumen");
  const [menuOpen, setMenuOpen] = useState(false);
  const isOverview = active === "Resumen";
  const page = modules[active];

  return (
    <div className="min-h-screen bg-[#f5f7fb] text-slate-800">
      {menuOpen && <button aria-label="Cerrar navegación" onClick={() => setMenuOpen(false)} className="fixed inset-0 z-30 bg-slate-950/40 lg:hidden" />}
      <aside className={`fixed inset-y-0 left-0 z-40 flex w-[260px] flex-col bg-[#111b2b] text-slate-300 transition-transform lg:translate-x-0 ${menuOpen ? "translate-x-0" : "-translate-x-full"}`}>
        <div className="flex h-[76px] items-center gap-3 border-b border-white/10 px-6">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-500 text-white"><Files size={19}/></div>
          <div><div className="text-[17px] font-semibold tracking-tight text-white">OpenTransfer</div><div className="text-[10px] font-semibold uppercase tracking-[.18em] text-slate-500">ADMINISTRACIÓN</div></div>
          <button onClick={() => setMenuOpen(false)} className="ml-auto lg:hidden" aria-label="Cerrar"><X size={18}/></button>
        </div>
        <div className="mx-4 mt-5 rounded-xl border border-white/10 bg-white/[.04] p-3">
          <div className="flex items-center gap-2 text-[10px] font-semibold tracking-wider text-slate-400"><span className="h-2 w-2 rounded-full bg-amber-400"/> ESTADO DE LA INSTANCIA</div>
          <div className="mt-2 text-sm font-semibold text-white">Configuración pendiente</div>
          <div className="mt-1 text-xs text-slate-500">Entorno de desarrollo</div>
        </div>
        <nav className="sidebar-scroll flex-1 overflow-y-auto px-3 py-6">
          {navigation.map(group => <div key={group.title} className="mb-6">
            <div className="mb-2 px-3 text-[10px] font-bold tracking-[.16em] text-slate-500">{group.title}</div>
            {group.items.map(item => { const Icon = item.icon; const selected = active === item.label; return <button key={item.label} onClick={() => {setActive(item.label);setMenuOpen(false);}} className={`mb-1 flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-[13px] font-medium transition ${selected ? "bg-blue-500 text-white" : "text-slate-400 hover:bg-white/[.06] hover:text-white"}`}><Icon size={17}/>{item.label}</button>; })}
          </div>)}
        </nav>
        <div className="border-t border-white/10 px-5 py-4"><div className="flex items-center gap-2 text-xs font-medium text-slate-300"><LockKeyhole size={14}/> Seguridad por diseño</div><p className="mt-1 text-[11px] leading-relaxed text-slate-500">No actives funciones de seguridad hasta que el servidor pueda aplicarlas realmente.</p></div>
      </aside>

      <main className="min-h-screen lg:ml-[260px]">
        <header className="sticky top-0 z-20 flex h-[76px] items-center justify-between border-b border-slate-200 bg-white/90 px-4 backdrop-blur sm:px-7">
          <div className="flex items-center gap-3"><button onClick={() => setMenuOpen(true)} className="rounded-lg p-2 hover:bg-slate-100 lg:hidden" aria-label="Abrir navegación"><Menu size={19}/></button><div><div className="text-[11px] text-slate-400">OpenTransfer / Administración</div><h1 className="mt-0.5 text-lg font-semibold text-slate-900">{active}</h1></div></div>
          <div className="flex items-center gap-3"><span className="hidden rounded-full border border-amber-200 bg-amber-50 px-3 py-1.5 text-[10px] font-semibold text-amber-700 sm:inline-flex">PROTOTIPO · SIN BACKEND</span><button aria-label="Notificaciones" className="rounded-lg p-2 text-slate-500 hover:bg-slate-100"><Bell size={18}/></button><div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-100 text-[11px] font-bold text-blue-700">AD</div></div>
        </header>

        <div className="mx-auto max-w-[1320px] px-4 py-7 sm:px-7 lg:px-9 lg:py-9">
          {isOverview ? <Overview onNavigate={setActive}/> : <ModulePage title={active} intro={page?.intro ?? ""} tasks={page?.tasks ?? []}/>}
          <footer className="mt-10 flex flex-col gap-2 border-t border-slate-200 pt-5 text-[10px] text-slate-400 sm:flex-row sm:justify-between"><span>OpenTransfer · Panel de administración · MVP en desarrollo</span><span className="flex items-center gap-1"><Activity size={12}/> No conectado a servicios reales</span></footer>
        </div>
      </main>
    </div>
  );
}

function Overview({onNavigate}:{onNavigate:(page:string)=>void}) {
  return <>
    <div className="mb-7"><div className="text-sm text-slate-500">Bienvenido a OpenTransfer</div><h2 className="mt-1 text-2xl font-semibold tracking-tight text-slate-900">Pongamos tu instancia en marcha</h2><p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">Este panel prioriza las tareas necesarias para que el servidor esté configurado antes de permitir transferencias reales.</p></div>
    <div className="mb-6 flex items-start gap-3 rounded-xl border border-blue-200 bg-blue-50 p-4"><div className="mt-0.5 text-blue-600"><ShieldCheck size={19}/></div><div><div className="text-sm font-semibold text-blue-950">Primero, una base segura</div><p className="mt-1 text-xs leading-5 text-blue-800">Los indicadores de esta versión son informativos. La autenticación, las políticas y el almacenamiento todavía deben implementarse en el backend Go.</p></div></div>
    <div className="grid gap-5 xl:grid-cols-[1.4fr_1fr]">
      <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
        <div className="flex items-center justify-between"><div><h3 className="text-sm font-semibold text-slate-900">Lista de puesta en marcha</h3><p className="mt-1 text-xs text-slate-400">Pasos necesarios antes de producción</p></div><span className="rounded-full bg-slate-100 px-2.5 py-1 text-[10px] font-semibold text-slate-600">0 de 6 completados</span></div>
        <div className="mt-5 space-y-1">{setupSteps.map((step,i)=><div key={step.title} className="flex gap-3 rounded-xl px-2 py-3"><div className="mt-0.5 text-slate-300"><Circle size={18}/></div><div className="min-w-0 flex-1"><div className="text-xs font-semibold text-slate-800">{i+1}. {step.title}</div><div className="mt-1 text-[11px] text-slate-400">{step.detail}</div></div><span className="text-[10px] font-medium text-slate-400">{step.status}</span></div>)}</div>
      </section>
      <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
        <h3 className="text-sm font-semibold text-slate-900">Servicios de la instancia</h3><p className="mt-1 text-xs text-slate-400">Pendientes de conectar al backend</p>
        <div className="mt-5 space-y-3"><Service icon={Server} name="API Go" status="No conectada"/><Service icon={Database} name="PostgreSQL" status="No comprobado"/><Service icon={HardDrive} name="Almacenamiento" status="Sin configurar"/><Service icon={Cloud} name="HTTPS / dominio" status="Sin configurar"/></div>
        <button onClick={()=>onNavigate("Sistema")} className="mt-5 flex w-full items-center justify-center gap-2 rounded-lg border border-slate-200 py-2.5 text-xs font-semibold text-slate-600 hover:bg-slate-50">Ver sistema <ArrowRight size={14}/></button>
      </section>
    </div>
    <section className="mt-5"><div className="mb-3"><h3 className="text-sm font-semibold text-slate-900">Administración</h3><p className="mt-1 text-xs text-slate-400">Accesos a los módulos previstos para el MVP</p></div><div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4"><QuickCard icon={Files} title="Transferencias" detail="Enlaces y descargas" onClick={()=>onNavigate("Transferencias")}/><QuickCard icon={Folder} title="Carpetas" detail="Espacios y permisos" onClick={()=>onNavigate("Carpetas")}/><QuickCard icon={Users} title="Usuarios" detail="Cuentas y cuotas" onClick={()=>onNavigate("Usuarios")}/><QuickCard icon={UserPlus} title="Invitados" detail="Acceso externo limitado" onClick={()=>onNavigate("Invitados")}/><QuickCard icon={Gauge} title="Cuotas" detail="GB y tamaño por subida" onClick={()=>onNavigate("Cuotas y límites")}/><QuickCard icon={ScrollText} title="Auditoría" detail="Trazabilidad de acciones" onClick={()=>onNavigate("Auditoría")}/><QuickCard icon={TerminalSquare} title="Registros" detail="Diagnóstico técnico" onClick={()=>onNavigate("Registros")}/><QuickCard icon={HardDrive} title="Almacenamiento" detail="Local, NAS y S3" onClick={()=>onNavigate("Almacenamiento")}/></div></section>
  </>;
}

function ModulePage({title,intro,tasks}:{title:string;intro:string;tasks:string[]}) {
  return <><div className="mb-7"><div className="text-sm text-slate-500">Configuración de la instancia</div><h2 className="mt-1 text-2xl font-semibold tracking-tight text-slate-900">{title}</h2><p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">{intro}</p></div><div className="max-w-3xl rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"><div className="flex items-center gap-2"><CheckCircle2 size={17} className="text-blue-600"/><h3 className="text-sm font-semibold text-slate-900">Alcance del módulo MVP</h3></div><p className="mt-2 text-xs leading-5 text-slate-500">Estas son las funciones que implementaremos. Aún no hay controles conectados ni cambios que guardar desde esta pantalla.</p><div className="mt-5 divide-y divide-slate-100">{tasks.map(task=><div key={task} className="flex items-start gap-3 py-3"><Circle size={16} className="mt-0.5 shrink-0 text-slate-300"/><span className="text-xs leading-5 text-slate-700">{task}</span></div>)}</div><div className="mt-4 rounded-lg bg-amber-50 px-3 py-2.5 text-[11px] leading-5 text-amber-800">Módulo planificado. No introduzcas aquí contraseñas, claves ni credenciales reales.</div></div></>;
}

function Service({icon:Icon,name,status}:{icon:typeof Server;name:string;status:string}) {
  return <div className="flex items-center gap-3 rounded-lg bg-slate-50 px-3 py-3"><Icon size={16} className="text-slate-400"/><span className="flex-1 text-xs font-medium text-slate-700">{name}</span><span className="text-[10px] font-medium text-slate-400">{status}</span></div>;
}
function QuickCard({icon:Icon,title,detail,onClick}:{icon:typeof Files;title:string;detail:string;onClick:()=>void}) {
  return <button onClick={onClick} className="rounded-xl border border-slate-200 bg-white p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-blue-200 hover:shadow-md"><div className="flex items-center justify-between"><Icon size={18} className="text-blue-600"/><ArrowRight size={14} className="text-slate-300"/></div><div className="mt-4 text-xs font-semibold text-slate-800">{title}</div><div className="mt-1 text-[11px] text-slate-400">{detail}</div></button>;
}

export default App;
