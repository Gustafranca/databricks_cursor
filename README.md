# Bakehouse Medallion — Databricks Asset Bundle

Pipeline de analytics da rede Bakehouse (48 franquias em 9 países) em arquitetura medalhão (**bronze → silver → gold**), orquestrado por Job e consumido por um dashboard AI/BI.

A fonte é o dataset somente leitura `samples.bakehouse`. Nada é escrito nele. Os dados materializados ficam em schemas isolados por projeto:

| Schema | Camada | Propósito |
|--------|--------|-----------|
| `bakehouse_bronze` | Bronze | Ingestão bruta + metadados de carga |
| `bakehouse_silver` | Silver | Limpeza, conformidade e qualidade |
| `bakehouse_gold` | Gold | Marts prontos para BI |
---

## Tecnologias

| Tecnologia | Papel neste projeto |
|------------|---------------------|
| **Databricks Asset Bundles (DABs)** | IaC versionado: schemas, pipeline, job e dashboard em YAML |
| **Unity Catalog** | Governança de catálogo/schema/tabela; destino parametrizado por `var.catalog` |
| **Lakeflow Declarative Pipelines** (serverless) | Um único pipeline SQL com Materialized Views nas 3 camadas |
| **Spark SQL / Photon** | Transformações SQL; Photon habilitado no pipeline |
| **Expectations (data quality)** | Regras de qualidade na silver (`EXPECT` / `DROP ROW` / `FAIL UPDATE`) |
| **AI Functions** (`ai_analyze_sentiment`) | Sentimento dos reviews na silver |
| **Lakeflow Jobs** | Orquestra a execução do pipeline |
| **AI/BI Dashboards (Lakeview)** | KPIs, séries, mapa e sentimento sobre as tabelas gold |
| **SQL Warehouse (serverless)** | Execução das queries do dashboard |
| **Databricks CLI** | Auth, `bundle validate/deploy/run` e exploração local |
| **GitHub Actions** | CI (lint/pytest) + validate/deploy em `prod` com aprovação |

---

## Visão de negócio

O dashboard responde:

- receita, pedidos, ticket médio e franquias ativas
- tendência diária de receita
- mix de produtos e meios de pagamento
- ranking e mapa geográfico de franquias
- desempenho por país
- sentimento dos reviews por franquia
- top customers

---

## Arquitetura medalhão

```text
samples.bakehouse (somente leitura)
        │
        ▼
┌───────────────────┐
│ bakehouse_bronze  │  cópia bruta + _ingested_at / _source_table
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ bakehouse_silver  │  tipos, país de país, joins, expectations, sentimento
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ bakehouse_gold    │  marts agregados para o dashboard
└─────────┬─────────┘
          ▼
   AI/BI Dashboard
```

### Bronze — ingestão

Espelha as tabelas-fonte com metadados de carga (`_ingested_at`, `_source_table`). Sem limpeza de negócio.

| Tabela | Origem |
|--------|--------|
| `transactions` | `samples.bakehouse.sales_transactions` |
| `franchises` | `samples.bakehouse.sales_franchises` |
| `customers` | `samples.bakehouse.sales_customers` |
| `suppliers` | `samples.bakehouse.sales_suppliers` |
| `reviews` | `samples.bakehouse.media_customer_reviews` |

### Silver — conformidade e qualidade

- tipagem e padronização de nomes
- datas derivadas (`transaction_date`, `transaction_month`)
- país unificado (`US` / `USA` → `United States`)
- transações enriquecidas com franquia e cliente
- expectations de qualidade (IDs obrigatórios, preços/quantidades válidos, joins)
- `reviews_sentiment` com `ai_analyze_sentiment`

| Tabela | Intuito |
|--------|---------|
| `customers` | clientes limpos e país padronizado |
| `franchises` | franquias com coordenadas e país padronizado |
| `transactions` | fatos conformados + dimensões |
| `reviews_sentiment` | reviews + sentimento |

### Gold — consumo analítico

Marts agregados para BI, sem reprocessar a lógica de limpeza.

| Tabela | Intuito |
|--------|---------|
| `daily_sales_by_franchise` | KPIs diários por franquia (série temporal) |
| `sales_by_product` | mix de produto e pagamento |
| `franchise_performance` | ranking + lat/lon para o mapa |
| `sales_by_country` | desempenho por país |
| `top_customers` | lifetime value / ranking de clientes |
| `sentiment_by_franchise` | volume de reviews por sentimento |

---

## Estrutura do repositório

```text
databricks_cursor/
├── databricks.yml                 # Bundle: variáveis, targets dev/prod
├── resources/
│   ├── medallion.schemas.yml      # Schemas bakehouse_bronze/silver/gold
│   ├── bakehouse.pipeline.yml     # Pipeline Lakeflow serverless
│   ├── bakehouse.job.yml          # Job que dispara o pipeline
│   └── bakehouse.dashboard.yml    # Dashboard Lakeview (aponta para gold)
├── src/
│   ├── pipelines/bakehouse/
│   │   └── transformations/
│   │       ├── bronze/*.sql       # 1 arquivo = 1 tabela
│   │       ├── silver/*.sql
│   │       └── gold/*.sql
│   └── dashboards/
│       └── bakehouse.lvdash.json  # Definição do AI/BI dashboard
└── .github/workflows/
    └── databricks.yaml            # CI/CD
```

### Papel de cada recurso do bundle

| Recurso | Arquivo | Intuito |
|---------|---------|---------|
| Schemas UC | `medallion.schemas.yml` | Fonte de verdade dos nomes das camadas |
| Pipeline | `bakehouse.pipeline.yml` | Materializa bronze/silver/gold via SQL |
| Job | `bakehouse.job.yml` | Orquestra o refresh do pipeline |
| Dashboard | `bakehouse.dashboard.yml` | Publica o Lakeview sobre `bakehouse_gold` |

### Parametrização (regra crítica)

O **catálogo nunca é hardcoded** nos SQLs nem no dashboard. Quem decide o destino é o target do bundle:

- YAML: `${var.catalog}`, `${resources.schemas.bakehouse_*.name}`
- SQL: `${medallion_catalog}`, `${bronze_schema}`, `${silver_schema}`, `${gold_schema}`
- Dashboard: tabelas gold só pelo nome curto (`FROM franchise_performance`); catalog/schema vêm de `dataset_catalog` / `dataset_schema`

Assim, trocar `dev` ↔ `prod` (ou o valor de `catalog`) não exige editar transformações.

---

## Pré-requisitos

1. [Databricks CLI](https://docs.databricks.com/dev-tools/cli/install) ≥ 0.292 (recomendado ≥ 1.x)
2. Autenticação no workspace:

```bash
databricks auth login --host https://dbc-4a3c13b8-c6c0.cloud.databricks.com --profile <seu-profile>
databricks auth profiles
```

3. Permissões para criar schemas/tabelas no catálogo configurado em `databricks.yml` e para rodar pipelines serverless.

Opcional (agentes de IA neste repo):

```bash
databricks aitools install
```

---

## Como executar

Substitua `<PROFILE>` pelo profile listado em `databricks auth profiles`.

### 1. Validar

```bash
databricks bundle validate --strict -t dev --profile <PROFILE>
```

### 2. Deploy (dev)

```bash
databricks bundle deploy -t dev --profile <PROFILE>
```

Cria/atualiza schemas, pipeline, job e dashboard no workspace.

### 3. Rodar o pipeline (via Job)

```bash
databricks bundle run bakehouse_orchestration -t dev --profile <PROFILE>
```

Alternativa direta no pipeline:

```bash
databricks bundle run bakehouse_medallion_isolated -t dev --profile <PROFILE>
```

### 4. Conferir o que foi implantado

```bash
databricks bundle summary -t dev --profile <PROFILE>
```

### 5. Validar dados (exemplo)

```bash
databricks experimental aitools tools query --profile <PROFILE> \
  "SELECT COUNT(*) AS orders, SUM(total_price) AS revenue
   FROM workspace.bakehouse_silver.transactions"
```

Valores esperados na amostra Bakehouse: **3.333** pedidos, receita **66.471**.

### 6. Dashboard

Após o deploy, o resumo do bundle mostra a URL do **Bakehouse Executive Performance**. As queries do dashboard usam apenas tabelas gold.

---

## Targets

| Target | Uso |
|--------|-----|
| `dev` (default) | desenvolvimento e iteração local |
| `prod` | produção; CI faz deploy após aprovação no environment `prod` |

Ambos usam `catalog: workspace` hoje. Para isolar ambientes por catálogo, altere só `variables.catalog` em `databricks.yml` — não altere os SQLs.

---

## CI/CD (GitHub Actions)

Workflow: `.github/workflows/databricks.yaml`

1. **test** — `ruff` + `pytest` (offline) em PR e push
2. **validate** — `databricks bundle validate -t prod`
3. **deploy** — `databricks bundle deploy -t prod` em push para `main`, com environment `prod` (aprovação humana)

Secrets necessários: `DATABRICKS_CLIENT_ID`, `DATABRICKS_SECRET` (Databricks-managed service principal OAuth secret; mapped to `DATABRICKS_CLIENT_SECRET` with `DATABRICKS_AUTH_TYPE=oauth-m2m`). O host também é fixado no workflow.

---

## Decisão de isolamento de schemas

Unity Catalog não tem nível “projeto” entre catálogo e schema. Como o workspace compartilha um único catálogo gerenciado gravável (`workspace`), as camadas deste projeto usam nomes `bakehouse_*` para não colidir com outros trabalhos no mesmo catálogo.
