import { useState } from "react";
import {
  Activity, ArrowUpRight, Bell, Check, ChevronDown,
  CircleHelp, Cloud, Database, Download, FileCheck2, Files, HardDrive,
  LayoutDashboard, LockKeyhole, Menu, MoreHorizontal, Network, Plus,
  Search, Server, Settings, Shield, ShieldCheck, Users, X
} from "lucide-react";

type NavItem = { label: string; icon: typeof LayoutDashboard; group: string };

const navItems: NavItem[] = [
  { label: "Dashboard", icon: LayoutDashboard, group: "GENERAL" },
  { label: "Transferencias", icon: Files, group: "GENERAL" },
  { label: "Usuarios y grupos", icon: Users, group: "GESTIÓN" },
  { label: "Seguridad", icon: ShieldCheck, group: "GESTIÓN" },
  { label: "Almacenamiento", icon: HardDrive, group: "SISTEMA" },
  { label: "Dominios y HTTPS", icon: Network, group: "SISTEMA" },
  { label: "Copias de seguridad", icon: Database, group: "SISTEMA" },
  { label: "Auditoría y registros", icon: Activity, group: "SISTEMA" },
  { label: "Configuración", icon: Settings, group: "SISTEMA" },
];

const activity = [
  { initials: "LM", name: "Laura Martín", action: "ha creado una transferencia", detail: "Presentación Q4.pdf", time: "Hace 4 min", color: "bg-violet-100 text-violet-700" },
  { initials: "JR", name: "Jordi Ruiz", action: "ha descargado un archivo", detail: "Diseño campaña.zip", time: "Hace 18 min", color: "bg-sky-100 text-sky-700" },
  { initials: "AC", name: "Ana Costa", action: "ha creado una transferencia", detail: "Contrato firmado.pdf", time: "Hace 32 min", color: "bg-amber-100 text-amber-700" },
  { initials: "SP", name: "Sistema", action: "ha completado una copia de seguridad", detail: "Backup automático", time: "Hace 1 h", color: "bg-emerald-100 text-emerald-700" },
];

function App() {
  const [active, setActive] = useState("Dashboard");
  const [mobileOpen, setMobileOpen] = useState(false);
  const [notice, setNotice] = useState(false);

  const pageTitle = active === "Dashboard" ? "Dashboard" : active;
  const isDashboard = active === "Dashboard";

  function selectPage(label: string) {
    setActive(label);
    setMobileOpen(false);
  }

  return (
    <div className="min-h-screen bg-[#f5f7fb] text-slate-800">
      {mobileOpen && <button aria-label="Cerrar menú" onClick={() => setMobileOpen(false)} className="fixed inset-0 z-30 bg-slate-950/40 lg:hidden" />}
      <aside className={`sidebar-scroll fixed inset-y-0 left-0 z-40 flex w-[258px] flex-col overflow-y-auto bg-[#111b2b] text-slate-300 transition-transform lg:translate-x-0 ${mobileOpen ? "translate-x-0" : "-translate-x-full"}`}>
        <div className="flex h-[76px] items-center gap-3 border-b border-white/8 px-6">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-500 text-white shadow-lg shadow-blue-950/30"><Files size={19} /></div>
          <div>
            <div className="text-[17px] font-semibold tracking-tight text-white">OpenTransfer</div>
            <div className="text-[10px] font-semibold uppercase tracking-[.18em] text-slate-500">ADMINISTRATION</div>
          </div>
          <button onClick={() => setMobileOpen(false)} className="ml-auto rounded-lg p-1 text-slate-400 hover:bg-white/10 lg:hidden" aria-label="Cerrar menú"><X size={18}/></button>
        </div>

        <div className="mx-4 mt-5 rounded-xl border border-white/10 bg-white/[.045] p-3">
          <div className="flex items-center gap-2 text-xs font-medium text-slate-400"><span className="h-2 w-2 rounded-full bg-emerald-400"/> INSTANCIA</div>
          <div className="mt-2 text-sm font-semibold text-white">Mi organización</div>
          <div className="mt-0.5 text-xs text-slate-500">Servidor principal</div>
          <div className="mt-3 flex items-center justify-between border-t border-white/8 pt-2.5 text-xs"><span className="text-slate-400">Entorno</span><span className="rounded-md bg-amber-400/10 px-2 py-1 font-medium text-amber-300">Demostración</span></div>
        </div>

        <nav className="flex-1 px-3 pb-5 pt-6">
          {["GENERAL", "GESTIÓN", "SISTEMA"].map(group => (
            <div key={group} className="mb-5">
              <div className="mb-2 px-3 text-[10px] font-bold tracking-[.16em] text-slate-500">{group}</div>
              {navItems.filter(item => item.group === group).map(item => {
                const Icon = item.icon;
                const selected = active === item.label;
                return <button key={item.label} onClick={() => selectPage(item.label)} className={`mb-1 flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-[13px] font-medium transition ${selected ? "bg-blue-500 text-white shadow-md shadow-blue-950/30" : "text-slate-400 hover:bg-white/[.06] hover:text-white"}`}>
                  <Icon size={17} strokeWidth={1.8}/><span>{item.label}</span>
                  {item.label === "Seguridad" && <span className="ml-auto h-1.5 w-1.5 rounded-full bg-emerald-400"/>}
                </button>;
              })}
            </div>
          ))}
        </nav>

        <div className="m-3 rounded-xl border border-white/8 bg-white/[.04] p-3">
          <div className="flex items-center gap-2 text-xs font-semibold text-slate-200"><CircleHelp size={15}/> ¿Necesitas ayuda?</div>
          <p className="mt-1.5 text-[11px] leading-relaxed text-slate-500">Consulta la documentación para configurar tu instancia.</p>
          <span className="mt-2 inline-flex items-center gap-1 text-xs font-semibold text-blue-400">Documentación <ArrowUpRight size={12}/></span>
        </div>
        <div className="flex items-center gap-3 border-t border-white/8 px-5 py-4">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-blue-500/20 text-xs font-bold text-blue-300">AD</div>
          <div className="min-w-0 flex-1"><div className="truncate text-xs font-semibold text-white">Administrador</div><div className="text-[11px] text-slate-500">admin@empresa.local</div></div>
          <button aria-label="Opciones de cuenta" className="text-slate-500 hover:text-white"><MoreHorizontal size={18}/></button>
        </div>
      </aside>

      <main className="min-h-screen lg:ml-[258px]">
        <header className="sticky top-0 z-20 flex h-[76px] items-center justify-between border-b border-slate-200/80 bg-white/90 px-4 backdrop-blur-md sm:px-7 lg:px-9">
          <div className="flex items-center gap-3">
            <button onClick={() => setMobileOpen(true)} className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 lg:hidden" aria-label="Abrir menú"><Menu size={20}/></button>
            <div><div className="text-[11px] font-medium text-slate-400">OpenTransfer <span className="px-1">/</span> Administración</div><h1 className="mt-0.5 text-lg font-semibold tracking-tight text-slate-900">{pageTitle}</h1></div>
          </div>
          <div className="flex items-center gap-2 sm:gap-4">
            <div className="hidden items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-400 md:flex"><Search size={14}/> Buscar... <span className="ml-5 rounded border border-slate-200 bg-white px-1.5 py-0.5 text-[10px]">⌘ K</span></div>
            <button aria-label="Notificaciones" className="relative rounded-lg p-2 text-slate-500 hover:bg-slate-100"><Bell size={18}/><span className="absolute right-1.5 top-1.5 h-1.5 w-1.5 rounded-full bg-blue-500 ring-2 ring-white"/></button>
            <div className="hidden h-8 w-px bg-slate-200 sm:block"/>
            <button className="flex items-center gap-2 rounded-lg p-1.5 hover:bg-slate-50"><div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-100 text-[11px] font-bold text-blue-700">AD</div><ChevronDown size={14} className="hidden text-slate-400 sm:block"/></button>
          </div>
        </header>

        <div className="mx-auto max-w-[1440px] px-4 py-7 sm:px-7 lg:px-9 lg:py-9">
          {!isDashboard ? (
            <div className="rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600"><Settings size={22}/></div>
              <h2 className="mt-5 text-lg font-semibold text-slate-900">{active}</h2>
              <p className="mt-2 max-w-xl text-sm leading-6 text-slate-500">Este módulo forma parte de la arquitectura prevista de OpenTransfer. Estamos construyendo primero la base del panel; todavía no está conectado al servidor ni gestiona datos reales.</p>
              <button onClick={() => selectPage("Dashboard")} className="mt-5 rounded-lg bg-slate-900 px-4 py-2.5 text-xs font-semibold text-white hover:bg-slate-700">Volver al dashboard</button>
            </div>
          ) : <>
            <div className="mb-7 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
              <div><div className="text-sm text-slate-500">Bienvenido de nuevo, Administrador</div><h2 className="mt-1 text-2xl font-semibold tracking-tight text-slate-900">Resumen general</h2><p className="mt-1 text-sm text-slate-500">Esto es lo que ocurre en tu instancia de OpenTransfer.</p></div>
              <button onClick={() => setNotice(true)} className="inline-flex items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-xs font-semibold text-white shadow-sm shadow-blue-200 transition hover:bg-blue-700"><Plus size={15}/> Nueva transferencia</button>
            </div>

            {notice && <div role="status" className="mb-5 flex items-center justify-between rounded-xl border border-blue-200 bg-blue-50 px-4 py-3 text-xs text-blue-800"><span>La creación de transferencias estará disponible cuando conectemos el backend.</span><button onClick={() => setNotice(false)} aria-label="Cerrar aviso"><X size={15}/></button></div>}
            <div className="mb-5 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-relaxed text-amber-800"><strong>Vista de demostración:</strong> las cifras y eventos de esta pantalla son datos de ejemplo. Aún no representan el estado de un servidor real.</div>

            <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
              <Metric title="Transferencias" value="1.284" change="+12,8%" note="respecto al mes anterior" icon={Files} tone="blue"/>
              <Metric title="Almacenamiento usado" value="684 GB" change="68,4%" note="de 1 TB de capacidad" icon={HardDrive} tone="violet"/>
              <Metric title="Descargas" value="8.492" change="+8,2%" note="en los últimos 30 días" icon={Download} tone="green"/>
              <Metric title="Usuarios activos" value="36" change="+4" note="respecto al mes anterior" icon={Users} tone="orange"/>
            </section>

            <section className="mt-5 grid gap-5 xl:grid-cols-[1.55fr_1fr]">
              <div className="panel rounded-2xl border border-slate-200 bg-white p-5 sm:p-6">
                <div className="flex items-center justify-between"><div><h3 className="text-sm font-semibold text-slate-900">Actividad de transferencias</h3><p className="mt-1 text-xs text-slate-400">Volumen de actividad · datos ilustrativos</p></div><button className="flex items-center gap-1 rounded-lg border border-slate-200 px-2.5 py-1.5 text-[11px] font-medium text-slate-500">Últimos 7 días <ChevronDown size={13}/></button></div>
                <div className="mt-7 flex h-[190px] items-end gap-3 border-b border-l border-slate-100 px-2 pb-0 sm:gap-5">
                  {[42,66,51,78,59,88,72].map((height,i)=><div key={i} className="flex h-full flex-1 flex-col items-center justify-end gap-2"><div className="flex h-full w-full items-end justify-center"><div style={{height:height+"%"}} className={`w-full max-w-10 rounded-t-md ${i===6?"bg-blue-600":"bg-blue-100"}`}/></div><span className="translate-y-6 text-[10px] text-slate-400">{["L","M","X","J","V","S","D"][i]}</span></div>)}
                </div>
                <div className="mt-10 flex flex-wrap items-center gap-5 text-[11px] text-slate-500"><span className="flex items-center gap-2"><i className="h-2 w-2 rounded-sm bg-blue-600"/> Esta semana</span><span className="flex items-center gap-2"><i className="h-2 w-2 rounded-sm bg-blue-100"/> Días anteriores</span></div>
              </div>

              <div className="panel rounded-2xl border border-slate-200 bg-white p-5 sm:p-6">
                <div className="flex items-center justify-between"><div><h3 className="text-sm font-semibold text-slate-900">Almacenamientos</h3><p className="mt-1 text-xs text-slate-400">Destinos configurados · ejemplo</p></div><button onClick={() => selectPage("Almacenamiento")} className="text-xs font-semibold text-blue-600 hover:text-blue-700">Gestionar</button></div>
                <div className="mt-5 space-y-5">
                  <StorageRow icon={HardDrive} name="Servidor local" detail="/data/transfers" percent={72} color="bg-blue-500"/>
                  <StorageRow icon={Server} name="NAS · Oficina" detail="192.168.1.20 · montado" percent={46} color="bg-violet-500"/>
                  <StorageRow icon={Cloud} name="S3 compatible" detail="Almacenamiento remoto" percent={28} color="bg-emerald-500"/>
                </div>
              </div>
            </section>

            <section className="mt-5 grid gap-5 xl:grid-cols-[1.55fr_1fr]">
              <div className="panel rounded-2xl border border-slate-200 bg-white p-5 sm:p-6">
                <div className="flex items-center justify-between"><div><h3 className="text-sm font-semibold text-slate-900">Actividad reciente</h3><p className="mt-1 text-xs text-slate-400">Últimos eventos registrados · ejemplo</p></div><button onClick={() => selectPage("Auditoría y registros")} className="text-xs font-semibold text-blue-600">Ver auditoría</button></div>
                <div className="mt-4 divide-y divide-slate-100">{activity.map(item=><div key={item.name+item.detail} className="flex items-center gap-3 py-3"><div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-[10px] font-bold ${item.color}`}>{item.initials}</div><div className="min-w-0 flex-1"><p className="truncate text-xs text-slate-700"><strong className="font-semibold">{item.name}</strong> {item.action}</p><p className="mt-1 truncate text-[11px] text-slate-400">{item.detail}</p></div><span className="shrink-0 text-[10px] text-slate-400">{item.time}</span></div>)}</div>
              </div>

              <div className="panel rounded-2xl border border-slate-200 bg-white p-5 sm:p-6">
                <div className="flex items-center justify-between"><div><h3 className="text-sm font-semibold text-slate-900">Estado del sistema</h3><p className="mt-1 text-xs text-slate-400">Componentes previstos</p></div><span className="rounded-full bg-amber-50 px-2.5 py-1 text-[10px] font-semibold text-amber-700">Demo</span></div>
                <div className="mt-4 space-y-3">
                  <SystemStatus icon={Activity} label="API OpenTransfer" status="No conectada" good={false}/>
                  <SystemStatus icon={Database} label="PostgreSQL" status="Pendiente" good={false}/>
                  <SystemStatus icon={Shield} label="Cifrado y claves" status="Pendiente" good={false}/>
                  <SystemStatus icon={FileCheck2} label="Copias de seguridad" status="Sin configurar" good={false}/>
                </div>
                <button onClick={() => selectPage("Configuración")} className="mt-5 flex w-full items-center justify-center gap-2 rounded-lg border border-slate-200 py-2.5 text-xs font-semibold text-slate-600 hover:bg-slate-50">Configurar instancia <ArrowUpRight size={14}/></button>
              </div>
            </section>

            <footer className="mt-8 flex flex-col justify-between gap-2 border-t border-slate-200 pt-5 text-[10px] text-slate-400 sm:flex-row"><span>OpenTransfer · Panel de administración · Interfaz inicial</span><span className="flex items-center gap-1"><LockKeyhole size={11}/> Diseñado para despliegues autoalojados</span></footer>
          </>}
        </div>
      </main>
    </div>
  );
}

function Metric({title,value,change,note,icon:Icon,tone}:{title:string;value:string;change:string;note:string;icon:typeof Files;tone:string}) {
  const tones:Record<string,string> = {blue:"bg-blue-50 text-blue-600",violet:"bg-violet-50 text-violet-600",green:"bg-emerald-50 text-emerald-600",orange:"bg-orange-50 text-orange-600"};
  return <div className="metric-card rounded-2xl border border-slate-200 bg-white p-5"><div className="flex items-center justify-between"><span className="text-xs font-medium text-slate-500">{title}</span><span className={`flex h-9 w-9 items-center justify-center rounded-xl ${tones[tone]}`}><Icon size={17}/></span></div><div className="mt-4 flex items-baseline gap-2"><span className="text-[26px] font-semibold tracking-tight text-slate-900">{value}</span><span className="text-[10px] font-semibold text-emerald-600">{change}</span></div><p className="mt-1 text-[11px] text-slate-400">{note}</p></div>;
}

function StorageRow({icon:Icon,name,detail,percent,color}:{icon:typeof HardDrive;name:string;detail:string;percent:number;color:string}) {
  return <div><div className="flex items-center gap-2"><span className="text-slate-400"><Icon size={15}/></span><span className="text-xs font-semibold text-slate-700">{name}</span><span className="ml-auto text-[11px] font-semibold text-slate-600">{percent}%</span></div><div className="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-100"><div className={`h-full rounded-full ${color}`} style={{width:percent+"%"}}/></div><p className="mt-1.5 text-[10px] text-slate-400">{detail}</p></div>;
}

function SystemStatus({icon:Icon,label,status,good}:{icon:typeof Activity;label:string;status:string;good:boolean}) {
  return <div className="flex items-center gap-2.5 rounded-lg bg-slate-50 px-3 py-2.5"><Icon size={15} className="text-slate-400"/><span className="flex-1 text-xs font-medium text-slate-600">{label}</span><span className={`text-[10px] font-semibold ${good?"text-emerald-600":"text-slate-400"}`}>{status}</span>{good?<Check size={13} className="text-emerald-500"/>:<span className="h-1.5 w-1.5 rounded-full bg-slate-300"/>}</div>;
}

export default App;
