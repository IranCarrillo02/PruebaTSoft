# Decisiones técnicas

Registro de las decisiones de arquitectura e implementación relevantes del proyecto, en formato breve tipo ADR (Architecture Decision Record). El objetivo es dejar por escrito el *por qué*, no solo el *qué* — el código ya documenta el qué.

---

## ADR-001: MVVM en lugar de VIPER

**Fecha:** 2026-07-14

**Contexto:** el assessment permite explícitamente MVVM o VIPER, y el alcance real es de dos pantallas (listado y detalle).

**Decisión:** MVVM.

**Consecuencias:** VIPER añade cinco componentes por módulo (View, Interactor, Presenter, Entity, Router) que resultan en ceremonia desproporcionada para dos pantallas. MVVM da la misma separación de responsabilidades relevante (View no conoce la red ni la persistencia) con mucho menos boilerplate, y se integra de forma natural con `@Observable` y `NavigationStack` de SwiftUI. El propio assessment pide explícitamente priorizar claridad sobre complejidad innecesaria.

---

## ADR-002: SwiftData en lugar de Core Data

**Fecha:** 2026-07-14

**Contexto:** se requiere justificar la estrategia de persistencia.

**Decisión:** SwiftData.

**Consecuencias:** API nativa moderna, mucho menos código repetitivo que Core Data (sin `.xcdatamodeld`, sin `NSManagedObject` boilerplate), y se integra directamente con `@Model`/`ModelContainer`/`FetchDescriptor` usando Swift puro (macros, `#Predicate`). Trade-off aceptado: menor madurez/documentación que Core Data y algunas limitaciones de migración compleja, irrelevantes para el alcance de este proyecto (dos entidades simples de caché).

---

## ADR-003: async/await en lugar de Combine

**Fecha:** 2026-07-14

**Contexto:** el assessment permite explícitamente Combine o async/await.

**Decisión:** async/await.

**Consecuencias:** menos boilerplate que Combine (sin `AnyCancellable`, sin operadores de composición para un flujo lineal simple de fetch → map → mostrar). `APIClient.request<T>(_:) async throws -> T` aísla `URLSession` de la capa visual, cumpliendo el requisito de no acoplar red y UI, sin necesidad de exponer `Publisher`s hacia arriba.

---

## ADR-004: Persistencia network-first con fallback a caché

**Fecha:** 2026-07-14

**Contexto:** se requiere justificar la estrategia de persistencia y considerar experiencia offline parcial.

**Decisión:** en cada carga, intentar primero la red; si tiene éxito, actualizar la caché SwiftData y mostrar esos datos; si falla, usar el último snapshot cacheado si existe; si no hay caché, mostrar el estado de error.

**Consecuencias:** da datos siempre lo más frescos posible cuando hay red, y una experiencia offline parcial razonable sin construir un motor de sincronización (reconciliación de conflictos, invalidación por TTL, etc.) que estaría fuera de alcance para un reto de dos días. Trade-off documentado: no hay indicador visual de "estás viendo datos en caché" (ver Pendientes en el README) — el fallback es transparente para el usuario, priorizando simplicidad.

---

## ADR-005: Cero dependencias de terceros

**Fecha:** 2026-07-14

**Contexto:** el assessment da libertad de selección de librerías, pidiendo justificarlas.

**Decisión:** no usar ninguna dependencia externa (ni Alamofire, ni Kingfisher/SDWebImage, ni un framework de DI).

**Consecuencias:** Foundation/SwiftUI/SwiftData/XCTest/Swift Testing cubren todo lo necesario para este alcance. Se evita cualquier paso de resolución de paquetes (SPM) que pudiera fallar, quedar desactualizado o generar conflictos de versión en la máquina de quien revise el reto — alineado con el requisito de "entrega lista para revisión sin pasos manuales ambiguos". Trade-off aceptado: se escribió un `ImageLoader` propio con `NSCache` en vez de usar una librería de carga/caché de imágenes ya probada en producción; para dos pantallas con imágenes simples, el costo de mantenerlo es mínimo.

---

## ADR-006: URL del sprite construida desde el ID, no llamada al detalle por fila

**Fecha:** 2026-07-14

**Contexto:** el endpoint de listado de PokéAPI (`GET /pokemon?limit=20&offset=0`) solo devuelve `{name, url}`, sin imagen.

**Decisión:** extraer el ID numérico del segmento final de esa `url` y construir directamente la URL del sprite (`https://raw.githubusercontent.com/PokeAPI/sprites/.../{id}.png`), en vez de llamar al endpoint de detalle de cada Pokémon solo para obtener su imagen.

**Consecuencias:** evita un problema de N+1 requests (20 llamadas extra por página, cada vez que se pagina). El detalle completo (tipos, habilidades, stats, peso, altura) se pide de forma perezosa, solo para el Pokémon seleccionado, al navegar a su pantalla de detalle.

---

## ADR-007: Manejo de errores centralizado con `AppError`

**Fecha:** 2026-07-14

**Contexto:** se pide manejo centralizado de errores y mensajes amigables para el usuario (bonus).

**Decisión:** un único `AppError: LocalizedError` en `Domain/Errors/`, al que se mapean `NetworkError` y cualquier falla de SwiftData en el límite del repositorio.

**Consecuencias:** ambos ViewModels consumen únicamente `AppError` — la lógica de "qué mensaje mostrar para qué error" vive en un solo lugar en vez de duplicarse por pantalla, y agregar una pantalla nueva no implica reinventar el mapeo de errores.

---

## ADR-008: `@Observable` en lugar de `ObservableObject`

**Fecha:** 2026-07-14

**Contexto:** ambos ViewModels necesitan publicar cambios de estado hacia SwiftUI.

**Decisión:** macro `@Observable` (Observation framework, iOS 17+).

**Consecuencias:** invalidación de vista más fina — solo se redibujan las vistas que leen la propiedad específica que cambió, en vez de cualquier vista suscrita al objeto completo como con `@Published`/`ObservableObject`. También menos boilerplate (no hace falta anotar cada propiedad con `@Published`).

---

## ADR-009: Inyección de dependencias manual (`DependencyContainer`), sin framework

**Fecha:** 2026-07-14

**Contexto:** el assessment pide usar inyección de dependencias cuando aplique, sin exigir una herramienta específica.

**Decisión:** un `DependencyContainer` simple, construido una vez en `PruebaTSoftApp`, que inyecta por constructor: `APIClient → PokemonLocalDataSource → PokemonRepository → UseCases → ViewModels`.

**Consecuencias:** para dos pantallas, un framework de DI (Swinject, Factory, etc.) sería ceremonia innecesaria y una dependencia externa más. El contenedor manual es explícito, fácil de seguir leyendo un solo archivo, y suficiente para el tamaño del proyecto.

---

## ADR-010: Se adopta el aislamiento a `MainActor` por defecto del proyecto (Approachable Concurrency de Xcode 16+)

**Fecha:** 2026-07-14

**Contexto:** el proyecto viene generado con `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (el nuevo default de Xcode 16+ para apps SwiftUI). Esto se descubrió al compilar: llamadas con `await` desde el repositorio hacia el data source local generaban warnings de "no async operations occur", porque ambos ya corren implícitamente en `MainActor`.

**Decisión:** aceptar y trabajar con ese default en vez de forzar actores personalizados o `Task.detached` innecesarios, mantener `@MainActor` explícito solo donde documenta una restricción real (por ejemplo, que `ModelContext.mainContext` de SwiftData requiere `MainActor`), y quitar `await` en las llamadas que no cruzan de actor.

**Consecuencias:** para una app de dos pantallas con parseo de JSON liviano (~20 elementos) y persistencia simple, no hay beneficio real en mover trabajo a un actor de fondo — la razón de ser de este nuevo default de Apple es justamente evitar esa ceremonia en apps de este tamaño. Las llamadas de red siguen suspendiendo correctamente vía `URLSession` sin bloquear la UI. Si el proyecto creciera (por ejemplo, parseo pesado o miles de registros), valdría la pena reconsiderar mover el trabajo de `Data/` a un actor no aislado a `MainActor`.

---

## ADR-011: Un solo target de Xcode con separación por carpetas, no paquetes SPM locales

**Fecha:** 2026-07-14

**Contexto:** la Clean Architecture se puede reforzar a nivel de compilador separando cada capa en su propio paquete SPM local (límites de módulo reales, no solo convención).

**Decisión:** un solo target con carpetas `Domain/`, `Data/`, `Presentation/`, `App/`, separadas por protocolos y convención, no por módulos de compilación distintos.

**Consecuencias:** para dos pantallas, dividir en paquetes SPM locales sería una capa de indirección y de configuración (múltiples `Package.swift`, gestión de visibilidad `public`/`internal` entre módulos) que no aporta valor proporcional al tamaño del proyecto. La regla de dependencia (Presentation → Domain ← Data) se mantiene igual de real y verificable por code review; simplemente no está reforzada por el compilador. Es el trade-off explícito de "claridad sobre complejidad innecesaria" que pide el assessment.

---

## ADR-012: Los XCUITest corren contra la PokéAPI real, sin stub de red a nivel de UI test

**Fecha:** 2026-07-14

**Contexto:** los tests de UI (`PokemonFlowUITests`) lanzan la app completa y verifican listado → detalle.

**Decisión:** no interceptar la red en estos tests (a diferencia del test de integración de `PokemonRepository`, que sí usa `URLProtocol` stub); dejar que golpeen la PokéAPI real.

**Consecuencias:** son pruebas de humo (smoke tests) de que la app real, tal como se entrega, efectivamente habla con la API real de punta a punta — la forma más directa de detectar errores de wiring (DI, navegación, forma real del JSON) que un mock no puede revelar. El trade-off es una dependencia de red y disponibilidad de la API en CI; se mitigó con timeouts generosos (15s) en las aserciones. Si esto resultara flaky en la práctica, la siguiente iteración sería inyectar una URL base configurable por variable de entorno/launch argument para apuntar a un servidor de test.
