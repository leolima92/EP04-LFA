# Reconhecedor de Lista de Afazeres

Este projeto implementa um reconhecedor de padrões textuais para um sistema de lista de afazeres. A aplicação recebe uma frase digitada pelo usuário e identifica, por meio de expressões regulares em Ruby, elementos como datas, horários, pessoas, ações, tags, URLs e emails.

## Problema resolvido

Em sistemas de tarefas, é comum o usuário escrever frases em linguagem natural, como:

```txt
Agendar com José reunião às 10:00 amanhã #trabalho
```

O objetivo do sistema é transformar esse texto livre em informações estruturadas:

```txt
Dia: 10/06/2026
Horário: 10:00
Pessoa: José
Ação: agendar
Tag: #trabalho
```

A data exibida para termos relativos, como `hoje`, `amanhã` e `depois de amanhã`, depende da data atual do computador no momento da execução.

## Teoria envolvida

O projeto se baseia em **expressões regulares**, que descrevem exatamente a classe das **linguagens regulares** — o nível mais restrito da Hierarquia de Chomsky, reconhecido por **autômatos finitos determinísticos (DFA)** e não-determinísticos (NFA).

Pelo **Teorema de Kleene**, toda linguagem regular pode ser descrita por uma expressão regular e vice-versa. Isso garante que existe um autômato finito equivalente para cada padrão definido neste projeto. O motor de regex do Ruby (Onigmo) compila internamente cada expressão em um NFA e o executa sobre a cadeia de entrada — percorrendo o texto sem backtracking excessivo e sem precisar de memória proporcional ao tamanho da entrada (propriedade dos autômatos finitos).

Cada categoria de informação (data, horário, tag, etc.) é tratada como uma **linguagem regular independente**:

- A linguagem dos horários com dois-pontos é `L₁ = {HH:MM | H,M ∈ {0..9}}`, regular e reconhecível por um DFA de poucos estados.
- A linguagem das tags é `L₂ = {#w | w ∈ (Σ_letra ∪ Σ_dígito ∪ {_,-})⁺}`, também regular.
- A linguagem das ações é uma **união finita** de linguagens singleton `{agendar} ∪ {marcar} ∪ ...` — a classe das linguagens regulares é fechada sob união, portanto o resultado é regular.
- Datas relativas como `hoje`, `amanhã` e `depois de amanhã` formam uma linguagem finita, que é um caso particular de linguagem regular.

Em vez de combinar substrings manualmente, cada padrão delega ao motor (Onigmo) o papel do reconhecedor, tornando a modelagem declarativa: descreve-se *qual* é a forma esperada (a linguagem), e não *como* percorrer o texto caractere a caractere (o autômato).

Foram definidos padrões para:

- horários, como `10:30`, `10 30`, `10 horas`, `1 hora` e `às 10`;
- datas, como `28 de Fevereiro`, `13 de agosto de 2021`, `30/01`, `20/04/2022`, `hoje`, `amanhã` e `depois de amanhã`;
- tags, como `#casa` e `#trabalho`;
- URLs iniciadas por `http://` ou `https://`;
- emails em formato tradicional;
- ações escolhidas no projeto, como `agendar`, `marcar`, `ligar`, `comprar`, `pagar`, `enviar`, entre outras;
- pessoas identificadas por conectores como `com`, `para`, `pra`, `ao` e `à`.

A modelagem detalhada de cada expressão regular, com os critérios adotados e os casos cobertos, está documentada em [`docs/modelagem.md`](docs/modelagem.md).

## Estrutura do projeto

```txt
reconhecedor_tarefas_ruby/
├── main.rb
├── README.md
└── docs/
    └── modelagem.md
```

## Como executar

É necessário ter o Ruby instalado (recomenda-se a versão 3.0 ou superior).

No terminal, dentro da pasta do projeto, execute:

```bash
ruby main.rb
```

Digite uma tarefa quando o programa solicitar a entrada.

Exemplo de entrada:

```txt
Agendar com José reunião às 10:00 amanhã #trabalho
```

Saída esperada:

```txt
Elementos reconhecidos:
------------------------------
Dia: 10/06/2026
Horário: 10:00
Pessoa: José
Ação: agendar
Tag: #trabalho
URL: não encontrado
Email: não encontrado
```

## Explicação básica do código

A classe `ReconhecedorAfazeres` concentra as expressões regulares e os métodos de extração. Cada método é responsável por uma categoria de informação e devolve apenas valores válidos e sem repetição.

Principais métodos:

- `extrair`: executa todos os reconhecedores e retorna um hash com os resultados;
- `extrair_datas`: reconhece datas numéricas (`30/01`), textuais (`13 de agosto de 2021`) e relativas (`hoje`, `amanhã`, `depois de amanhã`), convertendo todas para o formato `dd/mm/aaaa`;
- `extrair_horarios`: reconhece horários com dois-pontos, com espaço, por extenso (`10 horas`) e na forma `às 10`, evitando duplicidade entre os padrões;
- `extrair_pessoas`: reconhece pessoas a partir dos conectores definidos, exigindo nomes próprios iniciados por letra maiúscula;
- `extrair_acoes`: reconhece os verbos/ações escolhidos no projeto;
- `extrair_tags`: reconhece tags iniciadas por `#`, ignorando o caractere `#` que aparece dentro de URLs;
- `extrair_urls`: reconhece links iniciados por `http://` ou `https://`;
- `extrair_emails`: reconhece endereços de email.

O programa lê a entrada pelo teclado com `gets`, aplica as expressões regulares e exibe os elementos encontrados de forma estruturada.

## Observação

O projeto não utiliza gems ou bibliotecas externas de reconhecimento de datas. A biblioteca padrão `Date` é usada apenas para representar, validar e formatar datas, sem recorrer a métodos de interpretação automática como `Date.parse`.
