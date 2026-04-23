#!/usr/bin/env python3
"""Gera arquivo de lancamentos compativel com o Emunah Bank Lab."""

from __future__ import annotations

import argparse
import json
import random
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from typing import Any


DEFAULT_CANAIS = ["APP", "ATM", "PIX", "INTERNET", "BATCH", "POS", "TED", "RH"]
DEFAULT_HISTORICOS = [
    "DEPOSITO",
    "PAGAMENTO BOLETO",
    "TRANSFERENCIA",
    "SAQUE",
    "COMPRA DEBITO",
    "APORTE",
    "TED RECEBIDA",
    "PIX ENVIADO",
    "PIX RECEBIDO",
    "AJUSTE FINANCEIRO",
]


@dataclass(frozen=True)
class Cliente:
    client_id: int
    nome: str
    cpf: str
    data_nasc: str
    status: str
    data_cad: str


@dataclass(frozen=True)
class Conta:
    agencia: int
    numero: int
    client_id: int
    tipo: str
    status: str
    data_abertura: str
    saldo_centavos: int
    limite_centavos: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gerador de lancamentos em layout fixo de 120 bytes do Emunah Bank Lab."
    )
    parser.add_argument("--config", help="Arquivo JSON com os parametros de geracao.")
    parser.add_argument("--quantidade", type=int, help="Quantidade de lancamentos a gerar.")
    parser.add_argument("--output", help="Arquivo de saida.")
    parser.add_argument("--data", help="Data unica no formato AAAAMMDD.")
    parser.add_argument("--valor-min", type=Decimal, help="Valor minimo por lancamento.")
    parser.add_argument("--valor-max", type=Decimal, help="Valor maximo por lancamento.")
    parser.add_argument("--clientes", help="Lista separada por virgula com IDs ou nomes.")
    parser.add_argument("--tipos", help="Lista separada por virgula. Ex.: C,D")
    parser.add_argument("--canais", help="Lista separada por virgula.")
    parser.add_argument("--historicos", help="Lista separada por virgula.")
    parser.add_argument("--status", help="Status a gravar no registro. Ex.: P")
    parser.add_argument("--lote-inicial", type=int, help="Numero inicial do lote.")
    parser.add_argument("--arquivo-clientes", help="Seed de clientes.")
    parser.add_argument("--arquivo-contas", help="Seed de contas.")
    parser.add_argument("--seed", type=int, help="Seed do gerador aleatorio.")
    return parser.parse_args()


def load_config(config_path: str | None) -> dict[str, Any]:
    if not config_path:
        return {}
    path = Path(config_path)
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def split_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    return [item.strip() for item in str(value).split(",") if item.strip()]


def get_option(args: argparse.Namespace, config: dict[str, Any], name: str, default: Any) -> Any:
    cli_name = name.replace("-", "_")
    cli_value = getattr(args, cli_name, None)
    if cli_value is not None:
        return cli_value
    return config.get(name, default)


def resolve_path(path_value: str | Path, base_dir: Path, config_path: str | None = None) -> Path:
    path = Path(path_value)
    if path.is_absolute():
        return path
    if config_path:
        config_dir = Path(config_path).resolve().parent
        candidate = config_dir / path
        if candidate.exists() or str(path).startswith("."):
            return candidate
    return base_dir / path


def parse_clientes(path: Path) -> dict[int, Cliente]:
    clientes: dict[int, Cliente] = {}
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            record = line.rstrip("\r\n")
            if not record.strip():
                continue
            clientes[int(record[0:5])] = Cliente(
                client_id=int(record[0:5]),
                nome=record[5:35].strip(),
                cpf=record[35:46],
                data_nasc=record[46:54],
                status=record[54:55],
                data_cad=record[55:63],
            )
    return clientes


def parse_contas(path: Path) -> list[Conta]:
    contas: list[Conta] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            record = line.rstrip("\r\n")
            if not record.strip():
                continue
            contas.append(
                Conta(
                    agencia=int(record[0:4]),
                    numero=int(record[4:12]),
                    client_id=int(record[12:17]),
                    tipo=record[17:18],
                    status=record[18:19],
                    data_abertura=record[19:27],
                    saldo_centavos=int(record[28:41]),
                    limite_centavos=int(record[42:53]),
                )
            )
    return contas


def to_centavos(value: Decimal) -> int:
    return int((value * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def normalize_date(value: Any) -> str:
    if value in (None, ""):
        return datetime.now().strftime("%Y%m%d")
    date_str = str(value)
    datetime.strptime(date_str, "%Y%m%d")
    return date_str


def filter_contas(
    contas: list[Conta],
    clientes: dict[int, Cliente],
    filtros_cliente: list[str],
) -> list[Conta]:
    if not filtros_cliente:
        return [conta for conta in contas if conta.status == "A"]

    normalized = [filtro.casefold() for filtro in filtros_cliente]
    elegiveis: list[Conta] = []
    for conta in contas:
        cliente = clientes.get(conta.client_id)
        if cliente is None or conta.status != "A":
            continue
        nome = cliente.nome.casefold()
        client_id = str(cliente.client_id)
        if any(filtro == client_id or filtro in nome for filtro in normalized):
            elegiveis.append(conta)
    return elegiveis


def choose_amount_centavos(min_centavos: int, max_centavos: int, rng: random.Random) -> int:
    if min_centavos > max_centavos:
        raise ValueError("valor-min nao pode ser maior que valor-max.")
    return rng.randint(min_centavos, max_centavos)


def fit_text(value: str, size: int) -> str:
    return value[:size].ljust(size)


def build_record(
    conta: Conta,
    data_movimento: str,
    tipo: str,
    valor_centavos: int,
    historico: str,
    canal: str,
    lote: int,
    nseq: int,
    status: str,
) -> str:
    valor_str = f"{valor_centavos:013d}"
    registro = (
        f"{conta.agencia:04d}"
        f"{conta.numero:08d}"
        f"{data_movimento}"
        f"{tipo[:1]}"
        f"{valor_str}"
        f"{fit_text(historico.upper(), 30)}"
        f"{fit_text(canal.upper(), 10)}"
        f"{lote:06d}"
        f"{nseq:06d}"
        f"{status[:1].upper()}"
        f"{' ' * 33}"
    )
    if len(registro) != 120:
        raise ValueError(f"Registro gerado com tamanho invalido: {len(registro)}")
    return registro


def main() -> int:
    args = parse_args()
    config = load_config(args.config)

    base_dir = Path(__file__).resolve().parents[2]
    arquivo_clientes = resolve_path(
        get_option(args, config, "arquivo-clientes", str(base_dir / "data" / "seed" / "clientes.txt")),
        base_dir=base_dir,
        config_path=args.config,
    )
    arquivo_contas = resolve_path(
        get_option(args, config, "arquivo-contas", str(base_dir / "data" / "seed" / "contas.txt")),
        base_dir=base_dir,
        config_path=args.config,
    )
    output_path = resolve_path(
        get_option(args, config, "output", str(base_dir / "data" / "entrada" / "lancamentos_gerados.txt")),
        base_dir=base_dir,
        config_path=args.config,
    )
    quantidade = int(get_option(args, config, "quantidade", 10))
    data_movimento = normalize_date(get_option(args, config, "data", None))
    valor_min = Decimal(str(get_option(args, config, "valor-min", "10.00")))
    valor_max = Decimal(str(get_option(args, config, "valor-max", "5000.00")))
    status = str(get_option(args, config, "status", "P")).upper()
    lote_inicial = int(get_option(args, config, "lote-inicial", 1))
    seed = get_option(args, config, "seed", None)
    tipos = [tipo.upper() for tipo in split_list(get_option(args, config, "tipos", ["C", "D"]))] or ["C", "D"]
    canais = [canal.upper() for canal in split_list(get_option(args, config, "canais", DEFAULT_CANAIS))] or DEFAULT_CANAIS
    historicos = split_list(get_option(args, config, "historicos", DEFAULT_HISTORICOS)) or DEFAULT_HISTORICOS
    filtros_cliente = split_list(get_option(args, config, "clientes", []))

    if quantidade <= 0:
        raise ValueError("quantidade deve ser maior que zero.")
    if any(tipo not in {"C", "D"} for tipo in tipos):
        raise ValueError("tipos permitidos: C e D.")
    if len(status) != 1:
        raise ValueError("status deve possuir apenas 1 caractere.")

    clientes = parse_clientes(arquivo_clientes)
    contas = parse_contas(arquivo_contas)
    contas_elegiveis = filter_contas(contas, clientes, filtros_cliente)
    if not contas_elegiveis:
        raise ValueError("Nenhuma conta elegivel encontrada para os filtros informados.")

    rng = random.Random(seed)
    min_centavos = to_centavos(valor_min)
    max_centavos = to_centavos(valor_max)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    registros: list[str] = []
    for indice in range(quantidade):
        conta = rng.choice(contas_elegiveis)
        lote = lote_inicial + (indice // 999999)
        nseq = (indice % 999999) + 1
        tipo = rng.choice(tipos)
        valor_centavos = choose_amount_centavos(min_centavos, max_centavos, rng)
        historico = rng.choice(historicos)
        canal = rng.choice(canais)
        registros.append(
            build_record(
                conta=conta,
                data_movimento=data_movimento,
                tipo=tipo,
                valor_centavos=valor_centavos,
                historico=historico,
                canal=canal,
                lote=lote,
                nseq=nseq,
                status=status,
            )
        )

    with output_path.open("w", encoding="utf-8", newline="\n") as handle:
        for registro in registros:
            handle.write(registro + "\n")

    print("Arquivo gerado com sucesso.")
    print(f"Saida      : {output_path}")
    print(f"Registros  : {len(registros)}")
    print(f"Data       : {data_movimento}")
    print(f"Clientes   : {len({conta.client_id for conta in contas_elegiveis})} elegiveis")
    print(f"Contas     : {len(contas_elegiveis)} elegiveis")
    print(f"Faixa valor: {valor_min} a {valor_max}")
    if seed is not None:
        print(f"Seed       : {seed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
