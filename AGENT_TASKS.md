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

**Status:** `pending`  
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

**Status:** `pending`  
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

**Status:** `pending`  
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

**Status:** `pending`  
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

**Status:** `pending`  
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

_Última atualização pelo planejador: iteração 1 — 2026-08-11_
