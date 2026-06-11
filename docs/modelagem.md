# Modelagem das Expressões Regulares

Este documento descreve cada expressão regular utilizada no reconhecedor, detalhando os critérios adotados e os casos cobertos.

---

## 1. Horários

Três expressões regulares cooperam para reconhecer horários, cobrindo formatos distintos sem gerar duplicatas.

### 1.1 Horário com minutos — `REGEX_HORA_COM_MINUTO`

```ruby
/\b(?:às|as)?\s*(\d{1,2})(?::|\s+)(\d{2})\b/i
```

| Componente | Função |
|---|---|
| `\b` | Limite de palavra — evita capturar partes de números maiores |
| `(?:às\|as)?` | Preposição opcional antes do horário |
| `\s*` | Espaço opcional entre preposição e dígitos |
| `(\d{1,2})` | Captura as horas (1 ou 2 dígitos) |
| `(?::\|\s+)` | Separador: dois-pontos **ou** espaço |
| `(\d{2})` | Captura os minutos (exatamente 2 dígitos) |
| `\b` | Limite de palavra no final |

**Casos cobertos:** `10:30`, `10 30`, `às 10:30`, `as 9:05`

### 1.2 Horário por extenso — `REGEX_HORA_POR_EXTENSO`

```ruby
/\b(\d{1,2})\s*(?:h|hora|horas)\b/i
```

| Componente | Função |
|---|---|
| `(\d{1,2})` | Captura o número da hora |
| `\s*` | Espaço opcional entre número e unidade |
| `(?:h\|hora\|horas)` | Unidade de tempo por extenso ou abreviada |

**Casos cobertos:** `10 horas`, `1 hora`, `10h`, `9h`

### 1.3 Preposição sem minutos — `REGEX_AS_HORA`

```ruby
/\b(?:às|as)\s*(\d{1,2})\b(?!\s*(?::|\d))/i
```

| Componente | Função |
|---|---|
| `(?:às\|as)` | Preposição obrigatória (distingue de simples números) |
| `(\d{1,2})` | Captura a hora |
| `(?!\s*(?::\|\d))` | Lookahead negativo: rejeita se vier dois-pontos ou outro dígito (evita duplicar com `REGEX_HORA_COM_MINUTO`) |

**Casos cobertos:** `às 10`, `as 9`

**Deduplificação:** ao processar, `REGEX_AS_HORA` e `REGEX_HORA_POR_EXTENSO` só adicionam uma hora se ela ainda não foi encontrada por `REGEX_HORA_COM_MINUTO`. Ao final, `.uniq` elimina eventuais remanescentes.

---

## 2. Datas

### 2.1 Data relativa — `REGEX_DATA_RELATIVA`

```ruby
/(?<![\p{L}])(hoje|amanh[ãa]|depois de amanh[ãa])(?![\p{L}])/iu
```

| Componente | Função |
|---|---|
| `(?<![\p{L}])` | Lookbehind negativo: não pode vir precedido de letra Unicode |
| `(hoje\|amanh[ãa]\|depois de amanh[ãa])` | Termos relativos; `[ãa]` aceita com e sem acento |
| `(?![\p{L}])` | Lookahead negativo: não pode ser seguido de letra |
| Flag `u` | Ativa suporte Unicode para `\p{L}` |

Após o reconhecimento, o termo é convertido para data absoluta usando `Date.today`:
- `hoje` → data atual
- `amanhã` → data atual + 1
- `depois de amanhã` → data atual + 2

**Casos cobertos:** `hoje`, `amanhã`, `amanha`, `depois de amanhã`

### 2.2 Data numérica — `REGEX_DATA_NUMERICA`

```ruby
%r{\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b}
```

| Componente | Função |
|---|---|
| `(\d{1,2})` | Dia (1 ou 2 dígitos) |
| `/` | Separador obrigatório |
| `(\d{1,2})` | Mês (1 ou 2 dígitos) |
| `(?:/(\d{2,4}))?` | Ano opcional (2 ou 4 dígitos) |

Quando o ano é omitido, usa-se o ano corrente. Anos de 2 dígitos recebem o prefixo `2000` (ex.: `25` → `2025`).

**Casos cobertos:** `30/01`, `20/04/2022`, `1/3/25`

### 2.3 Data por extenso — `REGEX_DATA_TEXTUAL`

```ruby
/\b(\d{1,2})\s*(?:de\s+)?(janeiro|fevereiro|mar[çc]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*(?:de\s+)?(\d{4})?\b/i
```

| Componente | Função |
|---|---|
| `(\d{1,2})` | Dia |
| `\s*(?:de\s+)?` | Preposição "de" opcional antes do mês |
| `(janeiro\|...\|mar[çc]o\|...)` | Nome do mês; `mar[çc]o` aceita com e sem cedilha |
| `\s*(?:de\s+)?` | Preposição "de" opcional antes do ano |
| `(\d{4})?` | Ano de 4 dígitos, opcional |

A conversão numérica do nome do mês usa o dicionário `MESES`, que mapeia ambas as grafias de "março"/"marco".

**Casos cobertos:** `28 de Fevereiro`, `13 de agosto de 2021`, `18 agosto`, `18 de agosto 2023`, `30 de junho`

---

## 3. Tags

### `REGEX_TAG`

```ruby
/(?<![^\s])#[\p{L}\p{N}_-]+/u
```

| Componente | Função |
|---|---|
| `(?<![^\s])` | Lookbehind: o `#` deve estar precedido de espaço ou início de string (equivale a "não precedido de não-espaço") |
| `#` | Símbolo literal de tag |
| `[\p{L}\p{N}_-]+` | Um ou mais letras, dígitos, underscores ou hifens Unicode |

O texto é pré-processado com remoção de URLs antes da busca, impedindo que fragmentos como `#secao` dentro de `https://site.com/pag#secao` sejam capturados como tags.

**Casos cobertos:** `#casa`, `#trabalho`, `#minha-tarefa`, `#item_2`

---

## 4. URLs

### `REGEX_URL`

```ruby
%r{https?://[^\s]+}i
```

| Componente | Função |
|---|---|
| `https?` | Protocolo HTTP ou HTTPS |
| `://` | Separador de protocolo |
| `[^\s]+` | Qualquer caractere que não seja espaço — captura caminhos, âncoras, query strings |

**Casos cobertos:** `https://sp.senac.br/pag1#teste?aula=1&teste=4`, `http://example.com`

---

## 5. Emails

### `REGEX_EMAIL`

```ruby
/\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b/
```

| Componente | Função |
|---|---|
| `[A-Za-z0-9._%+\-]+` | Parte local: letras, dígitos, ponto, underscore, porcentagem, sinal de mais e hífen |
| `@` | Arroba literal |
| `[A-Za-z0-9.\-]+` | Domínio: letras, dígitos, ponto e hífen |
| `\.` | Ponto antes do TLD |
| `[A-Za-z]{2,}` | TLD com 2 ou mais letras |

O texto também é pré-processado para remover URLs, evitando falsos positivos em domínios que contenham `@` em query strings.

**Casos cobertos:** `jose.da-silva@sp.senac.br`, `user@example.com`, `contato+info@empresa.org`

---

## 6. Ações

### `REGEX_ACAO`

```ruby
/\b(agendar|marcar|ligar|comprar|pagar|enviar|estudar|revisar|entregar|fazer|buscar|levar|reuniao|reunião|cancelar|confirmar|reservar|anotar|lembrar|responder)\b/i
```

O padrão é gerado dinamicamente a partir da lista `ACOES` com `ACOES.join('|')`. O uso de `\b` garante que apenas palavras completas sejam reconhecidas (ex.: "fazer" em "desfazer" não é capturado). A flag `i` torna o reconhecimento insensível a maiúsculas.

**Casos cobertos:** `Agendar`, `marcar`, `LIGAR`, `reunião`, `reuniao`

---

## 7. Pessoas

### `REGEX_NOME`

```ruby
/[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+(?:\s+(?:de|da|do|dos|das)\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+|\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+)*/u
```

Reconhece nomes próprios iniciados obrigatoriamente por letra maiúscula acentuada ou não, seguidos de uma ou mais letras. Aceita nomes compostos separados por preposições (`de`, `da`, `do`, `dos`, `das`) ou por espaço com nova letra maiúscula.

**Casos cobertos:** `José`, `Maria`, `Ana Paula`, `João de Souza`

### `REGEX_PESSOA`

```ruby
/(?i:\b(?:com|para|pra|ao|à))\s+(REGEX_NOME(?:\s+e\s+REGEX_NOME)*)/u
```

| Componente | Função |
|---|---|
| `(?i:\b(?:com\|para\|pra\|ao\|à))` | Conector relacional insensível a maiúsculas |
| `\s+` | Espaço separador |
| `(REGEX_NOME(?:\s+e\s+REGEX_NOME)*)` | Um ou mais nomes separados por "e" |

Múltiplas pessoas separadas por "e" são divididas no pós-processamento com `.split(/\s+e\s+/i)`.

**Casos cobertos:** `com Pedro`, `para Maria`, `pra José e Ana`, `reunião com Pedro e João`