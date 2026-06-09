require 'date'

class ReconhecedorAfazeres
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
  }.freeze
 
  ACOES = %w[
    agendar marcar ligar comprar pagar enviar estudar revisar entregar fazer buscar levar
    reuniao reunião cancelar confirmar reservar anotar lembrar responder
  ].freeze
 
  REGEX_EMAIL = /\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b/.freeze
 
  REGEX_URL = %r{https?://[^\s]+}i.freeze
 
  REGEX_TAG = /(?<![^\s])#[\p{L}\p{N}_-]+/u.freeze
 
  REGEX_HORA_COM_MINUTO = /\b(?:às|as)?\s*(\d{1,2})(?::|\s+)(\d{2})\b/i.freeze
 
  REGEX_HORA_POR_EXTENSO = /\b(\d{1,2})\s*(?:h|hora|horas)\b/i.freeze
 
  REGEX_AS_HORA = /\b(?:às|as)\s*(\d{1,2})\b(?!\s*(?::|\d))/i.freeze
 
  REGEX_DATA_NUMERICA = %r{\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b}.freeze
 
  REGEX_DATA_RELATIVA =
    /(?<![\p{L}])(hoje|amanh[ãa]|depois de amanh[ãa])(?![\p{L}])/iu.freeze
 
  REGEX_DATA_TEXTUAL =
    /\b(\d{1,2})\s*(?:de\s+)?(janeiro|fevereiro|mar[çc]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*(?:de\s+)?(\d{4})?\b/i.freeze
 
  REGEX_ACAO = /\b(#{ACOES.join('|')})\b/i.freeze
 
  REGEX_NOME =
    /[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+(?:\s+(?:de|da|do|dos|das)\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+|\s+[A-ZÁÉÍÓÚÂÊÔÃÕÇ][\p{L}]+)*/u.freeze
 
  REGEX_PESSOA =
    /(?i:\b(?:com|para|pra|ao|à))\s+(#{REGEX_NOME}(?:\s+e\s+#{REGEX_NOME})*)/u.freeze
