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

**Status:** `pending`  
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

_Última atualização pelo planejador: iteração 3 — 2026-08-11_
