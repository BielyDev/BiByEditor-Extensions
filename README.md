# BiByEditor Extensions

Extensões opcionais do [BiByEditor](https://github.com/BielyDev/BiByEditor). Cada extensão é uma **pasta** com um `extension.json` e um `main.gd`.

| Extensão | O que faz |
|---|---|
| [`download_link`](download_link/) | Baixa o vídeo ou só o áudio de um link (YouTube e outros), podendo baixar só um trecho (início e fim), e põe o arquivo na pasta **Downloads** da biblioteca. |

## Como instalar uma extensão

1. No editor: **Editor > Extensions > Manage extensions…** e clique em **Open extensions folder**.
2. Copie a pasta da extensão (por exemplo `download_link`) para dentro dela.
3. Na mesma tela, ligue a extensão. O item aparece em **Editor > Extensions**.

> **Segurança:** uma extensão roda com o mesmo acesso do editor (lê arquivos, executa programas). Só ligue extensões de quem você confia.

## Como criar uma extensão

Veja `docs/EXTENSOES.md` no repositório do editor: manifesto, API (`add_menu_item`, `notice`, `import_media`, `data_dir`...), regras do script e pré-efeitos.

## Direitos de uso

Algumas extensões baixam mídia da internet. Baixe e use só o que você tem direito de usar: muitos sites proíbem o download nos termos de uso.
