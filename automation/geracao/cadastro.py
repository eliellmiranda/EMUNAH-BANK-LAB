#!/usr/bin/env python3
"""Cadastro de clientes, contas e gerador de lancamentos do Emunah Bank Lab.

Mantem os layouts fixos:
    clientes.txt    -> 80 bytes por registro
    contas.txt      -> 100 bytes por registro
    lancamentos.txt -> 120 bytes por registro
"""

from __future__ import annotations

import argparse
import random
import re
import sys
import unicodedata
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

# --------------------------------------------------------------------------- #
# Constantes de layout
# --------------------------------------------------------------------------- #

CLIENTE_LEN = 80
CONTA_LEN = 100
LANCAMENTO_LEN = 120

TIPOS_CONTA = {"C", "P"}            # Corrente / Poupanca
TIPOS_LANC = {"C", "D"}             # Credito / Debito
STATUS_ATIVO = "A"

CANAIS = ["APP", "ATM", "PIX", "INTERNET", "BATCH", "POS", "TED"]
HISTORICOS = [
    "DEPOSITO", "PAGAMENTO BOLETO", "TRANSFERENCIA", "SAQUE",
    "COMPRA DEBITO", "TED RECEBIDA", "PIX ENVIADO",
    "PIX RECEBIDO", "AJUSTE FINANCEIRO",
]

BASE_DIR = Path(__file__).resolve().parents[2]
DEFAULT_OUT = BASE_DIR / "data" / "normalized"


# --------------------------------------------------------------------------- #
# Modelos
# --------------------------------------------------------------------------- #

@dataclass
class Cliente:
    client_id: int
    nome: str
    cpf: str
    data_nasc: str
    status: str
    data_cad: str

    def serialize(self) -> str:
        rec = (
            f"{self.client_id:05d}"
            f"{self.nome[:30].ljust(30)}"
            f"{self.cpf}"
            f"{self.data_nasc}"
            f"{self.status[:1]}"
            f"{self.data_cad}"
        )
        return rec.ljust(CLIENTE_LEN)


@dataclass
class Conta:
    agencia: int
    numero: int
    client_id: int
    tipo: str
    status: str
    data_abertura: str
    saldo_centavos: int
    limite_centavos: int

    def serialize(self) -> str:
        rec = (
            f"{self.agencia:04d}"
            f"{self.numero:08d}"
            f"{self.client_id:05d}"
            f"{self.tipo[:1]}"
            f"{self.status[:1]}"
            f"{self.data_abertura}"
            f" {self.saldo_centavos:012d}"
            f" {self.limite_centavos:010d}"
        )
        return rec.ljust(CONTA_LEN)


@dataclass
class Lancamento:
    agencia: int
    conta: int
    data: str
    tipo: str
    valor_centavos: int
    historico: str
    canal: str
    lote: int
    nseq: int
    status: str = "P"

    def serialize(self) -> str:
        rec = (
            f"{self.agencia:04d}"
            f"{self.conta:08d}"
            f"{self.data}"
            f"{self.tipo[:1]}"
            f"{self.valor_centavos:013d}"
            f"{self.historico[:30].upper().ljust(30)}"
            f"{self.canal[:10].upper().ljust(10)}"
            f"{self.lote:06d}"
            f"{self.nseq:06d}"
            f"{self.status[:1].upper()}"
        )
        return rec.ljust(LANCAMENTO_LEN)


# --------------------------------------------------------------------------- #
# Repositorio
# --------------------------------------------------------------------------- #

@dataclass
class Repo:
    out_dir: Path
    clientes: dict[int, Cliente] = field(default_factory=dict)
    contas: dict[int, Conta] = field(default_factory=dict)
    cpfs: set[str] = field(default_factory=set)
    contas_por_cliente: dict[int, list[int]] = field(default_factory=dict)

    @property
    def clientes_path(self) -> Path:
        return self.out_dir / "clientes.txt"

    @property
    def contas_path(self) -> Path:
        return self.out_dir / "contas.txt"

    @property
    def lancamentos_path(self) -> Path:
        return self.out_dir / "lancamentos_simulados.txt"

    def load(self) -> None:
        if self.clientes_path.exists():
            with self.clientes_path.open("r", encoding="utf-8") as fh:
                for line in fh:
                    rec = line.rstrip("\r\n")
                    if not rec.strip():
                        continue
                    c = Cliente(
                        client_id=int(rec[0:5]),
                        nome=rec[5:35].rstrip(),
                        cpf=rec[35:46],
                        data_nasc=rec[46:54],
                        status=rec[54:55],
                        data_cad=rec[55:63],
                    )
                    self.clientes[c.client_id] = c
                    self.cpfs.add(c.cpf)
        if self.contas_path.exists():
            with self.contas_path.open("r", encoding="utf-8") as fh:
                for line in fh:
                    rec = line.rstrip("\r\n")
                    if not rec.strip():
                        continue
                    cc = Conta(
                        agencia=int(rec[0:4]),
                        numero=int(rec[4:12]),
                        client_id=int(rec[12:17]),
                        tipo=rec[17:18],
                        status=rec[18:19],
                        data_abertura=rec[19:27],
                        saldo_centavos=int(rec[28:40]),
                        limite_centavos=int(rec[41:51]),
                    )
                    self.contas[cc.numero] = cc
                    self.contas_por_cliente.setdefault(cc.client_id, []).append(cc.numero)

    def save_clientes(self) -> None:
        self.out_dir.mkdir(parents=True, exist_ok=True)
        with self.clientes_path.open("w", encoding="utf-8", newline="\n") as fh:
            for cid in sorted(self.clientes):
                fh.write(self.clientes[cid].serialize() + "\n")

    def save_contas(self) -> None:
        self.out_dir.mkdir(parents=True, exist_ok=True)
        with self.contas_path.open("w", encoding="utf-8", newline="\n") as fh:
            for num in sorted(self.contas):
                fh.write(self.contas[num].serialize() + "\n")

    def append_lancamentos(self, regs: list[Lancamento]) -> None:
        self.out_dir.mkdir(parents=True, exist_ok=True)
        with self.lancamentos_path.open("w", encoding="utf-8", newline="\n") as fh:
            for r in regs:
                fh.write(r.serialize() + "\n")

    # ------------------ regras de negocio ------------------ #

    def proximo_cliente_id(self) -> int:
        return (max(self.clientes) + 1) if self.clientes else 1

    def proxima_conta(self) -> int:
        return (max(self.contas) + 1) if self.contas else 1

    def add_cliente(self, nome: str, cpf: str, data_nasc: str) -> Cliente:
        if cpf in self.cpfs:
            raise ValueError(f"CPF {cpf} ja cadastrado.")
        cliente = Cliente(
            client_id=self.proximo_cliente_id(),
            nome=normalize_text(nome).upper(),
            cpf=cpf,
            data_nasc=data_nasc,
            status=STATUS_ATIVO,
            data_cad=datetime.now().strftime("%Y%m%d"),
        )
        self.clientes[cliente.client_id] = cliente
        self.cpfs.add(cpf)
        return cliente

    def add_conta(
        self,
        client_id: int,
        tipo: str,
        agencia: int = 1,
        saldo_centavos: int = 0,
        limite_centavos: int = 0,
        numero: int | None = None,
    ) -> Conta:
        if client_id not in self.clientes:
            raise ValueError(f"Cliente {client_id} nao existe.")
        if tipo not in TIPOS_CONTA:
            raise ValueError(f"Tipo de conta invalido: {tipo}. Use C ou P.")
        numero = numero if numero is not None else self.proxima_conta()
        if numero in self.contas:
            raise ValueError(f"Conta {numero:08d} ja cadastrada.")
        conta = Conta(
            agencia=agencia,
            numero=numero,
            client_id=client_id,
            tipo=tipo,
            status=STATUS_ATIVO,
            data_abertura=datetime.now().strftime("%Y%m%d"),
            saldo_centavos=saldo_centavos,
            limite_centavos=limite_centavos,
        )
        self.contas[numero] = conta
        self.contas_por_cliente.setdefault(client_id, []).append(numero)
        return conta


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

def normalize_text(value: str) -> str:
    nfkd = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in nfkd if not unicodedata.combining(ch))


def valida_cpf(cpf: str) -> str:
    digits = re.sub(r"\D", "", cpf)
    if len(digits) != 11:
        raise ValueError("CPF deve conter 11 digitos.")
    return digits


def valida_data(value: str, label: str = "data") -> str:
    try:
        datetime.strptime(value, "%Y%m%d")
    except ValueError as exc:
        raise ValueError(f"{label} invalida (use AAAAMMDD): {value}") from exc
    return value


def gerar_cpf_aleatorio(rng: random.Random, existentes: set[str]) -> str:
    while True:
        base = [rng.randint(0, 9) for _ in range(9)]

        def dv(parcial: list[int]) -> int:
            soma = sum(d * w for d, w in zip(parcial, range(len(parcial) + 1, 1, -1)))
            resto = (soma * 10) % 11
            return 0 if resto == 10 else resto

        d1 = dv(base)
        d2 = dv(base + [d1])
        cpf = "".join(map(str, base + [d1, d2]))
        if cpf not in existentes:
            return cpf


# --------------------------------------------------------------------------- #
# Acoes interativas
# --------------------------------------------------------------------------- #

def cmd_cliente(repo: Repo) -> None:
    print("\n--- Cadastro de Cliente ---")
    nome = input("Nome.............: ").strip()
    if not nome:
        print("Nome obrigatorio.")
        return
    cpf_raw = input("CPF (11 digitos).: ").strip()
    try:
        cpf = valida_cpf(cpf_raw)
    except ValueError as exc:
        print(f"ERRO: {exc}")
        return
    if cpf in repo.cpfs:
        print(f"ERRO: CPF {cpf} ja cadastrado.")
        return
    nasc = input("Nascimento AAAAMMDD: ").strip()
    try:
        valida_data(nasc, "nascimento")
    except ValueError as exc:
        print(f"ERRO: {exc}")
        return
    cliente = repo.add_cliente(nome, cpf, nasc)
    repo.save_clientes()
    print(f"OK -> cliente {cliente.client_id:05d} ({cliente.nome}) cadastrado.")


def cmd_conta(repo: Repo) -> None:
    print("\n--- Cadastro de Conta ---")
    if not repo.clientes:
        print("Nenhum cliente cadastrado. Cadastre clientes primeiro.")
        return
    try:
        cid = int(input("ID do cliente....: ").strip())
    except ValueError:
        print("ID invalido.")
        return
    if cid not in repo.clientes:
        print(f"Cliente {cid} nao existe.")
        return
    tipo = input("Tipo (C/P).......: ").strip().upper() or "C"
    saldo_str = input("Saldo inicial R$.: ").strip() or "0"
    limite_str = input("Limite R$........: ").strip() or "0"
    try:
        saldo_c = int(round(float(saldo_str.replace(",", ".")) * 100))
        limite_c = int(round(float(limite_str.replace(",", ".")) * 100))
        conta = repo.add_conta(cid, tipo, saldo_centavos=saldo_c, limite_centavos=limite_c)
    except ValueError as exc:
        print(f"ERRO: {exc}")
        return
    repo.save_contas()
    print(
        f"OK -> conta {conta.numero:08d} ({conta.tipo}) "
        f"para cliente {cid:05d} ({repo.clientes[cid].nome})."
    )


def cmd_listar(repo: Repo) -> None:
    print("\n--- Contas por Cliente ---")
    if not repo.clientes:
        print("Nenhum cliente cadastrado.")
        return
    for cid in sorted(repo.clientes):
        cli = repo.clientes[cid]
        contas = repo.contas_por_cliente.get(cid, [])
        marca = "(sem contas)" if not contas else ", ".join(
            f"{n:08d}/{repo.contas[n].tipo}" for n in sorted(contas)
        )
        print(f"  {cli.client_id:05d} {cli.nome:<30} CPF {cli.cpf}  -> {marca}")


def cmd_lancamentos(repo: Repo) -> None:
    print("\n--- Gerar Lancamentos ---")
    contas_ativas = [c for c in repo.contas.values() if c.status == STATUS_ATIVO]
    if not contas_ativas:
        print("Nenhuma conta ativa para gerar lancamentos.")
        return
    try:
        qtd = int(input("Quantidade.......: ").strip())
    except ValueError:
        print("Quantidade invalida.")
        return
    if qtd <= 0:
        print("Quantidade deve ser > 0.")
        return
    data = input("Data AAAAMMDD (Enter=hoje): ").strip() or datetime.now().strftime("%Y%m%d")
    try:
        valida_data(data, "data movimento")
    except ValueError as exc:
        print(f"ERRO: {exc}")
        return
    valor_min_str = input("Valor min R$ (10): ").strip() or "10"
    valor_max_str = input("Valor max R$ (5000): ").strip() or "5000"
    seed_str = input("Seed (Enter=randomico): ").strip()
    try:
        vmin = int(round(float(valor_min_str.replace(",", ".")) * 100))
        vmax = int(round(float(valor_max_str.replace(",", ".")) * 100))
    except ValueError:
        print("Faixa de valor invalida.")
        return
    if vmin > vmax:
        print("valor-min nao pode ser maior que valor-max.")
        return
    rng = random.Random(int(seed_str)) if seed_str else random.Random()
    regs = gerar_lancamentos(contas_ativas, qtd, data, vmin, vmax, rng)
    repo.append_lancamentos(regs)
    print(f"OK -> {len(regs)} lancamentos gravados em {repo.lancamentos_path}.")


def gerar_lancamentos(
    contas: list[Conta],
    quantidade: int,
    data: str,
    vmin_c: int,
    vmax_c: int,
    rng: random.Random,
    lote_inicial: int = 1,
) -> list[Lancamento]:
    regs: list[Lancamento] = []
    for indice in range(quantidade):
        conta = rng.choice(contas)
        regs.append(
            Lancamento(
                agencia=conta.agencia,
                conta=conta.numero,
                data=data,
                tipo=rng.choice(sorted(TIPOS_LANC)),
                valor_centavos=rng.randint(vmin_c, vmax_c),
                historico=rng.choice(HISTORICOS),
                canal=rng.choice(CANAIS),
                lote=lote_inicial + (indice // 999999),
                nseq=(indice % 999999) + 1,
            )
        )
    return regs


# --------------------------------------------------------------------------- #
# Modo seed (cria base sintetica)
# --------------------------------------------------------------------------- #

def cmd_seed(repo: Repo, qtd_clientes: int, contas_por_cliente: int, seed: int | None) -> None:
    rng = random.Random(seed)
    nomes = [
        "JOAO SILVA", "MARIA SOUZA", "PEDRO SANTOS", "ANA COSTA", "CARLA MORAES",
        "LUCAS BARBOSA", "BRUNO LIMA", "PAULA ALMEIDA", "RENATA ARAUJO",
        "FABIO PEREIRA", "MARTA FERNANDES", "GUSTAVO ROCHA", "JULIANA TEIXEIRA",
        "THIAGO RIBEIRO", "FERNANDA MELO", "DANIEL OLIVEIRA", "AMANDA MARTINS",
        "RODRIGO NUNES", "CAMILA GOMES", "RAFAEL DUARTE",
    ]
    for i in range(qtd_clientes):
        nome = nomes[i % len(nomes)] if i < len(nomes) else f"CLIENTE SINTETICO {i + 1:04d}"
        cpf = gerar_cpf_aleatorio(rng, repo.cpfs)
        nasc = f"{rng.randint(1960, 2005)}{rng.randint(1, 12):02d}{rng.randint(1, 28):02d}"
        cli = repo.add_cliente(nome, cpf, nasc)
        for j in range(contas_por_cliente):
            tipo = "C" if j == 0 else ("P" if j == 1 else rng.choice(["C", "P"]))
            repo.add_conta(
                cli.client_id, tipo,
                saldo_centavos=rng.randint(50_000, 500_000),
                limite_centavos=500_000,
            )
    repo.save_clientes()
    repo.save_contas()
    print(
        f"Seed gerado -> {len(repo.clientes)} clientes, {len(repo.contas)} contas em {repo.out_dir}."
    )


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #

def menu(repo: Repo) -> None:
    acoes = {
        "1": ("Cadastrar cliente", cmd_cliente),
        "2": ("Cadastrar conta", cmd_conta),
        "3": ("Listar contas por cliente", cmd_listar),
        "4": ("Gerar lancamentos", cmd_lancamentos),
        "0": ("Sair", None),
    }
    while True:
        print("\n=== Emunah Bank Lab - Cadastro & Geracao ===")
        print(f"Saida: {repo.out_dir}")
        print(f"Clientes: {len(repo.clientes)} | Contas: {len(repo.contas)}")
        for k, (label, _) in acoes.items():
            print(f"  {k}) {label}")
        opcao = input("Opcao: ").strip()
        if opcao == "0":
            return
        acao = acoes.get(opcao)
        if not acao:
            print("Opcao invalida.")
            continue
        try:
            acao[1](repo)
        except KeyboardInterrupt:
            print("\nCancelado.")
        except Exception as exc:  # noqa: BLE001
            print(f"ERRO: {exc}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--out-dir", default=str(DEFAULT_OUT), help="Diretorio de saida.")
    sub = p.add_subparsers(dest="cmd")

    sub.add_parser("menu", help="Menu interativo (default).")

    sp = sub.add_parser("seed", help="Gera base sintetica de clientes e contas.")
    sp.add_argument("--clientes", type=int, default=20)
    sp.add_argument("--contas-por-cliente", type=int, default=2)
    sp.add_argument("--seed", type=int, default=None)

    sp = sub.add_parser("lancamentos", help="Gera lancamentos aleatorios em batch.")
    sp.add_argument("--quantidade", type=int, required=True)
    sp.add_argument("--data", default=None, help="AAAAMMDD (default=hoje).")
    sp.add_argument("--valor-min", type=float, default=10.0)
    sp.add_argument("--valor-max", type=float, default=5000.0)
    sp.add_argument("--seed", type=int, default=None)

    return p.parse_args()


def main() -> int:
    args = parse_args()
    repo = Repo(out_dir=Path(args.out_dir))
    repo.load()

    if args.cmd == "seed":
        cmd_seed(repo, args.clientes, args.contas_por_cliente, args.seed)
        return 0

    if args.cmd == "lancamentos":
        contas = [c for c in repo.contas.values() if c.status == STATUS_ATIVO]
        if not contas:
            print("Nenhuma conta ativa. Rode 'seed' ou cadastre contas primeiro.", file=sys.stderr)
            return 1
        data = valida_data(args.data, "data") if args.data else datetime.now().strftime("%Y%m%d")
        rng = random.Random(args.seed)
        regs = gerar_lancamentos(
            contas, args.quantidade, data,
            int(round(args.valor_min * 100)),
            int(round(args.valor_max * 100)),
            rng,
        )
        repo.append_lancamentos(regs)
        print(f"OK -> {len(regs)} lancamentos em {repo.lancamentos_path}.")
        return 0

    menu(repo)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
