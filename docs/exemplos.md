# Exemplos de Teste

Este documento apresenta exemplos de entradas e saídas para validar o funcionamento do reconhecedor de lista de afazeres.

Os exemplos foram escolhidos para cobrir os principais padrões exigidos no trabalho:

* horários;
* datas;
* pessoas;
* ações;
* tags;
* URLs;
* emails;
* datas relativas;
* datas textuais;
* datas numéricas;
* casos inválidos.

As datas relativas como `hoje`, `amanhã` e `depois de amanhã` dependem da data atual do computador no momento da execução.

Nos exemplos abaixo, considera-se a execução no dia `11/06/2026`.

---

## Exemplo 1 — Tarefa com data relativa, horário, pessoa, ação e tag

### Entrada

```txt
Agendar com José reunião às 10:00 amanhã #trabalho
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 12/06/2026
Horário: 10:00
Pessoa: José
Ação: agendar, reunião
Tag: #trabalho
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Agendar`
* pessoa: `José`
* ação complementar: `reunião`
* horário: `10:00`
* data relativa: `amanhã`
* tag: `#trabalho`

---

## Exemplo 2 — Tarefa com duas pessoas e horário separado por espaço

### Entrada

```txt
Marcar com Pedro e João às 10 30 no dia 13 de agosto de 2021 #faculdade
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 13/08/2021
Horário: 10:30
Pessoa: Pedro, João
Ação: marcar
Tag: #faculdade
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Marcar`
* pessoas: `Pedro` e `João`
* horário com espaço: `10 30`
* data textual completa: `13 de agosto de 2021`
* tag: `#faculdade`

---

## Exemplo 3 — Tarefa com email, data numérica e horário por extenso

### Entrada

```txt
Enviar email para Maria 20/04/2022 às 10 horas jose.da-silva@sp.senac.br
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 20/04/2022
Horário: 10:00
Pessoa: Maria
Ação: enviar
Tag: não encontrado
URL: não encontrado
Email: jose.da-silva@sp.senac.br
```

### Padrões testados

* ação: `Enviar`
* pessoa: `Maria`
* data numérica completa: `20/04/2022`
* horário por extenso: `10 horas`
* email: `jose.da-silva@sp.senac.br`

---

## Exemplo 4 — Tarefa com URL, tag e data relativa composta

### Entrada

```txt
Revisar site https://sp.senac.br/pag1#teste?aula=1&teste=4 depois de amanhã #trabalho
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 13/06/2026
Horário: não encontrado
Pessoa: não encontrado
Ação: revisar
Tag: #trabalho
URL: https://sp.senac.br/pag1#teste?aula=1&teste=4
Email: não encontrado
```

### Padrões testados

* ação: `Revisar`
* URL completa com âncora e parâmetros;
* data relativa composta: `depois de amanhã`
* tag: `#trabalho`

### Observação

A parte `#teste` dentro da URL não deve ser reconhecida como tag, pois pertence ao link.

---

## Exemplo 5 — Tarefa com nome composto, data textual sem "de" e horário com "hora"

### Entrada

```txt
Ligar para Ana Clara 18 agosto 1 hora #casa
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 18/08/2026
Horário: 01:00
Pessoa: Ana Clara
Ação: ligar
Tag: #casa
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Ligar`
* pessoa com nome composto: `Ana Clara`
* data textual sem a palavra `de`: `18 agosto`
* horário por extenso: `1 hora`
* tag: `#casa`

---

## Exemplo 6 — Tarefa com data textual com ano, tag e horário com "às"

### Entrada

```txt
Comprar material para João 18 de agosto 2023 às 15 #casa
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 18/08/2023
Horário: 15:00
Pessoa: João
Ação: comprar
Tag: #casa
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Comprar`
* pessoa: `João`
* data textual com ano: `18 de agosto 2023`
* horário no formato `às 15`
* tag: `#casa`

---

## Exemplo 7 — Tarefa com data numérica sem ano

### Entrada

```txt
Pagar boleto 30/01 às 9h #financeiro
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 30/01/2026
Horário: 09:00
Pessoa: não encontrado
Ação: pagar
Tag: #financeiro
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Pagar`
* data numérica sem ano: `30/01`
* horário abreviado: `9h`
* tag: `#financeiro`

### Observação

Como o ano não foi informado, o sistema utiliza o ano atual.

---

## Exemplo 8 — Tarefa com hoje

### Entrada

```txt
Estudar hoje às 20:30 #faculdade
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 11/06/2026
Horário: 20:30
Pessoa: não encontrado
Ação: estudar
Tag: #faculdade
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Estudar`
* data relativa: `hoje`
* horário com dois-pontos: `20:30`
* tag: `#faculdade`

---

## Exemplo 9 — Tarefa com email e pessoa

### Entrada

```txt
Responder para Carlos hoje contato+info@empresa.org #trabalho
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 11/06/2026
Horário: não encontrado
Pessoa: Carlos
Ação: responder
Tag: #trabalho
URL: não encontrado
Email: contato+info@empresa.org
```

### Padrões testados

* ação: `Responder`
* pessoa: `Carlos`
* data relativa: `hoje`
* email com sinal de `+`
* tag: `#trabalho`

---

## Exemplo 10 — Tarefa com data inválida

### Entrada

```txt
Agendar com Pedro 31/02 às 10:00 #trabalho
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: não encontrado
Horário: 10:00
Pessoa: Pedro
Ação: agendar
Tag: #trabalho
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Agendar`
* pessoa: `Pedro`
* data inválida: `31/02`
* horário válido: `10:00`
* tag: `#trabalho`

### Observação

A data `31/02` é ignorada, pois fevereiro não possui 31 dias.

---

## Exemplo 11 — Tarefa com horário inválido

### Entrada

```txt
Reunião com Maria às 99:99 amanhã #trabalho
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 12/06/2026
Horário: não encontrado
Pessoa: Maria
Ação: reunião
Tag: #trabalho
URL: não encontrado
Email: não encontrado
```

### Padrões testados

* ação: `Reunião`
* pessoa: `Maria`
* data relativa: `amanhã`
* horário inválido: `99:99`
* tag: `#trabalho`

### Observação

O horário `99:99` é descartado porque a hora precisa estar entre `0` e `23` e os minutos entre `0` e `59`.

---

## Exemplo 12 — Tarefa com URL e sem tag externa

### Entrada

```txt
Revisar https://sp.senac.br/pag1#teste?aula=1&teste=4 amanhã
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: 12/06/2026
Horário: não encontrado
Pessoa: não encontrado
Ação: revisar
Tag: não encontrado
URL: https://sp.senac.br/pag1#teste?aula=1&teste=4
Email: não encontrado
```

### Padrões testados

* ação: `Revisar`
* URL completa;
* data relativa: `amanhã`

### Observação

O trecho `#teste` aparece dentro da URL e, por isso, não deve ser reconhecido como tag.

---

## Exemplo 13 — Tarefa sem nenhum padrão reconhecido

### Entrada

```txt
Texto aleatório sem informação estruturada
```

### Saída esperada

```txt
Elementos reconhecidos:
------------------------------
Dia: não encontrado
Horário: não encontrado
Pessoa: não encontrado
Ação: não encontrado
Tag: não encontrado
URL: não encontrado
Email: não encontrado
```

### Padrões testados

Este exemplo verifica se o programa lida corretamente com entradas que não possuem nenhum dos padrões reconhecidos.

---

## Resumo dos formatos testados

| Categoria               | Exemplos testados                                        |
| ----------------------- | -------------------------------------------------------- |
| Horário com dois-pontos | `10:00`, `20:30`                                         |
| Horário com espaço      | `10 30`                                                  |
| Horário por extenso     | `10 horas`, `1 hora`, `9h`                               |
| Horário com `às`        | `às 15`                                                  |
| Data relativa           | `hoje`, `amanhã`, `depois de amanhã`                     |
| Data numérica           | `30/01`, `20/04/2022`                                    |
| Data textual            | `13 de agosto de 2021`, `18 agosto`, `18 de agosto 2023` |
| Pessoa simples          | `José`, `Maria`, `Carlos`                                |
| Pessoa composta         | `Ana Clara`                                              |
| Duas pessoas            | `Pedro e João`                                           |
| Tag                     | `#trabalho`, `#casa`, `#faculdade`                       |
| URL                     | `https://sp.senac.br/pag1#teste?aula=1&teste=4`          |
| Email                   | `jose.da-silva@sp.senac.br`, `contato+info@empresa.org`  |
| Casos inválidos         | `31/02`, `99:99`                                         |

---

## Conclusão

Os testes demonstram que o reconhecedor consegue identificar os principais elementos solicitados no enunciado do trabalho.

Também foram incluídos casos inválidos para mostrar que o sistema não apenas captura padrões com expressões regulares, mas também realiza validações simples após a captura, como descartar datas inexistentes e horários fora do intervalo permitido.
