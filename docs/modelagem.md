# Modelagem das Expressões Regulares

Este documento apresenta a modelagem das expressões regulares utilizadas no projeto **Reconhecedor de Lista de Afazeres**.

O sistema recebe uma frase digitada pelo usuário e reconhece, por meio de expressões regulares em Ruby, elementos relevantes de uma tarefa, como:

* horários;
* datas;
* pessoas;
* ações;
* tags;
* URLs;
* emails.

A implementação utiliza expressões regulares em Ruby com o método `scan` para localizar padrões dentro da entrada textual. Não foram utilizadas gems ou bibliotecas externas para reconhecimento automático de datas.

---

## 1. Fundamento teórico

Expressões regulares são uma forma de representar padrões textuais pertencentes à classe das **linguagens regulares**.

Na teoria de Linguagens Formais, toda expressão regular possui um **autômato finito equivalente** capaz de reconhecer a mesma linguagem. Dessa forma, cada expressão regular definida neste projeto pode ser entendida como um reconhecedor específico para uma categoria de informação.

Neste trabalho, cada categoria foi modelada como uma linguagem regular independente:

* a linguagem dos horários;
* a linguagem das datas;
* a linguagem das tags;
* a linguagem dos emails;
* a linguagem das URLs;
* a linguagem das ações;
* a linguagem dos nomes de pessoas.

O uso de expressões regulares torna a solução declarativa, pois o programa descreve o formato esperado de cada padrão, sem precisar percorrer manualmente a string caractere por caractere.

---

## 2. Horários

Os horários são reconhecidos por três expressões regulares diferentes, pois o enunciado exige formatos variados.

Formatos cobertos:

```txt
10:30
10 30
10 horas
1 hora
às 10
```

---

### 2.1 Horário com minuto

Expressão regular:

```ruby
REGEX_HORA_COM_MINUTO = /\b(?:às|as)?\s*(\d{1,2})(?::|\s+)(\d{2})\b/i
```

Essa expressão reconhece horários com dois-pontos ou com espaço entre hora e minuto.

Exemplos aceitos:

```txt
10:30
9:05
10 30
às 14:00
as 8 30
```

Explicação dos principais trechos:

| Trecho        | Função                                             |
| ------------- | -------------------------------------------------- |
| `\b`          | Marca o início de uma palavra ou token             |
| `(?:às\|as)?` | Aceita opcionalmente `às` ou `as` antes do horário |
| `\s*`         | Aceita zero ou mais espaços                        |
| `(\d{1,2})`   | Captura a hora com 1 ou 2 dígitos                  |
| `(?::\|\s+)`  | Aceita dois-pontos ou espaço como separador        |
| `(\d{2})`     | Captura os minutos com exatamente 2 dígitos        |
| `i`           | Permite letras maiúsculas ou minúsculas            |

Exemplo:

```txt
Entrada: reunião às 10:30
Hora capturada: 10
Minuto capturado: 30
Saída: 10:30
```

---

### 2.2 Horário por extenso

Expressão regular:

```ruby
REGEX_HORA_POR_EXTENSO = /\b(\d{1,2})\s*(?:h|hora|horas)\b/i
```

Essa expressão reconhece horários escritos com `h`, `hora` ou `horas`.

Exemplos aceitos:

```txt
10 horas
1 hora
9h
```

Explicação dos principais trechos:

| Trecho               | Função                                            |
| -------------------- | ------------------------------------------------- |
| `\b`                 | Marca o início do token                           |
| `(\d{1,2})`          | Captura a hora                                    |
| `\s*`                | Aceita espaço opcional entre o número e a palavra |
| `(?:h\|hora\|horas)` | Aceita as formas `h`, `hora` ou `horas`           |
| `\b`                 | Marca o fim do token                              |
| `i`                  | Ignora diferença entre maiúsculas e minúsculas    |

Exemplo:

```txt
Entrada: ligar para Ana 1 hora
Hora capturada: 1
Saída: 01:00
```

---

### 2.3 Horário com "às"

Expressão regular:

```ruby
REGEX_AS_HORA = /\b(?:às|as)\s*(\d{1,2})\b(?!\s*(?::|\d))/i
```

Essa expressão reconhece horários no formato:

```txt
às 10
as 8
```

Ela exige que a palavra `às` ou `as` apareça antes da hora.

O trecho abaixo evita que o mesmo horário seja capturado duas vezes quando já existe minuto:

```ruby
(?!\s*(?::|\d))
```

Esse trecho é um **lookahead negativo**. Ele verifica se, depois da hora, não vem dois-pontos nem outro número. Assim, `às 10:30` é reconhecido pela regex de horário com minuto, e não por esta.

Exemplos:

| Entrada    | Resultado                                                         |
| ---------- | ----------------------------------------------------------------- |
| `às 10`    | `10:00`                                                           |
| `as 8`     | `08:00`                                                           |
| `às 10:30` | Não captura aqui, pois é tratado pela regex de horário com minuto |

---

### 2.4 Validação e normalização dos horários

As expressões regulares identificam candidatos a horário. Depois da captura, o método `formatar_horario` valida se o horário realmente existe.

```ruby
def formatar_horario(hora, minuto)
  return nil unless hora.between?(0, 23)
  return nil unless minuto.between?(0, 59)

  format('%02d:%02d', hora, minuto)
end
```

Esse método tem três funções:

1. verificar se a hora está entre `0` e `23`;
2. verificar se o minuto está entre `0` e `59`;
3. formatar a saída no padrão `HH:MM`.

Exemplos:

| Entrada  | Resultado  |
| -------- | ---------- |
| `10:30`  | `10:30`    |
| `9 05`   | `09:05`    |
| `às 10`  | `10:00`    |
| `1 hora` | `01:00`    |
| `25:00`  | descartado |
| `99:99`  | descartado |
| `10:80`  | descartado |

---

## 3. Datas

As datas são reconhecidas em três grupos:

1. datas relativas;
2. datas numéricas;
3. datas textuais.

Formatos cobertos:

```txt
hoje
amanhã
depois de amanhã
30/01
20/04/2022
28 de Fevereiro
13 de agosto de 2021
18 agosto
18 de agosto 2023
```

---

### 3.1 Datas relativas

Expressão regular:

```ruby
REGEX_DATA_RELATIVA = /(?<![\p{L}])(hoje|amanh[ãa]|depois de amanh[ãa])(?![\p{L}])/iu
```

Essa expressão reconhece:

```txt
hoje
amanhã
amanha
depois de amanhã
depois de amanha
```

Explicação dos principais trechos:

| Trecho                                   | Função                                                |
| ---------------------------------------- | ----------------------------------------------------- |
| `(?<![\p{L}])`                           | Garante que antes da palavra não exista uma letra     |
| `(hoje\|amanh[ãa]\|depois de amanh[ãa])` | Reconhece as opções de datas relativas                |
| `[ãa]`                                   | Aceita a palavra com ou sem acento                    |
| `(?![\p{L}])`                            | Garante que depois da palavra não exista uma letra    |
| `i`                                      | Ignora maiúsculas e minúsculas                        |
| `u`                                      | Permite trabalhar corretamente com caracteres Unicode |

Após reconhecer o termo, o programa converte para uma data real usando `Date.today`.

Exemplo considerando a execução em `11/06/2026`:

| Entrada            | Cálculo          | Resultado    |
| ------------------ | ---------------- | ------------ |
| `hoje`             | `Date.today`     | `11/06/2026` |
| `amanhã`           | `Date.today + 1` | `12/06/2026` |
| `depois de amanhã` | `Date.today + 2` | `13/06/2026` |

A data exibida depende da data atual do computador no momento da execução.

---

### 3.2 Datas numéricas

Expressão regular:

```ruby
REGEX_DATA_NUMERICA = %r{\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b}
```

Essa expressão reconhece datas no formato numérico.

Exemplos aceitos:

```txt
30/01
20/04/2022
1/3/25
```

Explicação dos principais trechos:

| Trecho            | Função                                     |
| ----------------- | ------------------------------------------ |
| `\b`              | Marca o início do token                    |
| `(\d{1,2})`       | Captura o dia com 1 ou 2 dígitos           |
| `/`               | Separador obrigatório                      |
| `(\d{1,2})`       | Captura o mês com 1 ou 2 dígitos           |
| `(?:/(\d{2,4}))?` | Captura o ano opcional, com 2 ou 4 dígitos |
| `\b`              | Marca o fim do token                       |

Quando o ano não é informado, o programa usa o ano atual.

Quando o ano tem apenas dois dígitos, o programa considera o século 2000.

Exemplos considerando o ano atual como 2026:

| Entrada      | Dia  | Mês  | Ano    | Resultado    |
| ------------ | ---- | ---- | ------ | ------------ |
| `30/01`      | `30` | `01` | `2026` | `30/01/2026` |
| `20/04/2022` | `20` | `04` | `2022` | `20/04/2022` |
| `1/3/25`     | `1`  | `3`  | `2025` | `01/03/2025` |

A validação da data é feita com `Date.new`. Se a data for inválida, ela é ignorada.

Exemplo:

```txt
31/02
```

Essa data é descartada, pois fevereiro não possui 31 dias.

---

### 3.3 Datas textuais

Expressão regular:

```ruby
REGEX_DATA_TEXTUAL = /\b(\d{1,2})\s*(?:de\s+)?(janeiro|fevereiro|mar[çc]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*(?:de\s+)?(\d{4})?\b/i
```

Essa expressão reconhece datas escritas com o nome do mês.

Exemplos aceitos:

```txt
28 de Fevereiro
13 de agosto de 2021
18 agosto
18 de agosto 2023
```

Explicação dos principais trechos:

| Trecho                                | Função                                         |
| ------------------------------------- | ---------------------------------------------- |
| `\b`                                  | Marca o início do token                        |
| `(\d{1,2})`                           | Captura o dia                                  |
| `\s*`                                 | Aceita espaços                                 |
| `(?:de\s+)?`                          | Aceita a palavra `de` de forma opcional        |
| `(janeiro\|fevereiro\|...\|dezembro)` | Reconhece o nome do mês                        |
| `mar[çc]o`                            | Aceita `março` e `marco`                       |
| `(?:de\s+)?`                          | Aceita outro `de` opcional antes do ano        |
| `(\d{4})?`                            | Captura o ano com 4 dígitos, caso exista       |
| `i`                                   | Ignora diferença entre maiúsculas e minúsculas |

Exemplos considerando o ano atual como 2026:

| Entrada                | Resultado    |
| ---------------------- | ------------ |
| `28 de Fevereiro`      | `28/02/2026` |
| `13 de agosto de 2021` | `13/08/2021` |
| `18 agosto`            | `18/08/2026` |
| `18 de agosto 2023`    | `18/08/2023` |

O nome do mês é convertido para número usando o hash `MESES`.

```ruby
MESES = {
  'janeiro' => 1,
  'fevereiro' => 2,
  'marco' => 3,
  'março' => 3,
  'abril' => 4,
  'maio' => 5,
  'junho' => 6,
  'julho' => 7,
  'agosto' => 8,
  'setembro' => 9,
  'outubro' => 10,
  'novembro' => 11,
  'dezembro' => 12
}
```

Assim como nas datas numéricas, a validação final também é feita com `Date.new`.

---

## 4. Tags

Expressão regular:

```ruby
REGEX_TAG = /(?<![^\s])#[\p{L}\p{N}_-]+/u
```

Essa expressão reconhece tags iniciadas com `#`.

Exemplos aceitos:

```txt
#casa
#trabalho
#faculdade
#minha-tarefa_2
```

Explicação dos principais trechos:

| Trecho            | Função                                                    |
| ----------------- | --------------------------------------------------------- |
| `(?<![^\s])`      | Garante que antes do `#` exista espaço ou início da frase |
| `#`               | Caractere obrigatório que inicia uma tag                  |
| `[\p{L}\p{N}_-]+` | Aceita letras, números, underline e hífen                 |
| `u`               | Permite caracteres Unicode                                |

O uso de `(?<![^\s])` evita que partes de URLs sejam reconhecidas como tags.

Exemplo:

```txt
https://sp.senac.br/pag1#teste?aula=1&teste=4
```

Nesse caso, `#teste` não deve ser reconhecido como tag, pois faz parte da URL.

Além disso, antes de buscar tags, o programa remove as URLs do texto:

```ruby
texto_limpo = texto.gsub(REGEX_URL, '')
```

Isso reduz falsos positivos.

---

## 5. URLs

Expressão regular:

```ruby
REGEX_URL = %r{https?://[^\s]+}i
```

Essa expressão reconhece URLs iniciadas por `http://` ou `https://`.

Exemplos aceitos:

```txt
https://sp.senac.br/pag1#teste?aula=1&teste=4
http://example.com
```

Explicação dos principais trechos:

| Trecho   | Função                                           |
| -------- | ------------------------------------------------ |
| `http`   | Início obrigatório do protocolo                  |
| `s?`     | Torna o `s` opcional, aceitando `http` e `https` |
| `://`    | Separador do protocolo                           |
| `[^\s]+` | Captura qualquer sequência sem espaços           |
| `i`      | Ignora diferença entre maiúsculas e minúsculas   |

Essa regex foi escolhida para capturar a URL completa, incluindo caminho, âncora e parâmetros.

Exemplo:

```txt
https://sp.senac.br/pag1#teste?aula=1&teste=4
```

Saída:

```txt
https://sp.senac.br/pag1#teste?aula=1&teste=4
```

---

## 6. Emails

Expressão regular:

```ruby
REGEX_EMAIL = /\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b/
```

Essa expressão reconhece emails em formato tradicional.

Exemplos aceitos:

```txt
jose.da-silva@sp.senac.br
contato+info@empresa.org
user@example.com
```

Explicação dos principais trechos:

| Trecho               | Função                              |
| -------------------- | ----------------------------------- |
| `\b`                 | Marca o início do token             |
| `[A-Za-z0-9._%+\-]+` | Parte local do email antes do `@`   |
| `@`                  | Arroba obrigatória                  |
| `[A-Za-z0-9.\-]+`    | Domínio do email                    |
| `\.`                 | Ponto antes da extensão             |
| `[A-Za-z]{2,}`       | Extensão com pelo menos duas letras |
| `\b`                 | Marca o fim do token                |

Antes de buscar emails, o programa remove URLs do texto:

```ruby
texto_limpo = texto.gsub(REGEX_URL, '')
```

Isso evita falsos positivos em URLs que possuam `@` em algum parâmetro.

---

## 7. Ações

As ações são reconhecidas a partir de uma lista de verbos e palavras comuns em tarefas.

Lista definida no código:

```ruby
ACOES = %w[
  agendar marcar ligar comprar pagar enviar estudar revisar entregar fazer buscar levar
  reuniao reunião cancelar confirmar reservar anotar lembrar responder
]
```

Expressão regular:

```ruby
REGEX_ACAO = /\b(#{ACOES.join('|')})\b/i
```

Essa regex é montada dinamicamente a partir da lista `ACOES`.

Explicação dos principais trechos:

| Trecho        | Função                                       |                                                  |
| ------------- | -------------------------------------------- | ------------------------------------------------ |
| `ACOES.join(' | ')`                                          | Une todas as ações com o operador de alternativa |
| `\b`          | Garante que a ação seja uma palavra completa |                                                  |
| `i`           | Ignora maiúsculas e minúsculas               |                                                  |

Exemplos:

| Entrada                    | Ações reconhecidas   |
| -------------------------- | -------------------- |
| `Agendar reunião com José` | `agendar`, `reunião` |
| `LIGAR para Ana`           | `ligar`              |
| `Enviar email para Maria`  | `enviar`             |
| `Revisar site`             | `revisar`            |

O uso de `\b` evita capturas dentro de outras palavras.

Exemplo:

```txt
desfazer
```

A palavra `fazer` não deve ser reconhecida dentro de `desfazer`.

---

## 8. Pessoas

A identificação de pessoas foi modelada a partir de conectores antes do nome.

Conectores aceitos:

```txt
com
para
pra
ao
à
```

Exemplos:

```txt
agendar com Pedro
marcar com José
reunião com Maria
reunião com Pedro e João
ligar para Ana Clara
```

---

### 8.1 Nome próprio

Expressão regular:

```ruby
REGEX_NOME = /[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+(?:\s+(?:de|da|do|dos|das)\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+|\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+)*/u
```

Essa expressão reconhece nomes próprios iniciados por letra maiúscula.

Explicação dos principais trechos:

| Trecho                     | Função                               |
| -------------------------- | ------------------------------------ |
| `[A-ZÁÉÍÓÚÂÊÔÃÕÇ]`         | Primeira letra maiúscula do nome     |
| `[\p{L}]+`                 | Restante do nome com letras Unicode  |
| `(?:de\|da\|do\|dos\|das)` | Aceita partículas de nomes compostos |
| `*`                        | Permite mais de uma palavra no nome  |
| `u`                        | Permite caracteres Unicode           |

Exemplos aceitos:

```txt
José
Maria
Ana Clara
Maria de Souza
João Pedro
```

---

### 8.2 Pessoa com conector

Expressão regular:

```ruby
REGEX_PESSOA = /(?i:\b(?:com|para|pra|ao|à))\s+(#{REGEX_NOME}(?:\s+e\s+#{REGEX_NOME})*)/u
```

Essa expressão reconhece nomes que aparecem depois de conectores.

Explicação dos principais trechos:

| Trecho                             | Função                                                     |
| ---------------------------------- | ---------------------------------------------------------- |
| `(?i:\b(?:com\|para\|pra\|ao\|à))` | Reconhece os conectores, ignorando maiúsculas e minúsculas |
| `\s+`                              | Exige pelo menos um espaço depois do conector              |
| `#{REGEX_NOME}`                    | Reutiliza a regex de nomes próprios                        |
| `(?:\s+e\s+#{REGEX_NOME})*`        | Permite nomes ligados por `e`                              |

Exemplos:

| Entrada                         | Pessoas reconhecidas |
| ------------------------------- | -------------------- |
| `com José`                      | `José`               |
| `para Maria de Souza`           | `Maria de Souza`     |
| `pra Pedro e João`              | `Pedro`, `João`      |
| `reunião com Ana Clara e Paulo` | `Ana Clara`, `Paulo` |

Depois da captura, o programa separa pessoas ligadas por `e` usando:

```ruby
split(/\s+e\s+/i)
```

Assim, a entrada:

```txt
reunião com Pedro e João
```

gera:

```txt
Pedro
João
```

---

## 9. Interação entre padrões

Alguns padrões podem gerar conflitos se forem aplicados diretamente sobre o texto original.

Por isso, o programa trata alguns casos antes da extração.

| Conflito                                              | Solução adotada                                           |
| ----------------------------------------------------- | --------------------------------------------------------- |
| `#teste` dentro de URL sendo capturado como tag       | A URL é removida antes da busca por tags                  |
| Um email dentro de uma URL sendo capturado como email | A URL é removida antes da busca por emails                |
| `às 10:30` sendo capturado por duas regex de horário  | A regex `REGEX_AS_HORA` usa lookahead negativo            |
| Horários inválidos como `99:99` sendo aceitos         | O método `formatar_horario` valida hora e minuto          |
| Datas inválidas como `31/02` sendo aceitas            | O código valida com `Date.new` e descarta se for inválida |

---

## 10. Exemplos gerais de reconhecimento

### Exemplo 1

Entrada:

```txt
Agendar com José reunião às 10:00 amanhã #trabalho
```

Elementos reconhecidos:

```txt
Dia: 12/06/2026
Horário: 10:00
Pessoa: José
Ação: agendar, reunião
Tag: #trabalho
URL: não encontrado
Email: não encontrado
```

---

### Exemplo 2

Entrada:

```txt
Marcar com Pedro e João às 10 30 no dia 13 de agosto de 2021 #faculdade
```

Elementos reconhecidos:

```txt
Dia: 13/08/2021
Horário: 10:30
Pessoa: Pedro, João
Ação: marcar
Tag: #faculdade
URL: não encontrado
Email: não encontrado
```

---

### Exemplo 3

Entrada:

```txt
Enviar email para Maria 20/04/2022 às 10 horas jose.da-silva@sp.senac.br
```

Elementos reconhecidos:

```txt
Dia: 20/04/2022
Horário: 10:00
Pessoa: Maria
Ação: enviar
Tag: não encontrado
URL: não encontrado
Email: jose.da-silva@sp.senac.br
```

---

### Exemplo 4

Entrada:

```txt
Revisar site https://sp.senac.br/pag1#teste?aula=1&teste=4 depois de amanhã #trabalho
```

Elementos reconhecidos:

```txt
Dia: 13/06/2026
Horário: não encontrado
Pessoa: não encontrado
Ação: revisar
Tag: #trabalho
URL: https://sp.senac.br/pag1#teste?aula=1&teste=4
Email: não encontrado
```

---

## 11. Limitações conhecidas

O reconhecedor foi construído para padrões comuns em listas de afazeres, mas não tenta interpretar a linguagem natural de forma completa.

Algumas limitações conhecidas:

* não reconhece datas vagas, como `semana que vem`, `mês que vem` ou `daqui a dois dias`;
* não reconhece nomes próprios escritos totalmente em minúsculo;
* não reconhece horários escritos por extenso, como `dez e meia`;
* não interpreta o contexto completo da frase;
* não diferencia quando uma palavra reconhecida como ação está sendo usada com outro significado;
* não reconhece URLs sem protocolo, como `www.exemplo.com`.

Essas limitações existem porque o objetivo do projeto é usar expressões regulares para reconhecer padrões formais específicos, e não construir um interpretador completo de linguagem natural.

---

## 12. Justificativa final

As expressões regulares foram escolhidas para cobrir os padrões solicitados no enunciado do trabalho, mantendo a implementação simples, clara e adequada ao conteúdo de Linguagens Formais e Autômatos.

O sistema reconhece os principais elementos de uma lista de afazeres e apresenta a saída de forma estruturada. Além disso, foram adicionadas validações simples para evitar resultados inválidos, como horários fora do intervalo permitido e datas inexistentes.

A modelagem foi organizada separando cada padrão em uma expressão regular própria, o que facilita a manutenção do código e a explicação teórica do funcionamento do reconhecedor.
