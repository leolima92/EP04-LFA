# Modelagem das Expressões Regulares

## Fundamento teórico

Expressões regulares descrevem exatamente a classe das **linguagens regulares** — o menor nível da Hierarquia de Chomsky. Toda expressão regular possui um autômato finito equivalente (NFA/DFA) que aceita exatamente a mesma linguagem, resultado direto do Teorema de Kleene.

Neste projeto cada categoria de informação (horário, data, tag, etc.) é tratada como uma linguagem regular independente. O motor de regex do Ruby (Onigmo) atua como o reconhecedor: dado um padrão, ele constrói internamente um NFA que percorre a cadeia de entrada e aceita as subcadeias que pertencem àquela linguagem. O programador descreve *o que* deve ser reconhecido; o motor decide *como* percorrer o texto — sem loops manuais nem concatenação de substrings.

---

## 1. Horários

Três expressões regulares cooperam para cobrir todos os formatos exigidos sem gerar duplicatas.

### 1.1 `REGEX_HORA_COM_MINUTO`

```
/\b(?:às|as)?\s*(\d{1,2})(?::|\s+)(\d{2})\b/i
```

| Fragmento | Papel no autômato |
|---|---|
| `\b` | Transição de estado "fora de palavra" → "início de token" |
| `(?:às\|as)?` | Arco epsilon opcional para a preposição |
| `\s*` | Laço epsilon sobre espaços entre preposição e dígito |
| `(\d{1,2})` | Estado de captura das horas — aceita 1 ou 2 dígitos |
| `(?::\|\s+)` | Bifurcação: separador dois-pontos **ou** espaço(s) |
| `(\d{2})` | Estado de captura dos minutos — exige exatamente 2 dígitos |
| `\b` | Transição "fim de token" |

**Grupos capturados e saída:**

| Entrada | Grupo 1 (hora) | Grupo 2 (min) | Saída formatada |
|---|---|---|---|
| `10:30` | `10` | `30` | `10:30` |
| `9 05` | `9` | `05` | `09:05` |
| `às 14:00` | `14` | `00` | `14:00` |
| `as 8 30` | `8` | `30` | `08:30` |

**Casos cobertos:** dois-pontos, espaço, com ou sem preposição.

**Casos intencionalmente não cobertos:** horários como `2400`, `99:99` — capturados pela regex mas rejeitados como datas inválidas no pós-processamento, se necessário.

---

### 1.2 `REGEX_HORA_POR_EXTENSO`

```
/\b(\d{1,2})\s*(?:h|hora|horas)\b/i
```

| Fragmento | Papel |
|---|---|
| `(\d{1,2})` | Captura o número da hora |
| `\s*` | Espaço opcional entre número e unidade |
| `(?:h\|hora\|horas)` | União de três palavras-chave para a unidade |

**Grupos capturados e saída:**

| Entrada | Grupo 1 | Saída |
|---|---|---|
| `10 horas` | `10` | `10:00` |
| `1 hora` | `1` | `01:00` |
| `9h` | `9` | `09:00` |

---

### 1.3 `REGEX_AS_HORA`

```
/\b(?:às|as)\s*(\d{1,2})\b(?!\s*(?::|\d))/i
```

A preposição é **obrigatória** aqui. O lookahead negativo `(?!\s*(?::|\d))` rejeita o match se vier dois-pontos ou outro dígito, evitando duplicar com `REGEX_HORA_COM_MINUTO`.

**Grupos capturados e saída:**

| Entrada | Lookahead rejeita? | Grupo 1 | Saída |
|---|---|---|---|
| `às 10` | Não — próximo é letra | `10` | `10:00` |
| `às 10:30` | Sim — próximo é `:` | — | (não captura, REGEX_HORA_COM_MINUTO assume) |
| `às 9 45` | Sim — próximo é dígito | — | (idem) |

**Deduplificação:** ao processar, `REGEX_AS_HORA` e `REGEX_HORA_POR_EXTENSO` só adicionam um horário se ele ainda não constar na lista parcial. `Array#uniq` elimina eventuais remanescentes.

---

## 2. Datas

### 2.1 `REGEX_DATA_RELATIVA`

```
/(?<![\p{L}])(hoje|amanh[ãa]|depois de amanh[ãa])(?![\p{L}])/iu
```

| Fragmento | Papel |
|---|---|
| `(?<![\p{L}])` | Lookbehind negativo: rejeita se precedido por letra Unicode |
| `(hoje\|amanh[ãa]\|depois de amanh[ãa])` | União dos três termos; `[ãa]` cobre acento e ausência |
| `(?![\p{L}])` | Lookahead negativo: rejeita se seguido por letra |
| Flag `u` | Ativa `\p{L}` para Unicode |

Após o reconhecimento, o termo capturado é convertido para data absoluta com `Date.today`:

| Termo capturado | Cálculo | Saída (exemplo) |
|---|---|---|
| `hoje` | `Date.today` | `11/06/2026` |
| `amanhã` / `amanha` | `Date.today + 1` | `12/06/2026` |
| `depois de amanhã` | `Date.today + 2` | `13/06/2026` |

**Limitação declarada:** não reconhece formas como "na próxima semana" ou "em dois dias" — escapam da classe das linguagens regulares quando envolvem aritmética arbitrária.

---

### 2.2 `REGEX_DATA_NUMERICA`

```
%r{\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b}
```

| Fragmento | Papel |
|---|---|
| `(\d{1,2})` | Dia — 1 ou 2 dígitos |
| `/` | Separador literal obrigatório |
| `(\d{1,2})` | Mês — 1 ou 2 dígitos |
| `(?:/(\d{2,4}))?` | Ano opcional — 2 ou 4 dígitos |

Quando o ano é omitido, usa-se `Date.today.year`. Anos de 2 dígitos recebem prefixo `2000`.

**Grupos capturados e saída:**

| Entrada | G1 dia | G2 mês | G3 ano | Saída |
|---|---|---|---|---|
| `30/01` | `30` | `01` | `nil` | `30/01/2026` |
| `20/04/2022` | `20` | `04` | `2022` | `20/04/2022` |
| `1/3/25` | `1` | `3` | `25` | `01/03/2025` |

**Validação:** `Date.new` levanta `ArgumentError` para datas inválidas (ex.: `31/02`); o `rescue` descarta silenciosamente.

---

### 2.3 `REGEX_DATA_TEXTUAL`

```
/\b(\d{1,2})\s*(?:de\s+)?(janeiro|fevereiro|mar[çc]o|...|dezembro)\s*(?:de\s+)?(\d{4})?\b/i
```

| Fragmento | Papel |
|---|---|
| `(\d{1,2})` | Dia |
| `\s*(?:de\s+)?` | Preposição "de" opcional antes do mês |
| `(janeiro\|...\|mar[çc]o)` | Nome do mês; `mar[çc]o` aceita cedilha ou 'c' |
| `\s*(?:de\s+)?` | Preposição "de" opcional antes do ano |
| `(\d{4})?` | Ano de 4 dígitos, opcional |

**Grupos capturados e saída:**

| Entrada | G1 dia | G2 mês | G3 ano | Saída |
|---|---|---|---|---|
| `28 de Fevereiro` | `28` | `fevereiro` | `nil` | `28/02/2026` |
| `13 de agosto de 2021` | `13` | `agosto` | `2021` | `13/08/2021` |
| `18 agosto` | `18` | `agosto` | `nil` | `18/08/2026` |
| `18 de agosto 2023` | `18` | `agosto` | `2023` | `18/08/2023` |

A conversão mês → número usa o dicionário `MESES`, que registra ambas as grafias de `março`/`marco`.

---

## 3. Tags

### `REGEX_TAG`

```
/(?<![^\s])#[\p{L}\p{N}_-]+/u
```

| Fragmento | Papel |
|---|---|
| `(?<![^\s])` | Lookbehind: `#` deve ser precedido por espaço ou início de cadeia |
| `#` | Delimitador literal da tag |
| `[\p{L}\p{N}_-]+` | Um ou mais letras, dígitos, underscores ou hifens Unicode |

**Por que o lookbehind `(?<![^\s])`?**
A negação dupla (`não precedido de não-espaço`) equivale a "precedido de espaço ou início de string". Isso impede que fragmentos como `#secao` dentro de `https://site.com/pagina#secao` sejam capturados como tags.

Adicionalmente, o texto passa por `gsub(REGEX_URL, '')` antes da varredura, removendo URLs completas.

**Exemplos:**

| Entrada | Saída |
|---|---|
| `#casa` | `#casa` |
| `#minha-tarefa_2` | `#minha-tarefa_2` |
| `https://site.com#ancora` | *(não captura — URL removida antes)* |

---

## 4. URLs

### `REGEX_URL`

```
%r{https?://[^\s]+}i
```

| Fragmento | Papel |
|---|---|
| `https?` | Protocolo HTTP ou HTTPS (`s?` torna o 's' opcional) |
| `://` | Separador de protocolo |
| `[^\s]+` | Qualquer sequência não-espaço — captura caminho, âncora e query string inteiros |

**Exemplos:**

| Entrada | Saída |
|---|---|
| `https://sp.senac.br/pag1#teste?aula=1&teste=4` | `https://sp.senac.br/pag1#teste?aula=1&teste=4` |
| `http://example.com` | `http://example.com` |

---

## 5. Emails

### `REGEX_EMAIL`

```
/\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b/
```

| Fragmento | Papel |
|---|---|
| `[A-Za-z0-9._%+\-]+` | Parte local: letras, dígitos e os símbolos `._%+-` |
| `@` | Arroba literal obrigatória |
| `[A-Za-z0-9.\-]+` | Domínio: letras, dígitos, ponto e hífen |
| `\.[A-Za-z]{2,}` | TLD obrigatório com 2+ letras |

**Exemplos:**

| Entrada | Saída |
|---|---|
| `jose.da-silva@sp.senac.br` | `jose.da-silva@sp.senac.br` |
| `contato+info@empresa.org` | `contato+info@empresa.org` |
| `user@example.com` | `user@example.com` |

O texto também é pré-processado com remoção de URLs para evitar falsos positivos em endereços que contenham `@` em query strings.

---

## 6. Ações

### `REGEX_ACAO`

```ruby
ACOES = %w[agendar marcar ligar comprar pagar enviar estudar revisar entregar
           fazer buscar levar reuniao reunião cancelar confirmar reservar
           anotar lembrar responder]

REGEX_ACAO = /\b(#{ACOES.join('|')})\b/i
```

O padrão é gerado dinamicamente com `join('|')`, formando uma **união de linguagens regulares** — cada verbo é uma linguagem singleton, e a união de linguagens regulares é também regular.

`\b` garante que apenas palavras completas sejam aceitas: `fazer` em `desfazer` não é capturado.

**Exemplos:**

| Entrada | Saída |
|---|---|
| `Agendar reunião` | `agendar`, `reunião` |
| `LIGAR para alguém` | `ligar` |
| `desfazer algo` | *(não captura — `\b` rejeita)* |

---

## 7. Pessoas

### `REGEX_NOME`

```
/[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+(?:\s+(?:de|da|do|dos|das)\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+|\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+)*/u
```

| Fragmento | Papel |
|---|---|
| `[A-ZÁÉÍÓÚÂÊÔÃÕÇ]` | Primeira letra maiúscula — própria ou acentuada |
| `[\p{L}]+` | Restante do nome — qualquer letra Unicode |
| `(?:\s+(?:de\|da\|do\|dos\|das)\s+[A-Z...])` | Partícula nobiliária + próximo nome próprio |
| `(\s+[A-Z...])*` | Zero ou mais palavras adicionais com maiúscula |

### `REGEX_PESSOA`

```
/(?i:\b(?:com|para|pra|ao|à))\s+(REGEX_NOME(?:\s+e\s+REGEX_NOME)*)/u
```

| Fragmento | Papel |
|---|---|
| `(?i:\b(?:com\|para\|pra\|ao\|à))` | Conector relacional — identifica que uma pessoa virá a seguir |
| `\s+` | Separador obrigatório |
| `(REGEX_NOME(?:\s+e\s+REGEX_NOME)*)` | Um ou mais nomes ligados por "e" |

Após a captura, `split(/\s+e\s+/i)` divide o grupo em nomes individuais.

**Exemplos:**

| Entrada | Saída |
|---|---|
| `com José` | `José` |
| `para Maria de Souza` | `Maria de Souza` |
| `pra Pedro e João` | `Pedro`, `João` |
| `reunião com Ana Clara e Paulo` | `Ana Clara`, `Paulo` |

---

## 8. Interação entre padrões

Dois padrões podem conflitar com outros se aplicados diretamente ao texto bruto:

| Conflito | Solução adotada |
|---|---|
| `#ancora` dentro de URL sendo capturado como tag | URL removida via `gsub(REGEX_URL, '')` antes de `scan(REGEX_TAG)` |
| Email dentro de URL sendo capturado como email | URL removida antes de `scan(REGEX_EMAIL)` |
| `REGEX_AS_HORA` e `REGEX_HORA_COM_MINUTO` capturando o mesmo horário | Lookahead negativo em `REGEX_AS_HORA` + verificação `include?` ao inserir na lista |