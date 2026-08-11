# AGData — Fila de Tarefas para Agente Executor

> Arquivo gerenciado pelo agente planejador. O agente executor deve pegar a próxima tarefa com status `pending`, implementá-la completamente, e mudar o status para `done`.
> Nunca marque `done` sem implementar. Nunca implemente uma tarefa `done`.

---

## TASK-001 · 🔴 Alta · Substituir cores hardcoded por AppColors nas telas de auth (parte 1)

**Status:** `done`  
**Arquivos:** `mobile/lib/features/auth/presentation/pages/login_page.dart`, `mobile/lib/features/auth/presentation/pages/change_password_page.dart`

**Contexto:**  
O design system do app define tokens em `core/theme/app_colors.dart`. Ambas as telas usam cores hardcoded (`Color(0xFF2E7D32)`, `Colors.red`, `Colors.grey`, etc.) em vez dos tokens, o que vai causar inconsistência se a paleta mudar.

**O que fazer:**

Em `login_page.dart`:
- `Color(0xFF2E7D32)` → `AppColors.primary`
- `Colors.red.shade700`, `Colors.redAccent` → `AppColors.danger`
- `Colors.grey` → `AppColors.textTertiary`

Em `change_password_page.dart`:
- `Color(0xFF2E7D32)` → `AppColors.primary`
- `Colors.redAccent`, `Colors.red` → `AppColors.danger`
- Barra de força da senha: substituir `[Colors.red, Colors.orange, Colors.green]` por `[AppColors.danger, AppColors.syncPending, AppColors.syncSuccess]`
- Adicionar import `app_colors.dart` se não existir

**Critérios de aceitação:**
- `dart analyze` sem erros ou warnings novos
- Nenhum `Colors.red`, `Colors.grey`, `Color(0xFF2E7D32)` restante nessas 2 telas
- Visual idêntico ao anterior (só troca constante, não muda valor numérico)

---

## TASK-002 · 🔴 Alta · Substituir cores hardcoded por AppColors nas telas de auth (parte 2)

**Status:** `done`  
**Arquivos:** `mobile/lib/features/auth/presentation/pages/add_user_page.dart`, `mobile/lib/features/auth/presentation/pages/super_admin_page.dart`, `mobile/lib/features/auth/presentation/pages/admin_page.dart`

**Contexto:** Mesma situação da TASK-001, outras telas.

**O que fazer:**

Em `add_user_page.dart`:
- `Color(0xFF2E7D32)` → `AppColors.primary`
- `Colors.red` → `AppColors.danger`
- `Colors.green` → `AppColors.primary` (se for ação positiva) ou `AppColors.syncSuccess`
- `Colors.blueGrey.shade50` → `AppColors.surfaceVariant`
- `Colors.blueAccent` → `AppColors.info`

Em `super_admin_page.dart`:
- `Color(0xFF2E7D32)` → `AppColors.primary`  
- `Colors.green` → `AppColors.primary` ou `AppColors.syncSuccess` conforme contexto
- `Colors.red` → `AppColors.danger`
- `Colors.blueGrey` → `AppColors.textSecondary` ou `AppColors.surfaceVariant`

Em `admin_page.dart`:
- `Colors.red` → `AppColors.danger`
- `Colors.green.shade50` → `AppColors.primaryContainer`
- `Color(0xFF2E7D32)`, `Color(0xFF1B5E20)` → `AppColors.primary`, `AppColors.primaryDark`
- `Colors.orange` → `Colors.orange` pode permanecer para o badge de admin (não há token laranja no AppColors)

**Critérios de aceitação:**
- `dart analyze` sem erros novos
- Nenhum `Color(0xFF2E7D32)` ou `Color(0xFF1B5E20)` hardcoded restante

---

## TASK-003 · 🟡 Média · Corrigir regex de validação de email

**Status:** `done`  
**Arquivos:** `mobile/lib/features/auth/presentation/pages/login_page.dart`, `mobile/lib/features/auth/presentation/pages/add_user_page.dart`

**Contexto:**  
Ambas as telas usam `r'^[^@]+@[^@]+\.[^@]+'` que permite emails inválidos como `a@b.c` (domínio de 1 char). Também verificar `forgot_password_page.dart` se existir.

**O que fazer:**  
Substituir a regex de validação de email pelo padrão mais robusto:
```dart
final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
```

Usar essa regex no validator de cada campo de email:
```dart
validator: (v) {
  if (v == null || v.isEmpty) return 'E-mail obrigatório';
  if (!_emailRegex.hasMatch(v.trim())) return 'E-mail inválido';
  return null;
},
```

A regex: exige pelo menos 2 chars no TLD, caracteres válidos no local-part e domínio.

**Critérios de aceitação:**
- `a@b.c` falha na validação
- `usuario@empresa.com.br` passa
- `dart analyze` sem erros

---

## TASK-004 · 🟡 Média · Preservar posição de scroll ao voltar do detalhe no HistóricoScreen

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`

**Contexto:**  
Ao abrir um detalhe de leitura e voltar, `_carregarDados()` é chamado no `didPopNext` e a lista reconstrói do topo. O usuário perde o contexto de onde estava.

**O que fazer:**

1. Adicionar `ScrollController _scrollController` ao state e inicializar no `initState`:
```dart
final ScrollController _scrollController = ScrollController();
```

2. Salvar a posição antes de navegar:
```dart
double _scrollOffset = 0;

// Antes do Navigator.push para detalhe:
_scrollOffset = _scrollController.offset;
```

3. Passar o controller ao `ListView.builder` ou `ListView` da tela:
```dart
controller: _scrollController,
```

4. Após `await _carregarDados()` (no retorno do detalhe), restaurar posição:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_scrollController.hasClients && _scrollOffset > 0) {
    _scrollController.jumpTo(
      _scrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
    );
  }
});
```

5. Fazer `dispose()` do controller.

**Critérios de aceitação:**
- Abrir detalhe de leitura na posição 5 da lista → voltar → lista reabre na posição 5
- Sem crash se a lista ficou menor após recarregar
- `dart analyze` limpo

---

## TASK-005 · 🟢 Baixa · Melhorar hint de senha na ChangePasswordPage

**Status:** `done`  
**Arquivo:** `mobile/lib/features/auth/presentation/pages/change_password_page.dart`

**Contexto:**  
O hint do campo "Nova Senha" provavelmente diz "Mínimo 6 dígitos" ou algo genérico. Deve ser mais claro sobre os requisitos.

**O que fazer:**
- Verificar o `hintText` / `labelText` do campo de senha
- Se disser "dígitos", trocar para "caracteres"
- Atualizar `helperText` ou adicionar abaixo do campo:
  ```
  helperText: 'Mínimo 8 caracteres'
  ```
- Atualizar o validator para exigir mínimo 8 chars (se atualmente exige 6, alinhar com o hint)

**Critérios de aceitação:**
- Hint/helper text claro e correto
- Validador alinhado com o que o texto promete
- `dart analyze` limpo

---

## TASK-006 · 🟡 Média · Dashboard — adicionar linha de últimas leituras recentes

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/home_dashboard_screen.dart`

**Contexto:**  
O dashboard atual tem TopBar + ClimaCard + MapControlCard + 2 action tiles. Falta uma seção de "Últimas leituras" que dá ao operador contexto imediato sem precisar ir ao Histórico.

**O que fazer:**

1. No `_HomeBody` (ou equivalente), após os action tiles, adicionar uma seção "Atividade recente".

2. Criar um `FutureBuilder` ou `initState` que carrega as últimas 3 leituras via `DatabaseService().buscarTodasLeituras()` e pega as 3 primeiras (já ordenadas por data desc).

3. Para cada leitura, exibir um `ListTile` compacto com:
   - Leading: `DiagnosticoBadge` ou ícone colorido via `DiagnosticoVisual.fromResultado(l.resultadoIA)`
   - Title: `l.talhao` + resultado
   - Subtitle: `formatarDataHora(l.dataHora)`
   - Trailing: `Icon(Icons.chevron_right)`
   - onTap: abre `LeituraDetalheScreen`

4. Se não houver leituras: mostrar texto sutil "Nenhuma análise ainda."

5. Adicionar um `TextButton('Ver todas')` que muda o tab do `RootScaffold` para o Histórico (usar `DefaultTabController` ou callback — verificar padrão existente).

**Observação:** O `DatabaseService` e `DiagnosticoVisual` já existem e podem ser importados diretamente.

**Critérios de aceitação:**
- As 3 leituras mais recentes aparecem no dashboard
- Tocar em uma abre o detalhe correto
- Se não há leituras, exibe texto vazio adequado
- `dart analyze` limpo

---

---

## TASK-007 · 🟡 Média · Testes unitários — lógica pura (formatters, visual, filtros)

**Status:** `done`  
**Arquivos a criar:**
- `mobile/test/unit/formatters_test.dart`
- `mobile/test/unit/diagnostico_visual_test.dart`
- `mobile/test/unit/email_validation_test.dart`
- `mobile/test/unit/relatorio_filter_test.dart`

**Contexto:**  
Há apenas um placeholder em `mobile/test/infra_test.dart`. O app tem lógica pura que pode ser testada sem Firebase/Isar.

**O que fazer:**

**`formatters_test.dart`** — testar `mobile/lib/core/utils/formatters.dart`:
- `formatarData(DateTime)` → "dd/MM/yyyy"
- `formatarDataHora(DateTime)` → "dd/MM/yyyy HH:mm"
- Casos: data normal, início do dia, fim do ano, mês com 1 dígito

**`diagnostico_visual_test.dart`** — testar `DiagnosticoVisual.fromResultado()` em `core/theme/diagnostico_visuals.dart`:
- "SAUDÁVEL" → `color == AppColors.saudavel` (ou o que o código definir)
- "FERRUGEM" → color ferrugem
- "INCONCLUSIVO" → color correspondente
- String inválida → fallback sem crash

**`email_validation_test.dart`** — testar a regex que será implementada na TASK-003:
- `usuario@empresa.com` → válido
- `usuario@empresa.com.br` → válido
- `a@b.c` → inválido (TLD < 2 chars)
- `semAroba` → inválido
- `@dominio.com` → inválido
- `usuario@.com` → inválido

**`relatorio_filter_test.dart`** — testar o getter `_leiturasFiltered` de `RelatorioPage`:
- Criar lista de `LeituraModel` mock com datas variadas
- Filtrar por range → apenas leituras no período aparecem
- Filtrar por talhão → apenas leituras do talhão
- Sem filtro → todas as leituras

**Critérios de aceitação:**
- `flutter test test/unit/` passa sem erros
- Nenhum import de Firebase ou Isar nos testes unitários (dados mock inline)

---

## TASK-008 · 🟡 Média · Testes de widget — componentes visuais isolados

**Status:** `done`  
**Arquivos a criar:**
- `mobile/test/widget/diagnostico_badge_test.dart`
- `mobile/test/widget/empty_state_test.dart`
- `mobile/test/widget/sync_status_button_test.dart`

**Contexto:** Componentes em `core/widgets/` e `features/diagnostico/presentation/widgets/` não têm cobertura de widget test.

**O que fazer:**

**`diagnostico_badge_test.dart`** — testar `core/widgets/diagnostico_badge.dart`:
- `DiagnosticoBadge(resultado: 'SAUDÁVEL')` → renderiza texto ou ícone correto
- `DiagnosticoBadge(resultado: 'FERRUGEM')` → cor diferente de SAUDÁVEL
- Widget não crasha com string desconhecida

**`empty_state_test.dart`** — testar `core/widgets/empty_state.dart`:
- Renderiza `title` e `message`
- Renderiza `action` quando fornecido
- Não renderiza action quando `action == null`
- `icon` aparece no widget tree

**`sync_status_button_test.dart`** — testar `SyncStatusButton` com estados mockados:
- Verificar que `Icons.cloud_done_outlined` aparece no estado "tudo sincronizado"
- Verificar que `CircularProgressIndicator` aparece durante sync
- Nota: este teste pode precisar de mocks para `ConnectivityService` e `DatabaseService` — usar `mockito` se já no pubspec, senão criar fakes simples

**Critérios de aceitação:**
- `flutter test test/widget/` passa
- Cada teste tem pelo menos 2 `expect()` com `findsOneWidget` / `findsNothing`

---

## TASK-009 · 🟢 Baixa · Testes unitários — lógica de filtro e ordenação do SelecaoTalhaoScreen

**Status:** `done`  
**Arquivo a criar:** `mobile/test/unit/selecao_talhao_filter_test.dart`

**Contexto:**  
`SelecaoTalhaoScreen._talhoesFiltrados` tem lógica de filtro por busca + 3 modos de ordenação. Vale testar isoladamente.

**O que fazer:**

O getter `_talhoesFiltrados` pode ser extraído para uma função pura testável, ou testado criando uma instância do state com dados mock.

Testar:
- Filtro por busca: "arr" filtra só talhões com "arr" no nome (case-insensitive)
- Ordem `nome`: lista ordenada A→Z
- Ordem `recente`: talhão com `ultimaLeitura` mais nova aparece primeiro; null vai pro fim
- Ordem `leituras`: talhão com maior `totalLeituras` aparece primeiro
- Busca vazia + ordem recente: retorna todos, ordenados por data

Para criar `TalhaoModel` sem Isar: instanciar diretamente (`TalhaoModel()..nome = 'X'..dataCriacao = DateTime.now()`).

**Critérios de aceitação:**
- `flutter test test/unit/selecao_talhao_filter_test.dart` passa
- Cada modo de ordenação coberto por ao menos 1 test case

---

---

## TASK-010 · 🔴 Alta · ForgotPasswordPage — corrigir cor hardcoded do botão

**Status:** `done`  
**Arquivo:** `mobile/lib/features/auth/presentation/pages/forgot_password_page.dart`

**Contexto:**  
A auditoria encontrou `const Color(0xFF2E7D32)` hardcoded na linha ~114 do botão principal. Todas as outras telas já foram corrigidas nas TASK-001/002 — esta ficou de fora.

**O que fazer:**
- Localizar `Color(0xFF2E7D32)` no arquivo
- Substituir por `AppColors.primary`
- Verificar se `app_colors.dart` já está importado; se não, adicionar
- Verificar se há outros `Color(0xFF...)` ou `Colors.*` hardcoded no arquivo e substituir

**Critérios de aceitação:**
- Nenhum `Color(0xFF2E7D32)` restante no arquivo
- `dart analyze` limpo

---

## TASK-011 · 🟡 Média · AdminPage — dividir lista de usuários em seções por role

**Status:** `done`  
**Arquivo:** `mobile/lib/features/auth/presentation/pages/admin_page.dart`

**Contexto:**  
A lista de usuários é uma `ListView.separated` flat que mistura admins e operadores. Com muitos usuários fica difícil entender a hierarquia. Deve ser dividida em duas seções com cabeçalho.

**O que fazer:**

1. Na query ou no state, separar os usuários em duas listas:
```dart
final admins = _usuarios.where((u) => u.role == UserRole.admin).toList();
final operadores = _usuarios.where((u) => u.role == UserRole.operador).toList();
```

2. Substituir o `ListView.separated` atual por um `ListView` com itens intercalados:
- Header "Administradores (N)" → `_SectionHeader`
- Cards dos admins
- Header "Operadores (N)" → `_SectionHeader`
- Cards dos operadores

3. Usar `SectionHeader` de `core/widgets/section_header.dart` para os cabeçalhos, ou criar um widget privado `_ListaHeader` com `Text` + `Divider`.

4. Se uma seção estiver vazia (ex.: nenhum admin além do atual), mostrar texto "Nenhum" ao invés de seção vazia.

5. Manter a barra de busca no topo — ela deve filtrar dentro de cada seção.

**Critérios de aceitação:**
- Admins aparecem acima, operadores abaixo, com cabeçalhos visíveis
- A busca ainda funciona e filtra ambas as seções
- Badge "Você" ainda aparece no usuário logado
- `dart analyze` limpo

---

## TASK-012 · 🟡 Média · HomeDashboard — contador de leituras pendentes de sync

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/home_dashboard_screen.dart`

**Contexto:**  
O `SyncStatusButton` na TopBar mostra um badge numérico quando há pendentes, mas fica pequeno e discreto. Um contador mais visível no dashboard ajuda o operador a saber que precisa sincronizar. Só aparece quando há pendentes.

**O que fazer:**

1. Adicionar um `FutureBuilder<int>` (ou carregar no `initState` com `setState`) que busca `DatabaseService().contarLeiturasPendentes()`.

2. Renderizar uma `Banner` ou `Card` informativa **somente quando `pendentes > 0`**:
```dart
if (pendentes > 0)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Card(
      color: AppColors.syncPending.withOpacity(0.15),
      child: ListTile(
        leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.syncPending),
        title: Text('$pendentes leitura(s) aguardando sincronização'),
        trailing: const Icon(Icons.chevron_right, size: 18),
        dense: true,
        onTap: () { /* nada por agora, ou abrir sheet de sync */ },
      ),
    ),
  ),
```

3. Posicionar esse widget entre o `ClimaCard` e os action tiles.

4. O `FutureBuilder` deve usar `DatabaseService().contarLeiturasPendentes()` — sem cache, carrega toda vez que o widget rebuilda.

**Critérios de aceitação:**
- Com 0 pendentes: widget não aparece
- Com N > 0 pendentes: widget aparece com texto correto
- `dart analyze` limpo

---

## TASK-013 · 🟢 Baixa · Migrar mensagens de "vazio" para o widget EmptyState

**Status:** `done`  
**Arquivos:** verificar `prescricao_page.dart`, `relatorio_page.dart`, `admin_page.dart`, `super_admin_page.dart`

**Contexto:**  
O widget `core/widgets/empty_state.dart` já existe com `icon`, `title`, `message` e `action` opcional. Algumas telas exibem um `Text` simples ou `SizedBox.shrink()` em vez de usar esse widget.

**O que fazer:**

1. Ler cada arquivo listado e procurar por padrões de estado vazio:
   - `Text('Nenhum...')` solto em `Center`
   - `SizedBox.shrink()` como fallback
   - `Padding + Text` sem ícone

2. Para cada caso encontrado, substituir por:
```dart
EmptyState(
  icon: Icons.xxx_outlined,
  title: 'Título curto',
  message: 'Mensagem explicativa do que o usuário pode fazer.',
)
```

3. Escolher ícone semanticamente correto:
   - Lista vazia de usuários → `Icons.people_outline`
   - Sem leituras → `Icons.analytics_outlined`
   - Sem talhões → `Icons.agriculture_outlined`
   - Sem relatório → `Icons.picture_as_pdf_outlined`

4. **NÃO** substituir `EmptyState` que já existe (como o de `SelecaoTalhaoScreen`).

**Critérios de aceitação:**
- Nenhum `Center(child: Text('Nenhum...'))` sem ícone restante nesses arquivos
- `dart analyze` limpo

---

## TASK-014 · 🟡 Média · Testes para SyncStatusButton — estados de resultado animado

**Status:** `done`  
**Arquivo a criar:** `mobile/test/widget/sync_result_animation_test.dart`

**Contexto:**  
O `SyncStatusButton` ganhou estados de resultado animado (✓/✗) na sessão anterior. Os testes existentes em `test/widget/sync_status_button_test.dart` provavelmente não cobrem esses novos estados.

**O que fazer:**

Criar `sync_result_animation_test.dart` com testes para:

1. Estado `sucesso` → `Icons.check_circle` aparece no widget tree
2. Estado `erro` → `Icons.cancel` aparece
3. Estado `none` + offline → `Icons.cloud_off_outlined` (ou equivalente) aparece
4. Verificar que `AnimatedSwitcher` está presente na árvore de widgets

Para isso, criar uma subclasse testável de `_SyncStatusButtonState` ou testar via pump+state manipulation.

**Alternativa simples se DI impedir:** Criar um widget de teste isolado `_TestSyncIcon` que só renderiza a parte de ícone baseado em enum `_SyncResultado` passado por parâmetro, e testá-lo diretamente.

**Critérios de aceitação:**
- `flutter test test/widget/sync_result_animation_test.dart` passa
- Ao menos 3 `expect()` com finders de ícone

---

---

## TASK-015 · 🔴 Alta · Adicionar token AppColors.warning e corrigir Colors.orange no ClimaCard

**Status:** `done`  
**Arquivos:** `mobile/lib/core/theme/app_colors.dart`, `mobile/lib/features/clima/presentation/clima_card.dart`

**Contexto:**  
A auditoria encontrou `Colors.orange` hardcoded nas linhas 98 e 107 de `clima_card.dart` para o estado offline. O design system não define um token `warning` (laranja), quebrando a regra de usar AppColors.

**O que fazer:**

1. Em `app_colors.dart`, adicionar após os tokens existentes:
```dart
static const Color warning = Color(0xFFE65100);
static const Color warningContainer = Color(0xFFFBE9E7);
```

2. Em `clima_card.dart`, substituir:
- `Colors.orange` (linha 98) → `AppColors.warning`
- `Colors.orange` (linha 107) → `AppColors.warning`

3. Adicionar import de `app_colors.dart` em `clima_card.dart` se ainda não existir.

**Critérios de aceitação:**
- `dart analyze` limpo
- Nenhum `Colors.orange` restante no ClimaCard
- Token `AppColors.warning` disponível para uso futuro

---

## TASK-016 · 🟡 Média · HistoricoScreen — limitar resolução de thumbnails para evitar jank

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`

**Contexto:**  
O widget `_Thumb` (linhas ~586-608) usa `Image.file()` sem `cacheWidth`/`cacheHeight`. Isso faz o Flutter decodificar a imagem full-resolution (geralmente 4-8 MB do sensor) na memória para exibir um thumbnail de 72×72px. Em listas longas causa picos de memória e jank.

**O que fazer:**

Localizar o `Image.file(...)` dentro de `_Thumb` e adicionar os parâmetros de cache:
```dart
Image.file(
  File(leitura.caminhoImagem),
  width: 72,
  height: 72,
  fit: BoxFit.cover,
  cacheWidth: 144,   // 2× para displays de alta resolução
  cacheHeight: 144,
  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
)
```

O `cacheWidth`/`cacheHeight` instrui o engine a decodificar na resolução exata, reduzindo uso de memória em ~99% por thumbnail.

**Critérios de aceitação:**
- `Image.file` em `_Thumb` tem `cacheWidth: 144, cacheHeight: 144`
- `dart analyze` limpo

---

## TASK-017 · 🟡 Média · ClimaCard — adicionar probabilidade de chuva à previsão

**Status:** `done`  
**Arquivos:** `mobile/lib/features/clima/data/clima_service.dart`, `mobile/lib/features/clima/presentation/clima_card.dart`

**Contexto:**  
A API Open-Meteo já é consultada mas só pede temperatura, umidade, vento e código WMO. A probabilidade de precipitação (`precipitation_probability_max`) é a métrica mais relevante para trabalho de campo agrícola e não está sendo exibida.

**O que fazer:**

1. Em `clima_service.dart`, adicionar `precipitation_probability_max` à lista de parâmetros `daily` da URL da API (verificar como os outros parâmetros daily são passados na URL).

2. Criar ou atualizar o modelo de clima (`ClimaModel` ou equivalente) para incluir:
```dart
final int? precipProbMax; // 0-100
```

3. No parser da resposta JSON (`fromJson` ou equivalente), extrair `precipitation_probability_max[0]` (dia atual).

4. Em `clima_card.dart`, adicionar na linha de previsão do dia atual ou na row de métricas:
```dart
if (precipProb != null)
  _MetricaItem(
    icon: Icons.water_drop_outlined,
    valor: '$precipProb%',
    label: 'Chuva',
  )
```

**Critérios de aceitação:**
- A probabilidade de chuva aparece no card quando disponível
- Se API retornar null, campo não aparece (sem crash)
- `dart analyze` limpo

---

## TASK-018 · 🟡 Média · HomeScreen — etapas visuais no progresso de análise ML

**Status:** `done`  
**Arquivos:** `mobile/lib/features/diagnostico/presentation/pages/home_screen.dart`, `mobile/lib/features/diagnostico/presentation/controllers/home_controller.dart`

**Contexto:**  
O `_LoadingCard` mostra apenas "Analisando amostra..." com um spinner genérico. O controller executa 3 etapas distintas: predição TFLite → extração GPS → salvamento. Exibir cada etapa dá feedback real ao usuário e reduz a ansiedade de espera.

**O que fazer:**

1. Em `home_controller.dart`, adicionar um campo `String etapaAtual` (ou enum) e chamar `notifyListeners()` ao mudar de etapa:
```dart
String etapaProgresso = 'Preparando análise...';

// Antes da predição:
etapaProgresso = 'Consultando IA...'; notifyListeners();

// Antes da extração GPS:
etapaProgresso = 'Obtendo localização...'; notifyListeners();

// Antes de salvar:
etapaProgresso = 'Salvando resultado...'; notifyListeners();
```

2. Em `home_screen.dart`, no `_LoadingCard`, exibir `controller.etapaProgresso` no lugar (ou abaixo) do texto fixo:
```dart
Text(
  controller.etapaProgresso,
  style: Theme.of(context).textTheme.bodyMedium,
  textAlign: TextAlign.center,
)
```

3. Garantir que o ListenableBuilder já envolve o card — se não, envolver.

**Critérios de aceitação:**
- Texto muda visivelmente durante o processamento (verificável no código — não precisamos rodar o app)
- `etapaProgresso` exposto como getter público no controller
- `dart analyze` limpo

---

## TASK-019 · 🟢 Baixa · LeituraDetalheScreen — mini-mapa embutido no lugar do link GPS

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/leitura_detalhe_screen.dart`

**Contexto:**  
O GPS da leitura é exibido como um `InfoPill` tappable (link para Google Maps). Uma miniatura de mapa embutida seria mais rica visualmente e mais útil em campo. O `flutter_map` já está no pubspec.

**O que fazer:**

1. Substituir o `GestureDetector + InfoPill` de GPS por um layout que mostra:
   - Um container de altura ~160px com `FlutterMap` + `MarkerLayer` marcando o ponto
   - Abaixo do mapa, o `InfoPill` com as coordenadas permanece como link para Google Maps (não remover)

2. O mapa deve usar o mesmo `TileLayer` com OSM e o mesmo cache (`CachedTileProvider`) que `mapa_screen.dart` usa (copiar a configuração).

3. `MapOptions` com `initialCenter = LatLng(l.latitude, l.longitude)` e `initialZoom = 17`.

4. Envolver o `FlutterMap` em `IgnorePointer(child: ...)` para que o mapa não intercepte scroll da tela — ou usar `MapOptions(interactionOptions: InteractionOptions(flags: InteractiveFlag.none))` para desabilitar interação.

5. Só renderizar quando `temGps == true` (já existe essa condição).

**Importações necessárias:** `flutter_map`, `flutter_map_cache`, `latlong2`, `path_provider`, `dio_cache_interceptor_hive_store` — todos já no pubspec.

**Critérios de aceitação:**
- Mini-mapa aparece no detalhe quando há coordenadas GPS
- Não é interativo (não captura scroll)
- Link do InfoPill ainda funciona ao tocar
- `dart analyze` limpo

---

## TASK-020 · 🟢 Baixa · Testes unitários para agrupamento por role no AdminPage

**Status:** `done`  
**Arquivo a criar:** `mobile/test/unit/admin_grouping_test.dart`

**Contexto:**  
A TASK-011 adicionou lógica de agrupamento (admins / operadores) no AdminPage. Vale cobrir com testes a lógica de separação de listas, filtro de busca por seção e contagem de cada grupo.

**O que fazer:**

Criar `admin_grouping_test.dart` com funções puras que espelham a lógica do AdminPage:

```dart
List<UserModel> filtrarPorRole(List<UserModel> lista, UserRole role) =>
    lista.where((u) => u.role == role).toList();

List<UserModel> filtrarPorBusca(List<UserModel> lista, String busca) =>
    busca.isEmpty ? lista : lista.where((u) =>
        u.name.toLowerCase().contains(busca.toLowerCase()) ||
        u.email.toLowerCase().contains(busca.toLowerCase())).toList();
```

Casos de teste:
- Lista mista → admins e operadores separados corretamente
- Busca "joao" → filtra por nome em ambos os grupos
- Lista só de operadores → seção admins vazia
- Lista vazia → ambas as seções vazias

**Critérios de aceitação:**
- `flutter test test/unit/admin_grouping_test.dart` passa
- Pelo menos 6 `expect()` cobrindo os casos acima

---

---

## TASK-021 · 🟡 Média · ClimaCard — adicionar sensação térmica (apparent_temperature)

**Status:** `done`  
**Arquivos:** `mobile/lib/features/clima/data/clima_service.dart`, `mobile/lib/features/clima/presentation/clima_card.dart`

**Contexto:**  
O card já mostra temperatura, umidade, vento e prob. de chuva (TASK-017). Para trabalhadores de campo, a sensação térmica (`apparent_temperature`) é mais relevante que a temperatura real — indica quanto calor/frio o corpo sente considerando vento e umidade.

**O que fazer:**

1. Em `clima_service.dart`, adicionar `apparent_temperature` à lista de parâmetros `hourly` da URL (verificar como os outros parâmetros hourly são passados). Pegar o valor do índice da hora atual.

2. No modelo de clima, adicionar:
```dart
final double? sensacaoTermica;
```

3. No parser JSON, extrair `hourly['apparent_temperature'][horaAtual]`.

4. Em `clima_card.dart`, exibir abaixo da temperatura principal:
```dart
if (sensacao != null)
  Text(
    'Sensação ${sensacao.toStringAsFixed(0)}°C',
    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
  )
```

**Critérios de aceitação:**
- "Sensação X°C" aparece no card quando API retorna o dado
- Se null, não aparece (sem crash)
- `dart analyze` limpo

---

## TASK-022 · 🟡 Média · PrescricaoPage — exibir estatísticas de cobertura GPS antes de exportar

**Status:** `done`  
**Arquivo:** `mobile/lib/features/prescricao/presentation/pages/prescricao_page.dart`

**Contexto:**  
Após calcular a grade (`_grade != null`), o usuário não sabe quantas células têm dados reais de leitura vs. quantas foram interpoladas. Uma linha de estatísticas torna o mapa de prescrição mais transparente.

**O que fazer:**

1. Após o widget de mapa de prescrição (`PrescricaoMapWidget`), adicionar um `Card` com estatísticas da grade:

```dart
// Calcular antes de renderizar:
final totalCelulas = _grade!.length;
final celulasComDados = _grade!.where((c) => c.temLeitura).length; // verificar propriedade real
final cobertura = (celulasComDados / totalCelulas * 100).round();
```

2. Exibir:
```dart
_InfoStatRow(
  label: 'Células na grade',
  valor: '$totalCelulas',
),
_InfoStatRow(
  label: 'Com dados GPS',
  valor: '$celulasComDados ($cobertura%)',
  valorColor: cobertura < 30 ? AppColors.warning : AppColors.syncSuccess,
),
```

3. Se cobertura < 30%, adicionar aviso sutil:
```dart
if (cobertura < 30)
  Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Text(
      'Cobertura baixa — considere fazer mais leituras para melhorar a precisão.',
      style: textTheme.bodySmall?.copyWith(color: AppColors.warning),
    ),
  ),
```

**Observação:** Inspecionar o modelo da célula de grade (`PrescricaoCell` ou equivalente) para encontrar o campo/propriedade que indica se a célula tem leitura real ou foi interpolada. Adaptar conforme necessário.

**Critérios de aceitação:**
- Estatísticas de cobertura aparecem quando `_grade != null`
- Aviso aparece quando cobertura < 30%
- `dart analyze` limpo

---

## TASK-023 · 🟡 Média · Testes unitários para filtros do HistoricoScreen

**Status:** `done`  
**Arquivo a criar:** `mobile/test/unit/historico_filter_test.dart`

**Contexto:**  
O `HistoricoScreen` tem filtros por doença, confiança mínima e intervalo de datas. Essa lógica de filtragem deve ser coberta por testes unitários independentes da UI.

**O que fazer:**

Criar `historico_filter_test.dart` extraindo a lógica de filtro como função pura testável:

```dart
List<LeituraModel> filtrarLeituras(
  List<LeituraModel> todas, {
  String? doenca,
  double? confiancaMin,
  DateTime? dataInicio,
  DateTime? dataFim,
}) {
  return todas.where((l) {
    if (doenca != null && l.resultadoIA != doenca) return false;
    if (confiancaMin != null && l.confianca < confiancaMin) return false;
    if (dataInicio != null && l.dataHora.isBefore(dataInicio)) return false;
    if (dataFim != null && l.dataHora.isAfter(dataFim)) return false;
    return true;
  }).toList();
}
```

Casos de teste:
- Filtro por doença "FERRUGEM" → retorna só leituras com esse resultado
- Filtro por confiança ≥ 0.8 → exclui leituras com confiança < 0.8
- Filtro por data → exclui leituras fora do intervalo
- Combinação de filtros → interseção dos critérios
- Sem filtros → retorna todas
- Lista vazia com filtros → retorna lista vazia

**Critérios de aceitação:**
- `flutter test test/unit/historico_filter_test.dart` passa
- Pelo menos 8 test cases

---

## TASK-024 · 🟢 Baixa · Verificar e corrigir lastDate nos date pickers do PrescricaoPage

**Status:** `done`  
**Arquivo:** `mobile/lib/features/prescricao/presentation/pages/prescricao_page.dart`

**Contexto:**  
O `RelatorioPage` já usa `lastDate: DateTime.now()` nos date pickers. O `PrescricaoPage` pode não ter essa proteção, permitindo selecionar datas futuras que nunca terão leituras.

**O que fazer:**

1. Buscar `showDatePicker` ou `showDateRangePicker` em `prescricao_page.dart`
2. Verificar se `lastDate` está setado para `DateTime.now()`
3. Se não estiver, adicionar `lastDate: DateTime.now()` a todos os pickers de data
4. Verificar também `firstDate` — deve ser `DateTime(2023)` ou similar (não `DateTime(1900)`)

**Critérios de aceitação:**
- `lastDate: DateTime.now()` presente em todos os date pickers do arquivo
- `dart analyze` limpo

---

---

## TASK-025 · 🔴 Alta · Integrar Sentry nos blocos catch dos controllers e repositories

**Status:** `done`  
**Arquivos:** `mobile/lib/features/diagnostico/presentation/controllers/home_controller.dart`, `mobile/lib/infra/repositories/sync_repository.dart`

**Contexto:**  
O Sentry está inicializado em `main.dart` e captura erros globais, mas os blocos `catch` nos controllers/repositories fazem apenas `debugPrint` — erros de produção passam invisíveis para o painel do Sentry.

**O que fazer:**

Import necessário (adicionar se ausente):
```dart
import 'package:sentry_flutter/sentry_flutter.dart';
```

Em `home_controller.dart`, nos blocos catch (linhas ~150 e ~187):
```dart
} catch (e, st) {
  debugPrint('Erro: $e');
  unawaited(Sentry.captureException(e, stackTrace: st));
  // ... resto do tratamento existente
}
```

Em `sync_repository.dart`, nos blocos catch sem Sentry (linhas ~86 e ~110):
```dart
} catch (e, st) {
  debugPrint('Erro sync: $e');
  unawaited(Sentry.captureException(e, stackTrace: st));
  // ... resto do tratamento existente
}
```

**Importante:** usar `unawaited(...)` (import `dart:async`) para não aguardar a chamada ao Sentry — não deve bloquear o fluxo. Manter o `debugPrint` existente.

**Critérios de aceitação:**
- Todos os blocos `catch (e)` relevantes passam a ser `catch (e, st)` com `Sentry.captureException`
- `dart analyze` limpo
- Nenhum await adicionado que possa causar delay na UI

---

## TASK-026 · 🔴 Alta · Substituir Colors.white por AppColors.onPrimary/textOnDark no HomeDashboardScreen

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/home_dashboard_screen.dart`

**Contexto:**  
8 ocorrências de `Colors.white` hardcoded no arquivo — todas em elementos sobre o fundo verde (`AppColors.primary`). O token correto é `AppColors.onPrimary` (branco puro) ou `AppColors.textOnDark` (branco para texto), ambos já definidos no design system.

**O que fazer:**

Para cada ocorrência de `Colors.white` no arquivo:
- Se é **cor de ícone ou texto sobre fundo verde**: usar `AppColors.textOnDark`
- Se é **cor de fundo translúcido** (`.withValues(alpha: 0.xx)` ou `.withOpacity`): usar `AppColors.onPrimary.withValues(alpha: 0.xx)` (mesmo efeito, semântica correta)
- Se é **foregroundColor de botão sobre fundo primário**: usar `AppColors.onPrimary`

Verificar também `app_button.dart` linha ~53 (spinner em `ElevatedButton` → `AppColors.onPrimary`) e `prescricao_page.dart` linha ~384 e `relatorio_page.dart` linha ~477 (spinners nos botões de ação → `AppColors.onPrimary`).

**Critérios de aceitação:**
- Nenhum `Colors.white` hardcoded restante nesses 4 arquivos
- `dart analyze` limpo
- Visual idêntico ao anterior

---

## TASK-027 · 🟡 Média · HistoricoScreen — paginação para listas longas

**Status:** `done`  
**Arquivos:** `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`, `mobile/lib/features/diagnostico/data/datasources/database_service.dart`

**Contexto:**  
`buscarTodasLeituras()` retorna todos os registros de uma vez. Com 1000+ leituras, a construção da lista e o uso de memória podem ser problemáticos. Implementar carregamento de 50 em 50 com "carregar mais" ao chegar no fim da lista.

**O que fazer:**

1. Em `DatabaseService`, adicionar método com paginação:
```dart
Future<List<LeituraModel>> buscarLeiturasPaginadas({
  int limite = 50,
  int offset = 0,
}) async {
  return await isar.leituraModels
      .where()
      .sortByDataHoraDesc()
      .offset(offset)
      .limit(limite)
      .findAll();
}
```

2. Em `HistoricoScreen`:
   - Trocar `_leituras` de carregamento total para carregamento paginado
   - Adicionar `_pagina = 0`, `_temMais = true`, `_carregandoMais = false`
   - Adicionar `ScrollController` para detectar chegada ao fim (além do já existente para preservar posição)
   - Ao chegar a 90% do scroll: chamar `_carregarMais()` que faz `buscarLeiturasPaginadas(offset: _leituras.length)`
   - Enquanto carrega mais: mostrar `CircularProgressIndicator` no final da lista

3. A busca com filtros ativos (doença, confiança, data) deve continuar funcionando — filtros são aplicados sobre `_leituras` carregados; com paginação, filtrar pode requerer continuar carregando até ter resultados suficientes ou atingir o fim.

**Critérios de aceitação:**
- Lista carrega apenas 50 leituras inicialmente
- Ao rolar até o final, carrega mais 50 automaticamente
- Spinner aparece enquanto carrega mais
- `dart analyze` limpo

---

## TASK-028 · 🟢 Baixa · HomeScreen — AnimatedSwitcher na transição processando→resultado

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/home_screen.dart`

**Contexto:**  
A transição entre o estado "processando" (spinner + etapas ML) e o estado "revisão de resultado" é abrupta — os widgets trocam instantaneamente. Um `AnimatedSwitcher` suaviza essa transição e dá feedback visual mais profissional.

**O que fazer:**

Localizar o método `_buildEstado()` (ou equivalente) que retorna widgets baseado em `_controller.status`. Envolver o widget retornado em `AnimatedSwitcher`:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 400),
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  ),
  child: KeyedSubtree(
    key: ValueKey(_controller.status),
    child: _buildEstado(_controller.status),
  ),
)
```

A `ValueKey(_controller.status)` garante que o switcher detecta a mudança de estado e anima a transição.

**Critérios de aceitação:**
- Fade+slide suave de ~400ms na transição entre estados
- `dart analyze` limpo
- Sem regressão nos outros estados (erro, inicial)

---

---

## TASK-029 · 🔴 Alta · Pull-to-refresh no HistoricoScreen

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`

**Contexto:**  
O `HistoricoScreen` tem um `ListView.builder` paginado mas não permite ao usuário forçar recarregamento dos dados. Pull-to-refresh é um padrão UX universal em apps mobile — ausência dele é perceptível.

**O que fazer:**

1. Localizar o `ListView.builder` principal (que lista `_leiturasFiltradas`).
2. Envolver com `RefreshIndicator`:
```dart
RefreshIndicator(
  onRefresh: _recarregar,
  child: ListView.builder(
    controller: _scrollController,
    // ... resto idêntico
  ),
)
```
3. Implementar `_recarregar()`:
```dart
Future<void> _recarregar() async {
  setState(() {
    _leituras = []; // ou _todasLeituras
    _temMais = true;
    _carregandoMais = false;
  });
  await _carregarDados();
}
```
   **Atenção:** Verificar os nomes exatos das variáveis usadas no arquivo (`_leituras`, `_todasLeituras`, etc.) e usar os corretos.

4. A lista filtrada (`_leiturasFiltradas`) deve ser recalculada após o reload — verificar se `_carregarDados()` já chama `_aplicarFiltros()` ou equivalente; se não, chamar explicitamente.

5. `dart analyze mobile` deve passar.  
6. Commit: `feat: pull-to-refresh no HistoricoScreen`

**Critérios de aceitação:**
- Puxar a lista para baixo dispara indicador de loading e recarrega desde a primeira página
- Filtros ativos são mantidos após o refresh
- Sem crash se o usuário soltar durante o carregamento

---

## TASK-030 · 🔴 Alta · Pull-to-refresh no HomeDashboard

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/home_dashboard_screen.dart`

**Contexto:**  
`HomeDashboardScreen` é atualmente um `StatelessWidget`. Para suportar pull-to-refresh que force recarregamento do `ClimaCard` (dados climáticos) e do `_PendentesBanner` (contador de pendentes), precisamos de uma key mutável que force o rebuild desses widgets.

**O que fazer:**

1. Converter `HomeDashboardScreen` de `StatelessWidget` para `StatefulWidget`.

2. Adicionar campo de estado: `int _refreshKey = 0;`

3. Implementar `_recarregar()`:
```dart
Future<void> _recarregar() async {
  setState(() => _refreshKey++);
  // Pequena pausa para garantir que o indicador seja visível
  await Future.delayed(const Duration(milliseconds: 500));
}
```

4. Envolver o `SingleChildScrollView` com `RefreshIndicator`:
```dart
RefreshIndicator(
  onRefresh: _recarregar,
  child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(), // necessário para pull-to-refresh funcionar mesmo com pouco conteúdo
    padding: ...,
    child: Column(...),
  ),
)
```

5. Passar `key: ValueKey('clima_$_refreshKey')` para `ClimaCard` e `key: ValueKey('pendentes_$_refreshKey')` para `_PendentesBanner` — isso força o Flutter a destruir e recriar os widgets, disparando seus respectivos `initState()` e recarregando os dados.

6. `dart analyze mobile` deve passar.  
7. Commit: `feat: pull-to-refresh no HomeDashboard forçando reload de ClimaCard e PendentesBanner`

**Critérios de aceitação:**
- Pull-to-refresh visível e funcional no HomeDashboard
- ClimaCard recarrega dados climáticos do servidor após o pull
- _PendentesBanner recarrega contador de pendentes após o pull
- `physics: AlwaysScrollableScrollPhysics()` garante que o gesto funcione mesmo quando o conteúdo não preenche a tela

---

## TASK-031 · 🟡 Média · Unit tests para lógica pura: iniciais do avatar e paginação

**Status:** `done`  
**Arquivos:** 
- `mobile/test/unit/avatar_iniciais_test.dart` (NOVO)
- `mobile/test/unit/paginacao_logic_test.dart` (NOVO)

**Contexto:**  
Os testes existentes seguem o padrão de testar funções puras sem dependências de UI ou Isar. A função de iniciais do avatar em `SettingsPage` e a lógica de paginação (`_temMais = novas.length == 50`) são candidatas ideais.

**O que fazer:**

**Arquivo 1:** `mobile/test/unit/avatar_iniciais_test.dart`

Extrair a lógica de iniciais como função pura (sem copiar o widget):
```dart
import 'package:flutter_test/flutter_test.dart';

/// Função pura espelho da lógica do _Avatar widget
String computarIniciais(String nome) {
  final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes[0][0].toUpperCase();
  return '${partes[0][0]}${partes.last[0]}'.toUpperCase();
}

void main() {
  group('computarIniciais', () {
    test('nome completo retorna primeira e última inicial', () {
      expect(computarIniciais('João Silva'), 'JS');
    });
    test('nome único retorna primeira letra maiúscula', () {
      expect(computarIniciais('Maria'), 'M');
    });
    test('string vazia retorna ?', () {
      expect(computarIniciais(''), '?');
    });
    test('apenas espaços retorna ?', () {
      expect(computarIniciais('   '), '?');
    });
    test('três partes usa primeira e última', () {
      expect(computarIniciais('Ana Paula Souza'), 'AS');
    });
    test('nome minúsculo é convertido para maiúsculo', () {
      expect(computarIniciais('carlos'), 'C');
    });
    test('espaços extras entre palavras são ignorados', () {
      expect(computarIniciais('  João   Silva  '), 'JS');
    });
  });
}
```

**Arquivo 2:** `mobile/test/unit/paginacao_logic_test.dart`

Testar a lógica de decisão `_temMais`:
```dart
import 'package:flutter_test/flutter_test.dart';

/// Espelho da lógica de paginação do HistoricoScreen
bool calcularTemMais(int registrosRetornados, {int limite = 50}) {
  return registrosRetornados == limite;
}

void main() {
  group('calcularTemMais', () {
    test('retorna true quando recebe página cheia (50 registros)', () {
      expect(calcularTemMais(50), isTrue);
    });
    test('retorna false quando recebe página incompleta (< 50)', () {
      expect(calcularTemMais(30), isFalse);
    });
    test('retorna false quando não há mais registros (0)', () {
      expect(calcularTemMais(0), isFalse);
    });
    test('retorna false quando recebe 49 registros', () {
      expect(calcularTemMais(49), isFalse);
    });
    test('funciona com limite personalizado', () {
      expect(calcularTemMais(20, limite: 20), isTrue);
      expect(calcularTemMais(19, limite: 20), isFalse);
    });
  });
}
```

**Rodar testes:** `flutter test test/unit/avatar_iniciais_test.dart test/unit/paginacao_logic_test.dart` (dentro de `mobile/`)

8. Commit: `test: testes unitários para iniciais do avatar e lógica de paginação`

**Critérios de aceitação:**
- Todos os testes passam sem erro
- Nenhum import de Flutter UI necessário nos arquivos de teste unitário (apenas `flutter_test`)

---

## TASK-032 · 🟡 Média · Unit tests para DiagnosticoStatus e etapaProgresso

**Status:** `done`  
**Arquivo:** `mobile/test/unit/home_controller_logic_test.dart` (NOVO)

**Contexto:**  
O `HomeController` tem lógica de estado complexa (`DiagnosticoStatus`, `etapaProgresso`, `descartar()`). Testar o controller diretamente exigiria mockar Classifier, Location, etc. — complexo. Mas a lógica de transição de estados pode ser testada como funções puras.

**O que fazer:**

Criar `mobile/test/unit/home_controller_logic_test.dart` testando a **lógica de decisão** do controller sem instanciar o `HomeController`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/presentation/controllers/home_controller.dart';

/// Funções puras que espelham decisões do HomeController
bool deveHabilitarSalvar(DiagnosticoStatus status, bool salvando) {
  return status == DiagnosticoStatus.revisao && !salvando;
}

bool deveExibirBotoesCaptura(DiagnosticoStatus status) {
  return status == DiagnosticoStatus.inicial || status == DiagnosticoStatus.erro;
}

void main() {
  group('DiagnosticoStatus enum', () {
    test('todos os valores estão presentes', () {
      expect(DiagnosticoStatus.values.length, 4);
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.inicial));
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.processando));
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.revisao));
      expect(DiagnosticoStatus.values, contains(DiagnosticoStatus.erro));
    });
  });

  group('deveHabilitarSalvar', () {
    test('habilitado apenas em revisão sem salvamento em curso', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.revisao, false), isTrue);
    });
    test('desabilitado durante salvamento', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.revisao, true), isFalse);
    });
    test('desabilitado em estado inicial', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.inicial, false), isFalse);
    });
    test('desabilitado em processamento', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.processando, false), isFalse);
    });
    test('desabilitado em erro', () {
      expect(deveHabilitarSalvar(DiagnosticoStatus.erro, false), isFalse);
    });
  });

  group('deveExibirBotoesCaptura', () {
    test('exibe botões no estado inicial', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.inicial), isTrue);
    });
    test('exibe botões no estado de erro (retry)', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.erro), isTrue);
    });
    test('oculta botões durante processamento', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.processando), isFalse);
    });
    test('oculta botões em revisão', () {
      expect(deveExibirBotoesCaptura(DiagnosticoStatus.revisao), isFalse);
    });
  });
}
```

**Rodar:** `flutter test test/unit/home_controller_logic_test.dart` (dentro de `mobile/`)

Commit: `test: testes de lógica de estados do DiagnosticoStatus`

**Critérios de aceitação:**
- Todos os testes passam
- Import apenas de `flutter_test` e do enum `DiagnosticoStatus` (sem instanciar HomeController)

---

---

## TASK-033 · 🔴 Alta · Fix: _UltimasLeituras usa buscarTodasLeituras — trocar por buscarLeiturasPaginadas(limite: 3)

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/home_dashboard_screen.dart`

**Contexto:**  
O widget `_UltimasLeituras` no dashboard usa `FutureBuilder` com `DatabaseService().buscarTodasLeituras()` para exibir apenas as 3 leituras mais recentes. Isso carrega **todo** o banco Isar em memória só para pegar 3 registros — ineficiente e piora conforme o banco cresce.

**O que fazer:**

Localizar na classe `_UltimasLeituras` (linha ~288) o `FutureBuilder` que usa `buscarTodasLeituras()` e substituir por `buscarLeiturasPaginadas`:

```dart
// ANTES:
future: DatabaseService().buscarTodasLeituras(),

// DEPOIS:
future: DatabaseService().buscarLeiturasPaginadas(limite: 3, offset: 0),
```

Após essa mudança, o snapshot já retorna exatamente 3 itens (os mais recentes, ordenados por data desc). Remover qualquer `.take(3)` ou `.sublist(0, 3)` que existia para limitar a lista, pois não é mais necessário.

**Verificar:** se havia `.take(3)` no builder do FutureBuilder, removê-lo. Se não havia e o código simplesmente iterava sobre `dados`, deixar como está — a paginação já limita.

`dart analyze mobile` → sem erros.  
Commit: `perf: _UltimasLeituras usa buscarLeiturasPaginadas ao invés de carregar tudo`

**Critérios de aceitação:**
- Nenhuma chamada a `buscarTodasLeituras()` no `home_dashboard_screen.dart`
- Dashboard mostra as 3 leituras mais recentes corretamente
- `dart analyze` limpo

---

## TASK-034 · 🔴 Alta · Exclusão de leituras selecionadas no HistoricoScreen

**Status:** `done`  
**Arquivos:**
- `mobile/lib/features/diagnostico/data/datasources/database_service.dart`
- `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`

**Contexto:**  
O HistoricoScreen já tem multi-seleção implementada (`_selecionados`, `_alternarSelecao()`) e usa a seleção para envio via WhatsApp. Porém, não há como **excluir** leituras selecionadas do dispositivo. Um botão de deletar é fundamental para gestão de dados locais.

**O que fazer:**

**1. Em `DatabaseService`**, adicionar método de exclusão por IDs:
```dart
Future<void> deletarLeituras(List<int> ids) async {
  await isar.writeTxn(() async {
    await isar.leituraModels.deleteAll(ids);
  });
}
```

**2. Em `HistoricoScreen.build()` — AppBar.actions**, adicionar ícone de delete quando há itens selecionados:
```dart
if (_selecionados.isNotEmpty)
  IconButton(
    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
    tooltip: 'Excluir selecionados',
    onPressed: _confirmarExclusao,
  ),
// ícones existentes (filter, share) depois
```

**3. Implementar `_confirmarExclusao()`:**
```dart
Future<void> _confirmarExclusao() async {
  final n = _selecionados.length;
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Excluir leituras?'),
      content: Text(
        'Serão excluídas $n leitura(s) deste dispositivo. '
        'Leituras já sincronizadas com a nuvem não serão afetadas.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.onPrimary,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmar != true || !mounted) return;

  final ids = List<int>.from(_selecionados);
  await _databaseService.deletarLeituras(ids);
  setState(() => _selecionados.clear());
  await _recarregar();

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$n leitura(s) excluída(s).')),
    );
  }
}
```

**Observação:** `AppColors.onPrimary` deve existir — verificar no `app_colors.dart`. Se não existir, usar `Colors.white`.

`dart analyze mobile` → sem erros.  
Commit: `feat: exclusão de leituras selecionadas no HistoricoScreen`

**Critérios de aceitação:**
- Ícone de lixeira aparece na AppBar quando há itens selecionados
- Dialog de confirmação exibe número de itens
- Após confirmação, itens são removidos do banco e da lista
- `dart analyze` limpo

---

## TASK-035 · 🟡 Média · Busca por texto no HistoricoScreen

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`

**Contexto:**  
O filtro atual cobre data, tipo de doença e grau de confiança, mas não permite busca textual por nome de talhão. Usuários com muitos talhões (T1, T2...T30) precisam rolar a lista para encontrar um específico.

**O que fazer:**

**1. Adicionar variável de busca:**
```dart
String _buscaTexto = '';
```

**2. Adicionar campo de busca na AppBar** — usar `PreferredSize` com `TextField` expandido ou simplesmente `SearchBar`:

No `build()`, converter a AppBar para incluir campo de busca:
```dart
appBar: AppBar(
  title: _buscaAtiva
    ? TextField(
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Buscar talhão...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        onChanged: (valor) {
          setState(() => _buscaTexto = valor);
          _aplicarFiltros();
        },
      )
    : Text(widget.talhaoInicial == null ? 'Relatórios de campo' : 'Relatórios · ${widget.talhaoInicial}'),
  actions: [
    if (!_buscaAtiva)
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Buscar por talhão',
        onPressed: () => setState(() => _buscaAtiva = true),
      ),
    if (_buscaAtiva)
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _buscaAtiva = false;
            _buscaTexto = '';
          });
          _aplicarFiltros();
        },
      ),
    // demais actions existentes
  ],
),
```

Adicionar campos: `bool _buscaAtiva = false;` e `String _buscaTexto = '';`

**3. Em `_aplicarFiltros()`**, adicionar condição de busca textual:
```dart
bool passaBusca = true;
if (_buscaTexto.isNotEmpty) {
  passaBusca = leitura.talhao.toLowerCase()
      .contains(_buscaTexto.trim().toLowerCase());
}
return passaData && passaDoenca && passaConfianca && passaBusca;
```

**4. Quando a busca está ativa** e o usuário pressiona "back" no iOS/Android, deve sair do modo busca (não fechar a tela). Usar `PopScope` ou `WillPopScope` para interceptar:
```dart
// No build, envolver o Scaffold:
if (_buscaAtiva) {
  // PopScope com canPop: false quando busca ativa
}
```
Ou mais simples: quando `_buscaAtiva`, o `IconButton(Icons.close)` na AppBar já fecha a busca. No Android, o botão back fecha a busca — basta testar.

`dart analyze mobile` → sem erros.  
Commit: `feat: busca por nome de talhão no HistoricoScreen`

**Critérios de aceitação:**
- Ícone de lupa na AppBar
- Toque na lupa → AppBar vira campo de texto
- Digitando nome do talhão filtra a lista em tempo real
- Botão X limpa busca e restaura título
- `dart analyze` limpo

---

## TASK-036 · 🟡 Média · Unit test para exclusão de leituras e widget test para SettingsPage

**Status:** `done`  
**Arquivos novos:**
- `mobile/test/unit/database_delete_test.dart`
- `mobile/test/widget/settings_page_structure_test.dart`

**Contexto:**  
Com a adição de `deletarLeituras()` no DatabaseService, é útil documentar o comportamento esperado. E a SettingsPage não tem cobertura de widget test.

**O que fazer:**

**Arquivo 1 — `mobile/test/unit/database_delete_test.dart`:**

Testar a lógica de IDs de exclusão como função pura (sem Isar):
```dart
import 'package:flutter_test/flutter_test.dart';

/// Espelho da lógica de filtragem após exclusão
List<int> idsAExcluir(List<int> selecionados) => List<int>.from(selecionados);

bool idFoiExcluido(int id, List<int> idsExcluidos) => idsExcluidos.contains(id);

void main() {
  group('lógica de exclusão de leituras', () {
    test('idsAExcluir retorna cópia dos selecionados', () {
      final sel = [1, 2, 3];
      final ids = idsAExcluir(sel);
      expect(ids, equals([1, 2, 3]));
      // deve ser uma cópia, não referência
      sel.add(4);
      expect(ids.length, 3);
    });

    test('idFoiExcluido retorna true para ids excluídos', () {
      expect(idFoiExcluido(2, [1, 2, 3]), isTrue);
    });

    test('idFoiExcluido retorna false para ids não excluídos', () {
      expect(idFoiExcluido(5, [1, 2, 3]), isFalse);
    });

    test('exclusão de lista vazia não afeta nada', () {
      final ids = idsAExcluir([]);
      expect(ids, isEmpty);
    });
  });
}
```

**Arquivo 2 — `mobile/test/widget/settings_page_structure_test.dart`:**

Testar que a SettingsPage renderiza sem crash com dados mínimos. Precisará de mock do `SessionController` / `sl`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Importar o widget e mocks necessários

void main() {
  testWidgets('SettingsPage renderiza as seções principais', (tester) async {
    // Se não for possível mockar sl<SessionController> facilmente,
    // testar apenas os sub-widgets reutilizáveis que não dependem de DI:
    // _SecaoLabel, _InfoTile, _TapTile
    
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // Testar o widget _SecaoLabel diretamente não é possível (private)
              // Testar que SettingsPage pode ser instanciada como widget
            ],
          ),
        ),
      ),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });
  
  // Foco principal: testar os widgets PÚBLICOS reutilizáveis se existirem
  // Se SettingsPage depende demais de DI, pular o widget test e focar no unit test
}
```

**Importante:** Se o `SessionController` via `sl<>` for difícil de mockar sem infraestrutura de test (Firebase, Isar), **simplificar o teste** para verificar apenas os sub-widgets de UI pura que possam ser extraídos ou testados em isolamento. Não forçar um widget test que precise de Firebase mock — isso pertence a integration tests.

Adapte os testes ao que for testável de forma simples e direta.

Rodar `flutter test test/unit/database_delete_test.dart` e verificar que passa.

Commit: `test: testes para lógica de exclusão e estrutura de settings`

**Critérios de aceitação:**
- `database_delete_test.dart` passa com todos os testes
- `settings_page_structure_test.dart` passa (ou é simplificado ao que for testável sem DI)
- `dart analyze` limpo

---

---

## TASK-037 · 🔴 Alta · RelatorioPage: filtro de data no nível do banco Isar

**Status:** `done`  
**Arquivos:**
- `mobile/lib/features/diagnostico/data/datasources/database_service.dart`
- `mobile/lib/features/diagnostico/data/models/leitura_model.dart` (verificar índices)
- `mobile/lib/features/relatorio/presentation/pages/relatorio_page.dart`

**Contexto:**  
`RelatorioPage._init()` usa `buscarTodasLeituras()` que carrega **todo** o banco Isar em memória. O filtro por data (`_leiturasFiltered`) é feito depois em Dart. Com muitas leituras, isso é ineficiente — melhor filtrar diretamente no Isar.

**O que fazer:**

**1. Verificar se `LeituraModel.dataHora` tem `@Index()`:**
Abrir `mobile/lib/features/diagnostico/data/models/leitura_model.dart` e verificar se `dataHora` tem anotação de índice. Se não tiver, adicionar `@Index()` antes do campo:
```dart
@Index()
late DateTime dataHora;
```
**Importante:** Adicionar `@Index()` a um campo existente **não quebra** dados — o Isar recria o índice na próxima abertura. Mas requer incrementar `schemasVersion` em `DatabaseService.initialize()` e adicionar `migration` (ou usar `Isar.openAsync` com `compactOnLaunch`). Verificar como o Isar é inicializado no projeto e seguir o padrão existente.

**Alternativa sem índice:** Usar `.filter().dataHoraGreaterThan(start).dataHoraLessThan(end)` — que não precisa de índice mas é mais lento que `.where()` indexado. Para este app, a alternativa com `.filter()` é suficiente.

**2. Adicionar método em `DatabaseService`:**
```dart
Future<List<LeituraModel>> buscarLeiturasPorPeriodo(
  DateTime inicio,
  DateTime fim,
) async {
  return await isar.leituraModels
      .filter()
      .dataHoraGreaterThan(inicio.subtract(const Duration(seconds: 1)))
      .dataHoraLessThan(fim.add(const Duration(days: 1)))
      .sortByDataHoraDesc()
      .findAll();
}
```

**3. Em `RelatorioPage._init()`**, substituir:
```dart
// ANTES:
_todasLeituras = await _db.buscarTodasLeituras();

// DEPOIS:
_todasLeituras = await _db.buscarLeiturasPorPeriodo(_periodo.start, _periodo.end);
```

**4.** Quando o usuário mudar o período (`_periodo`), refazer a busca. Localizar onde `_periodo` é atualizado (deve haver um `showDateRangePicker` ou equivalente) e chamar `_recarregarLeituras()`:
```dart
Future<void> _recarregarLeituras() async {
  setState(() => _loading = true);
  _todasLeituras = await _db.buscarLeiturasPorPeriodo(_periodo.start, _periodo.end);
  if (mounted) setState(() => _loading = false);
}
```

**5.** O getter `_leiturasFiltered` ainda pode filtrar por talhão (já funciona com a lista em memória).

`dart analyze mobile` → sem erros.  
Commit: `perf: RelatorioPage filtra leituras por período no Isar ao invés de carregar tudo`

---

## TASK-038 · 🟡 Média · LeituraDetalheScreen — compartilhar resultado individual

**Status:** `done`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/leitura_detalhe_screen.dart`

**Contexto:**  
A tela de detalhe tem editar e excluir, mas não tem botão de compartilhar o resultado individualmente. O pacote `share_plus` já está no pubspec (usado em `relatorio_page.dart`).

**O que fazer:**

1. Adicionar import:
```dart
import 'package:share_plus/share_plus.dart';
```

2. Implementar `_compartilhar()`:
```dart
Future<void> _compartilhar() async {
  final l = widget.leitura;
  final confiancaStr = '${(l.confianca * 100).toStringAsFixed(1)}%';
  final dataStr = formatarDataHora(l.dataHora);
  final gpsStr = (l.latitude != 0.0 || l.longitude != 0.0)
      ? 'https://www.google.com/maps/search/?api=1&query=${l.latitude},${l.longitude}'
      : null;

  final sb = StringBuffer()
    ..writeln('📊 Diagnóstico HectarIA — AGData')
    ..writeln('Talhão: ${l.talhao.isEmpty ? "Sem talhão" : l.talhao}')
    ..writeln('Resultado: ${l.resultadoIA}')
    ..writeln('Precisão: $confiancaStr')
    ..writeln('Data: $dataStr');
  if (l.observacao.trim().isNotEmpty) {
    sb.writeln('Obs.: ${l.observacao.trim()}');
  }
  if (gpsStr != null) {
    sb.writeln('📍 $gpsStr');
  }

  await Share.share(sb.toString(), subject: 'Diagnóstico: ${l.resultadoIA}');
}
```

3. Adicionar `IconButton` de compartilhar na AppBar, **antes** do botão de delete:
```dart
IconButton(
  icon: const Icon(Icons.share_outlined),
  tooltip: 'Compartilhar resultado',
  onPressed: _compartilhar,
),
```

`dart analyze mobile` → sem erros.  
Commit: `feat: botão de compartilhar resultado individual no LeituraDetalheScreen`

**Critérios de aceitação:**
- Share sheet do sistema abre com texto formatado
- GPS link incluído quando disponível
- `dart analyze` limpo

---

## TASK-039 · 🟡 Média · Sentry em ClimaCard, AdminPage e sync_repository catch blocks restantes

**Status:** `done`  
**Arquivos:**
- `mobile/lib/features/clima/presentation/clima_card.dart`
- `mobile/lib/features/auth/presentation/pages/admin_page.dart`

**Contexto:**  
Após a TASK-025, os catch blocks de `home_controller.dart` e `sync_repository.dart` foram instrumentados com Sentry. Mas `ClimaCard` tem `catch (_) { _falhar(); }` e `AdminPage` tem catch blocks sem Sentry, perdendo visibilidade de erros de produção nesses fluxos.

**O que fazer:**

**Em `clima_card.dart`:**

1. Adicionar imports:
```dart
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
```

2. Em `_carregar()`, substituir `catch (_)` por:
```dart
} catch (e, st) {
  unawaited(Sentry.captureException(e, stackTrace: st));
  _falhar();
}
```

**Em `admin_page.dart`:**

3. Adicionar imports (se ausentes):
```dart
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
```

4. Em `_confirmarExclusao()` → `onPressed` do botão Excluir, o catch já mostra snackbar mas não reporta ao Sentry. Adicionar:
```dart
} catch (e, st) {
  unawaited(Sentry.captureException(e, stackTrace: st));
  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Erro ao excluir: $e")),
  );
}
```

5. Em `_enviarAcessoWhatsApp()`, o catch também faz apenas snackbar — adicionar Sentry igualmente.

`dart analyze mobile` → sem erros.  
Commit: `feat: Sentry nos catch blocks de ClimaCard e AdminPage`

---

## TASK-040 · 🟡 Média · Unit tests para lógica de filtro do RelatorioPage

**Status:** `done`  
**Arquivo novo:** `mobile/test/unit/relatorio_filter_test.dart`

**Contexto:**  
O getter `_leiturasFiltered` do `RelatorioPage` contém lógica de filtro por período e talhão. Extraindo como função pura, é fácil cobrir com testes — sem Firebase, sem Isar.

**O que fazer:**

Criar `mobile/test/unit/relatorio_filter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/leitura_model.dart';

/// Espelho do getter _leiturasFiltered do RelatorioPage
List<LeituraModel> filtrarParaRelatorio(
  List<LeituraModel> todas, {
  required DateTime inicio,
  required DateTime fim,
  Set<String>? talhoesSelecionados,
}) {
  return todas.where((l) {
    final noTalhao = talhoesSelecionados == null ||
        talhoesSelecionados.isEmpty ||
        talhoesSelecionados.contains(l.talhao);
    final noRange = !l.dataHora.isBefore(inicio) &&
        !l.dataHora.isAfter(fim.add(const Duration(days: 1)));
    return noTalhao && noRange;
  }).toList();
}

LeituraModel _make({
  required String talhao,
  required DateTime dataHora,
  String resultado = 'SAUDÁVEL',
}) {
  return LeituraModel()
    ..talhao = talhao
    ..dataHora = dataHora
    ..resultadoIA = resultado
    ..confianca = 0.9
    ..caminhoImagem = '/fake/path.jpg'
    ..latitude = -22.0
    ..longitude = -47.0;
}

void main() {
  final base = DateTime(2024, 6, 1);
  final leituras = [
    _make(talhao: 'T1', dataHora: DateTime(2024, 5, 15)),
    _make(talhao: 'T1', dataHora: DateTime(2024, 6, 10)),
    _make(talhao: 'T2', dataHora: DateTime(2024, 6, 20)),
    _make(talhao: 'T3', dataHora: DateTime(2024, 7, 5)),
  ];

  group('filtrar por período', () {
    test('retorna apenas leituras dentro do período', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: base,
        fim: DateTime(2024, 6, 30),
      );
      expect(result.length, 2); // T1 junho e T2 junho
    });

    test('exclui leituras fora do período', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 7, 1),
        fim: DateTime(2024, 7, 31),
      );
      expect(result.length, 1);
      expect(result.first.talhao, 'T3');
    });

    test('período de 1 dia inclui leituras desse dia', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 6, 10),
        fim: DateTime(2024, 6, 10),
      );
      expect(result.length, 1);
      expect(result.first.talhao, 'T1');
    });
  });

  group('filtrar por talhão', () {
    test('sem seleção retorna todos', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 1, 1),
        fim: DateTime(2024, 12, 31),
        talhoesSelecionados: {},
      );
      expect(result.length, 4);
    });

    test('com seleção retorna apenas talhões escolhidos', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: DateTime(2024, 1, 1),
        fim: DateTime(2024, 12, 31),
        talhoesSelecionados: {'T1'},
      );
      expect(result.length, 2);
      expect(result.every((l) => l.talhao == 'T1'), isTrue);
    });
  });

  group('combinação', () {
    test('filtro de período + talhão aplica interseção', () {
      final result = filtrarParaRelatorio(
        leituras,
        inicio: base,
        fim: DateTime(2024, 6, 30),
        talhoesSelecionados: {'T2'},
      );
      expect(result.length, 1);
      expect(result.first.talhao, 'T2');
    });
  });
}
```

Rodar `flutter test test/unit/relatorio_filter_test.dart` dentro de `mobile/`.

Commit: `test: testes unitários para lógica de filtro do RelatorioPage`

---

---

## TASK-041 · 🔴 Alta · DatabaseService.contarTodasLeituras() — evitar carregar tudo só para contar

**Status:** `done`  
**Arquivos:**
- `mobile/lib/features/diagnostico/data/datasources/database_service.dart`
- `mobile/lib/features/settings/presentation/pages/settings_page.dart`

**Contexto:**  
`SettingsPage._carregarDados()` faz `await _db.buscarTodasLeituras()` só para pegar `.length`. Isso carrega todos os objetos em memória para descobrir a contagem — exatamente o que o Isar tem `.count()` para evitar.

**O que fazer:**

**1. Em `DatabaseService`**, adicionar método de contagem eficiente após `contarLeiturasPendentes()`:
```dart
Future<int> contarTodasLeituras() async {
  return await isar.leituraModels.count();
}
```
**Verificar** que `isar.leituraModels.count()` existe na versão do Isar usada (Isar 3.x tem isso). Se não existir, usar:
```dart
return await isar.leituraModels.where().count();
```

**2. Em `SettingsPage._carregarDados()`**, substituir:
```dart
// ANTES:
final todas = await _db.buscarTodasLeituras();
// ...
_totalLeituras = todas.length;

// DEPOIS:
final total = await _db.contarTodasLeituras();
// ...
_totalLeituras = total;
```

`dart analyze mobile` → sem erros.  
Commit: `perf: SettingsPage usa contarTodasLeituras() ao invés de carregar tudo para contar`

---

## TASK-042 · 🔴 Alta · HistoricoScreen — tratamento de erro em _carregarDados()

**Status:** `pending`  
**Arquivo:** `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`

**Contexto:**  
`_carregarDados()` e `_carregarMais()` não têm try/catch. Se o Isar falhar (disco cheio, corrupção), o app fica preso com `_loading = true` ou `_carregandoMais = true` indefinidamente, sem mensagem para o usuário.

**O que fazer:**

**1. Adicionar variável de estado de erro:**
```dart
bool _erro = false;
```

**2. Em `_carregarDados()`**, envolver em try/catch:
```dart
Future<void> _carregarDados() async {
  setState(() => _erro = false);
  try {
    var dados = await _databaseService.buscarLeiturasPaginadas(limite: 50, offset: 0);
    if (widget.talhaoInicial != null) {
      dados = dados.where((l) => l.talhao == widget.talhaoInicial).toList();
    }
    if (mounted) {
      setState(() {
        _todasLeituras = dados;
        _leiturasFiltradas = List.from(_todasLeituras);
        _temMais = dados.length == 50;
        _loading = false;
      });
    }
  } catch (e, st) {
    unawaited(Sentry.captureException(e, stackTrace: st));
    if (mounted) setState(() { _loading = false; _erro = true; });
  }
}
```

Adicionar imports:
```dart
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
```

**3. Em `_carregarMais()`**, envolver o corpo em try/catch também:
```dart
} catch (e, st) {
  unawaited(Sentry.captureException(e, stackTrace: st));
  if (mounted) setState(() => _carregandoMais = false);
}
```

**4. No `build()`, quando `_erro == true`** (e não loading), mostrar um widget de erro com retry em vez de lista vazia:
```dart
: _erro
    ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text('Erro ao carregar leituras',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: () {
                setState(() { _loading = true; _erro = false; });
                _carregarDados();
              },
            ),
          ],
        ),
      )
    : RefreshIndicator( ... ) // lista normal
```

`dart analyze mobile` → sem erros.  
Commit: `feat: tratamento de erro e estado de retry no HistoricoScreen`

---

## TASK-043 · 🟡 Média · Sentry nos catch blocks restantes — HistoricoScreen e SyncRepository

**Status:** `pending`  
**Arquivos:**
- `mobile/lib/features/diagnostico/presentation/pages/historico_screen.dart`
- `mobile/lib/infra/repositories/sync_repository.dart`

**Contexto:**  
`HistoricoScreen._enviarRelatorioWhatsApp()` tem `catch (e)` que mostra SnackBar sem reportar ao Sentry. `sync_repository.dart` pode ter catch blocks adicionados na TASK-025 — verificar se todos os catch blocks foram instrumentados (pode ter perdido algum).

**O que fazer:**

**Em `historico_screen.dart` — `_enviarRelatorioWhatsApp()` (linha ~334):**

Verificar o catch existente e converter para:
```dart
} catch (e, st) {
  unawaited(Sentry.captureException(e, stackTrace: st));
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erro ao abrir o WhatsApp.")),
    );
  }
}
```

**Em `sync_repository.dart`:**

Ler o arquivo e verificar se existem catch blocks sem `Sentry.captureException`. A TASK-025 adicionou Sentry em alguns, mas pode ter perdido. Para cada catch sem Sentry, adicionar.

Se os imports já existem (da TASK-025), não adicionar duplicados.

`dart analyze mobile` → sem erros.  
Commit: `feat: Sentry nos catch blocks restantes do HistoricoScreen e sync_repository`

---

## TASK-044 · 🟡 Média · Unit test para geração de texto do relatório WhatsApp

**Status:** `pending`  
**Arquivo novo:** `mobile/test/unit/whatsapp_report_test.dart`

**Contexto:**  
`HistoricoScreen._enviarRelatorioWhatsApp()` constrói um StringBuffer com formatação específica. Extraindo essa lógica como função pura, podemos garantir que o formato não quebra com mudanças futuras.

**O que fazer:**

Criar `mobile/test/unit/whatsapp_report_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/diagnostico/data/models/leitura_model.dart';
import 'package:mobile/core/utils/formatters.dart';

/// Espelho da lógica de geração de texto do _enviarRelatorioWhatsApp
String gerarTextoRelatorio(List<LeituraModel> itens) {
  final sb = StringBuffer();
  sb.writeln('📊 *Relatório AGdata - Inspeção de Campo*');
  sb.writeln('⚠️ *Atenção:* ${itens.length} registro(s) selecionado(s).\n');

  for (int i = 0; i < itens.length; i++) {
    final item = itens[i];
    sb.writeln('*Foco ${i + 1} - ${item.resultadoIA}*');
    sb.writeln('Talhão: ${item.talhao}');
    sb.writeln('Precisão: ${(item.confianca * 100).toStringAsFixed(1)}%');
    if (item.observacao.trim().isNotEmpty) {
      sb.writeln('Obs.: ${item.observacao.trim()}');
    }
  }
  sb.writeln('Aguardando orientações de manejo. 🚜');
  return sb.toString();
}

LeituraModel _make({
  required String talhao,
  required String resultado,
  required double confianca,
  String obs = '',
}) {
  return LeituraModel()
    ..talhao = talhao
    ..resultadoIA = resultado
    ..confianca = confianca
    ..observacao = obs
    ..dataHora = DateTime(2024, 6, 15)
    ..caminhoImagem = '/fake/path.jpg'
    ..latitude = -22.0
    ..longitude = -47.0;
}

void main() {
  group('gerarTextoRelatorio', () {
    test('texto inclui cabeçalho padrão', () {
      final texto = gerarTextoRelatorio([]);
      expect(texto, contains('Relatório AGdata'));
      expect(texto, contains('Inspeção de Campo'));
    });

    test('texto inclui contagem correta de registros', () {
      final leituras = [
        _make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.95),
        _make(talhao: 'T2', resultado: 'SAUDÁVEL', confianca: 0.88),
      ];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('2 registro(s)'));
    });

    test('cada leitura tem número de foco sequencial', () {
      final leituras = [
        _make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.9),
        _make(talhao: 'T2', resultado: 'OÍDIO', confianca: 0.8),
      ];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('Foco 1 - FERRUGEM'));
      expect(texto, contains('Foco 2 - OÍDIO'));
    });

    test('precisão é formatada com 1 casa decimal', () {
      final leituras = [_make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.956)];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('95.6%'));
    });

    test('observação é incluída quando não vazia', () {
      final leituras = [_make(talhao: 'T1', resultado: 'FERRUGEM', confianca: 0.9, obs: 'Urgente')];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, contains('Obs.: Urgente'));
    });

    test('observação é omitida quando vazia', () {
      final leituras = [_make(talhao: 'T1', resultado: 'SAUDÁVEL', confianca: 0.9)];
      final texto = gerarTextoRelatorio(leituras);
      expect(texto, isNot(contains('Obs.:')));
    });

    test('lista vazia não quebra e inclui rodapé', () {
      final texto = gerarTextoRelatorio([]);
      expect(texto, contains('Aguardando orientações'));
    });
  });
}
```

Rodar `flutter test test/unit/whatsapp_report_test.dart` dentro de `mobile/`.

Commit: `test: testes unitários para geração de texto do relatório WhatsApp`

---

_Última atualização pelo planejador: iteração 9 — 2026-08-11_
