# Release Strategy

## Visão geral

O processo de release é controlado exclusivamente por **tags Git**. A branch `main` não dispara nenhum workflow automaticamente — commits livres não geram builds.

```text
main  →  commits livres (sem trigger)
          ↓
       tag v1.0.0-rc1   →  Firebase App Distribution  (testers)
       tag v1.0.0-rc2   →  Firebase App Distribution  (fix de feedback)
          ↓
       tag v1.0.0        →  Google Play Internal Track
```

---

## Workflows

| Arquivo | Trigger | Artefato | Destino |
| --- | --- | --- | --- |
| `distribute.yml` | tag `v*-rc*` | APK | Firebase App Distribution |
| `release.yml` | tag `v[0-9]+.[0-9]+.[0-9]+` | AAB | Google Play (Internal) |

---

## Convenção de tags

| Padrão | Exemplo | Significado |
| --- | --- | --- |
| `v<major>.<minor>.<patch>-rc<n>` | `v1.2.0-rc1` | Candidato a release — vai para testers |
| `v<major>.<minor>.<patch>` | `v1.2.0` | Release estável — vai para a loja |

> Tags com outros sufixos (`-beta`, `-hotfix`) **não disparam nenhum workflow**. Fique à vontade para usá-las como marcadores sem efeito colateral.

---

## Passo a passo: distribuir para testers

1. Garanta que a `main` está no estado desejado e o build local passa:

   ```bash
   flutter test
   flutter build apk --dart-define-from-file=dart_defines.json --release
   ```

2. Crie e envie a tag RC:

   ```bash
   git tag v1.0.0-rc1
   git push origin v1.0.0-rc1
   ```

3. O workflow `distribute.yml` é disparado automaticamente. O APK chegará ao grupo `testers` no Firebase App Distribution com a nota de versão `RC v1.0.0-rc1`.

4. Se precisar corrigir algo após feedback, itere na `main` e crie a próxima RC:

   ```bash
   git tag v1.0.0-rc2
   git push origin v1.0.0-rc2
   ```

---

## Passo a passo: publicar na loja

1. Após os testers aprovarem a última RC, crie a tag estável **no mesmo commit** da RC aprovada:

   ```bash
   # Confirme o hash da RC aprovada
   git log --oneline -5

   # Crie a tag no commit correto (HEAD se for o mesmo)
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. O workflow `release.yml` é disparado. O AAB é enviado para a **Internal Testing Track** do Google Play.

3. Promova manualmente para os tracks seguintes (Closed → Open → Production) pelo painel do Google Play Console conforme seu processo de aprovação.

---

## Atualizar o changelog (whatsnew)

O arquivo `.github/whatsnew/whatsnew-pt-BR` é enviado como changelog para o Google Play. Atualize-o antes de criar a tag estável:

```text
# .github/whatsnew/whatsnew-pt-BR
- Novo: cadastro de veículo via QR Code
- Fix: crash ao abrir histórico sem conexão
- Melhoria: tempo de carregamento da tela inicial reduzido
```

> O arquivo deve ter no máximo 500 caracteres (limite do Google Play).

---

## Remover uma tag errada

Se criou a tag no commit errado ou com nome errado:

```bash
# Remover local
git tag -d v1.0.0-rc1

# Remover remoto (atenção: isso cancela o workflow em andamento)
git push origin --delete v1.0.0-rc1
```

---

## TestFlight (iOS — futuro)

Quando a integração com o TestFlight for implementada, o `distribute.yml` receberá um segundo job para build e upload do IPA. O trigger de tags RC permanece o mesmo — sem mudança no fluxo.
