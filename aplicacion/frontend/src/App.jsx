import { useEffect, useState } from 'react'

// Versión del frontend, fijada al construir la imagen (--build-arg APP_VERSION).
const FRONTEND_VERSION = import.meta.env.VITE_APP_VERSION || 'local'

// Rutas relativas: el ALB envía /api/* al backend, así que no hace falta
// conocer su URL ni configurar CORS.
async function pedir(ruta, opciones) {
  const respuesta = await fetch(ruta, opciones)
  if (!respuesta.ok) {
    throw new Error(`${ruta} respondió ${respuesta.status}`)
  }
  return respuesta.json()
}

export default function App() {
  const [items, setItems] = useState([])
  const [titulo, setTitulo] = useState('')
  const [descripcion, setDescripcion] = useState('')
  const [backendVersion, setBackendVersion] = useState('…')
  const [cargando, setCargando] = useState(true)
  const [guardando, setGuardando] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    Promise.all([pedir('/api/items'), pedir('/api/version')])
      .then(([lista, version]) => {
        setItems(lista)
        setBackendVersion(version.version)
      })
      .catch((e) => {
        setError(`No se pudo conectar con la API: ${e.message}`)
        setBackendVersion('sin conexión')
      })
      .finally(() => setCargando(false))
  }, [])

  async function crear(evento) {
    evento.preventDefault()
    if (!titulo.trim()) return

    setGuardando(true)
    setError('')
    try {
      const nuevo = await pedir('/api/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ titulo: titulo.trim(), descripcion: descripcion.trim() }),
      })
      setItems((actuales) => [...actuales, nuevo])
      setTitulo('')
      setDescripcion('')
    } catch (e) {
      setError(`No se pudo guardar: ${e.message}`)
    } finally {
      setGuardando(false)
    }
  }

  return (
    <div className="pagina">
      <header>
        <h1>Lista de elementos del equipo</h1>
        <p className="subtitulo">Frontend en React que consume una API en FastAPI, ambos en Amazon ECS.</p>
      </header>

      <main>
        <section className="panel">
          <h2>Nuevo elemento</h2>
          <form onSubmit={crear}>
            <label>
              Título
              <input
                value={titulo}
                onChange={(e) => setTitulo(e.target.value)}
                maxLength={100}
                required
              />
            </label>
            <label>
              <span>
                Descripción <span className="opcional">(opcional)</span>
              </span>
              <textarea
                value={descripcion}
                onChange={(e) => setDescripcion(e.target.value)}
                maxLength={500}
                rows={3}
              />
            </label>
            <button type="submit" disabled={guardando || !titulo.trim()}>
              {guardando ? 'Guardando…' : 'Agregar'}
            </button>
          </form>
        </section>

        <section className="panel">
          <h2>
            Elementos <span className="contador">{items.length}</span>
          </h2>
          {error && <p className="error" role="alert">{error}</p>}
          {cargando ? (
            <p className="vacio">Cargando…</p>
          ) : items.length === 0 ? (
            <p className="vacio">Todavía no hay elementos. Crea el primero con el formulario.</p>
          ) : (
            <ul className="lista">
              {items.map((item) => (
                <li key={item.id}>
                  <span className="id">#{item.id}</span>
                  <div>
                    <strong>{item.titulo}</strong>
                    {item.descripcion && <p>{item.descripcion}</p>}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>

      <footer>
        <span>Frontend <code>{FRONTEND_VERSION.slice(0, 7)}</code></span>
        <span>Backend <code>{backendVersion.slice(0, 7)}</code></span>
      </footer>
    </div>
  )
}
